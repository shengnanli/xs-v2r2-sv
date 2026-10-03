// TLXbar_5 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= TLXbar_5 =================
  int unsigned x_mode = 0;
  initial begin
    #1;
    force x_u_impl.u_core.g_out_a[0].u_arb.beats_left = x_u_gold.beatsLeft;
    force x_u_impl.u_core.g_out_a[0].u_arb.mask = x_u_gold.readys_mask;
    force x_u_impl.u_core.g_out_a[0].u_arb.state = {x_u_gold.state_2, x_u_gold.state_1, x_u_gold.state_0};
    force x_u_impl.u_core.g_out_a[1].u_arb.beats_left = x_u_gold.beatsLeft_1;
    force x_u_impl.u_core.g_out_a[1].u_arb.mask = x_u_gold.readys_mask_1;
    force x_u_impl.u_core.g_out_a[1].u_arb.state = {x_u_gold.state_1_2, x_u_gold.state_1_1, x_u_gold.state_1_0};
    force x_u_impl.u_core.g_out_a[2].u_arb.beats_left = x_u_gold.beatsLeft_2;
    force x_u_impl.u_core.g_out_a[2].u_arb.mask = x_u_gold.readys_mask_2;
    force x_u_impl.u_core.g_out_a[2].u_arb.state = {x_u_gold.state_2_2, x_u_gold.state_2_1, x_u_gold.state_2_0};
    force x_u_impl.u_core.g_out_a[3].u_arb.beats_left = x_u_gold.beatsLeft_3;
    force x_u_impl.u_core.g_out_a[3].u_arb.mask = x_u_gold.readys_mask_3;
    force x_u_impl.u_core.g_out_a[3].u_arb.state = {x_u_gold.state_3_2, x_u_gold.state_3_1, x_u_gold.state_3_0};
    force x_u_impl.u_core.u_arb_b.beats_left = x_u_gold.beatsLeft_4;
    force x_u_impl.u_core.u_arb_b.mask = x_u_gold.readys_mask_4;
    force x_u_impl.u_core.u_arb_b.state = {x_u_gold.state_4_3, x_u_gold.state_4_2, x_u_gold.state_4_1, x_u_gold.state_4_0};
    force x_u_impl.u_core.g_in_d[0].u_arb.beats_left = x_u_gold.beatsLeft_5;
    force x_u_impl.u_core.g_in_d[0].u_arb.mask = x_u_gold.readys_mask_5;
    force x_u_impl.u_core.g_in_d[0].u_arb.state = {x_u_gold.state_5_3, x_u_gold.state_5_2, x_u_gold.state_5_1, x_u_gold.state_5_0};
    force x_u_impl.u_core.g_in_d[1].u_arb.beats_left = x_u_gold.beatsLeft_6;
    force x_u_impl.u_core.g_in_d[1].u_arb.mask = x_u_gold.readys_mask_6;
    force x_u_impl.u_core.g_in_d[1].u_arb.state = {x_u_gold.state_6_3, x_u_gold.state_6_2, x_u_gold.state_6_1, x_u_gold.state_6_0};
    force x_u_impl.u_core.g_in_d[2].u_arb.beats_left = x_u_gold.beatsLeft_7;
    force x_u_impl.u_core.g_in_d[2].u_arb.mask = x_u_gold.readys_mask_7;
    force x_u_impl.u_core.g_in_d[2].u_arb.state = {x_u_gold.state_7_3, x_u_gold.state_7_2, x_u_gold.state_7_1, x_u_gold.state_7_0};
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
    release x_u_impl.u_core.g_out_a[3].u_arb.beats_left;
    release x_u_impl.u_core.g_out_a[3].u_arb.mask;
    release x_u_impl.u_core.g_out_a[3].u_arb.state;
    release x_u_impl.u_core.u_arb_b.beats_left;
    release x_u_impl.u_core.u_arb_b.mask;
    release x_u_impl.u_core.u_arb_b.state;
    release x_u_impl.u_core.g_in_d[0].u_arb.beats_left;
    release x_u_impl.u_core.g_in_d[0].u_arb.mask;
    release x_u_impl.u_core.g_in_d[0].u_arb.state;
    release x_u_impl.u_core.g_in_d[1].u_arb.beats_left;
    release x_u_impl.u_core.g_in_d[1].u_arb.mask;
    release x_u_impl.u_core.g_in_d[1].u_arb.state;
    release x_u_impl.u_core.g_in_d[2].u_arb.beats_left;
    release x_u_impl.u_core.g_in_d[2].u_arb.mask;
    release x_u_impl.u_core.g_in_d[2].u_arb.state;
  end
  logic x_reset;
  wire  x_g_auto_in_2_a_ready, x_i_auto_in_2_a_ready;
  logic x_s0_auto_in_2_a_ready = '0, x_s1_auto_in_2_a_ready = '0;
  logic x_auto_in_2_a_valid;
  logic [3:0] x_auto_in_2_a_bits_opcode;
  logic [2:0] x_auto_in_2_a_bits_param;
  logic [2:0] x_auto_in_2_a_bits_size;
  logic [3:0] x_auto_in_2_a_bits_source;
  logic [47:0] x_auto_in_2_a_bits_address;
  logic [4:0] x_auto_in_2_a_bits_user_reqSource;
  logic [31:0] x_auto_in_2_a_bits_mask;
  logic [255:0] x_auto_in_2_a_bits_data;
  logic x_auto_in_2_a_bits_corrupt;
  logic x_auto_in_2_d_ready;
  wire  x_g_auto_in_2_d_valid, x_i_auto_in_2_d_valid;
  logic x_s0_auto_in_2_d_valid = '0, x_s1_auto_in_2_d_valid = '0;
  wire  [3:0] x_g_auto_in_2_d_bits_opcode, x_i_auto_in_2_d_bits_opcode;
  logic [3:0] x_s0_auto_in_2_d_bits_opcode = '0, x_s1_auto_in_2_d_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_2_d_bits_param, x_i_auto_in_2_d_bits_param;
  logic [1:0] x_s0_auto_in_2_d_bits_param = '0, x_s1_auto_in_2_d_bits_param = '0;
  wire  [2:0] x_g_auto_in_2_d_bits_size, x_i_auto_in_2_d_bits_size;
  logic [2:0] x_s0_auto_in_2_d_bits_size = '0, x_s1_auto_in_2_d_bits_size = '0;
  wire  [3:0] x_g_auto_in_2_d_bits_source, x_i_auto_in_2_d_bits_source;
  logic [3:0] x_s0_auto_in_2_d_bits_source = '0, x_s1_auto_in_2_d_bits_source = '0;
  wire  [9:0] x_g_auto_in_2_d_bits_sink, x_i_auto_in_2_d_bits_sink;
  logic [9:0] x_s0_auto_in_2_d_bits_sink = '0, x_s1_auto_in_2_d_bits_sink = '0;
  wire  x_g_auto_in_2_d_bits_denied, x_i_auto_in_2_d_bits_denied;
  logic x_s0_auto_in_2_d_bits_denied = '0, x_s1_auto_in_2_d_bits_denied = '0;
  wire  [255:0] x_g_auto_in_2_d_bits_data, x_i_auto_in_2_d_bits_data;
  logic [255:0] x_s0_auto_in_2_d_bits_data = '0, x_s1_auto_in_2_d_bits_data = '0;
  wire  x_g_auto_in_2_d_bits_corrupt, x_i_auto_in_2_d_bits_corrupt;
  logic x_s0_auto_in_2_d_bits_corrupt = '0, x_s1_auto_in_2_d_bits_corrupt = '0;
  wire  x_g_auto_in_1_a_ready, x_i_auto_in_1_a_ready;
  logic x_s0_auto_in_1_a_ready = '0, x_s1_auto_in_1_a_ready = '0;
  logic x_auto_in_1_a_valid;
  logic [3:0] x_auto_in_1_a_bits_opcode;
  logic [2:0] x_auto_in_1_a_bits_param;
  logic [2:0] x_auto_in_1_a_bits_size;
  logic [3:0] x_auto_in_1_a_bits_source;
  logic [47:0] x_auto_in_1_a_bits_address;
  logic [1:0] x_auto_in_1_a_bits_user_alias;
  logic [4:0] x_auto_in_1_a_bits_user_reqSource;
  logic x_auto_in_1_a_bits_user_needHint;
  logic [31:0] x_auto_in_1_a_bits_mask;
  logic [255:0] x_auto_in_1_a_bits_data;
  logic x_auto_in_1_a_bits_corrupt;
  logic x_auto_in_1_d_ready;
  wire  x_g_auto_in_1_d_valid, x_i_auto_in_1_d_valid;
  logic x_s0_auto_in_1_d_valid = '0, x_s1_auto_in_1_d_valid = '0;
  wire  [3:0] x_g_auto_in_1_d_bits_opcode, x_i_auto_in_1_d_bits_opcode;
  logic [3:0] x_s0_auto_in_1_d_bits_opcode = '0, x_s1_auto_in_1_d_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_1_d_bits_param, x_i_auto_in_1_d_bits_param;
  logic [1:0] x_s0_auto_in_1_d_bits_param = '0, x_s1_auto_in_1_d_bits_param = '0;
  wire  [2:0] x_g_auto_in_1_d_bits_size, x_i_auto_in_1_d_bits_size;
  logic [2:0] x_s0_auto_in_1_d_bits_size = '0, x_s1_auto_in_1_d_bits_size = '0;
  wire  [3:0] x_g_auto_in_1_d_bits_source, x_i_auto_in_1_d_bits_source;
  logic [3:0] x_s0_auto_in_1_d_bits_source = '0, x_s1_auto_in_1_d_bits_source = '0;
  wire  [9:0] x_g_auto_in_1_d_bits_sink, x_i_auto_in_1_d_bits_sink;
  logic [9:0] x_s0_auto_in_1_d_bits_sink = '0, x_s1_auto_in_1_d_bits_sink = '0;
  wire  x_g_auto_in_1_d_bits_denied, x_i_auto_in_1_d_bits_denied;
  logic x_s0_auto_in_1_d_bits_denied = '0, x_s1_auto_in_1_d_bits_denied = '0;
  wire  [255:0] x_g_auto_in_1_d_bits_data, x_i_auto_in_1_d_bits_data;
  logic [255:0] x_s0_auto_in_1_d_bits_data = '0, x_s1_auto_in_1_d_bits_data = '0;
  wire  x_g_auto_in_1_d_bits_corrupt, x_i_auto_in_1_d_bits_corrupt;
  logic x_s0_auto_in_1_d_bits_corrupt = '0, x_s1_auto_in_1_d_bits_corrupt = '0;
  wire  x_g_auto_in_0_a_ready, x_i_auto_in_0_a_ready;
  logic x_s0_auto_in_0_a_ready = '0, x_s1_auto_in_0_a_ready = '0;
  logic x_auto_in_0_a_valid;
  logic [3:0] x_auto_in_0_a_bits_opcode;
  logic [2:0] x_auto_in_0_a_bits_param;
  logic [2:0] x_auto_in_0_a_bits_size;
  logic [5:0] x_auto_in_0_a_bits_source;
  logic [47:0] x_auto_in_0_a_bits_address;
  logic [1:0] x_auto_in_0_a_bits_user_alias;
  logic [43:0] x_auto_in_0_a_bits_user_vaddr;
  logic [4:0] x_auto_in_0_a_bits_user_reqSource;
  logic x_auto_in_0_a_bits_user_needHint;
  logic x_auto_in_0_a_bits_echo_isKeyword;
  logic [31:0] x_auto_in_0_a_bits_mask;
  logic [255:0] x_auto_in_0_a_bits_data;
  logic x_auto_in_0_a_bits_corrupt;
  logic x_auto_in_0_b_ready;
  wire  x_g_auto_in_0_b_valid, x_i_auto_in_0_b_valid;
  logic x_s0_auto_in_0_b_valid = '0, x_s1_auto_in_0_b_valid = '0;
  wire  [2:0] x_g_auto_in_0_b_bits_opcode, x_i_auto_in_0_b_bits_opcode;
  logic [2:0] x_s0_auto_in_0_b_bits_opcode = '0, x_s1_auto_in_0_b_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_0_b_bits_param, x_i_auto_in_0_b_bits_param;
  logic [1:0] x_s0_auto_in_0_b_bits_param = '0, x_s1_auto_in_0_b_bits_param = '0;
  wire  [2:0] x_g_auto_in_0_b_bits_size, x_i_auto_in_0_b_bits_size;
  logic [2:0] x_s0_auto_in_0_b_bits_size = '0, x_s1_auto_in_0_b_bits_size = '0;
  wire  [5:0] x_g_auto_in_0_b_bits_source, x_i_auto_in_0_b_bits_source;
  logic [5:0] x_s0_auto_in_0_b_bits_source = '0, x_s1_auto_in_0_b_bits_source = '0;
  wire  [47:0] x_g_auto_in_0_b_bits_address, x_i_auto_in_0_b_bits_address;
  logic [47:0] x_s0_auto_in_0_b_bits_address = '0, x_s1_auto_in_0_b_bits_address = '0;
  wire  [31:0] x_g_auto_in_0_b_bits_mask, x_i_auto_in_0_b_bits_mask;
  logic [31:0] x_s0_auto_in_0_b_bits_mask = '0, x_s1_auto_in_0_b_bits_mask = '0;
  wire  [255:0] x_g_auto_in_0_b_bits_data, x_i_auto_in_0_b_bits_data;
  logic [255:0] x_s0_auto_in_0_b_bits_data = '0, x_s1_auto_in_0_b_bits_data = '0;
  wire  x_g_auto_in_0_b_bits_corrupt, x_i_auto_in_0_b_bits_corrupt;
  logic x_s0_auto_in_0_b_bits_corrupt = '0, x_s1_auto_in_0_b_bits_corrupt = '0;
  wire  x_g_auto_in_0_c_ready, x_i_auto_in_0_c_ready;
  logic x_s0_auto_in_0_c_ready = '0, x_s1_auto_in_0_c_ready = '0;
  logic x_auto_in_0_c_valid;
  logic [2:0] x_auto_in_0_c_bits_opcode;
  logic [2:0] x_auto_in_0_c_bits_param;
  logic [2:0] x_auto_in_0_c_bits_size;
  logic [5:0] x_auto_in_0_c_bits_source;
  logic [47:0] x_auto_in_0_c_bits_address;
  logic [1:0] x_auto_in_0_c_bits_user_alias;
  logic [43:0] x_auto_in_0_c_bits_user_vaddr;
  logic [4:0] x_auto_in_0_c_bits_user_reqSource;
  logic x_auto_in_0_c_bits_user_needHint;
  logic x_auto_in_0_c_bits_echo_isKeyword;
  logic [255:0] x_auto_in_0_c_bits_data;
  logic x_auto_in_0_c_bits_corrupt;
  logic x_auto_in_0_d_ready;
  wire  x_g_auto_in_0_d_valid, x_i_auto_in_0_d_valid;
  logic x_s0_auto_in_0_d_valid = '0, x_s1_auto_in_0_d_valid = '0;
  wire  [3:0] x_g_auto_in_0_d_bits_opcode, x_i_auto_in_0_d_bits_opcode;
  logic [3:0] x_s0_auto_in_0_d_bits_opcode = '0, x_s1_auto_in_0_d_bits_opcode = '0;
  wire  [1:0] x_g_auto_in_0_d_bits_param, x_i_auto_in_0_d_bits_param;
  logic [1:0] x_s0_auto_in_0_d_bits_param = '0, x_s1_auto_in_0_d_bits_param = '0;
  wire  [2:0] x_g_auto_in_0_d_bits_size, x_i_auto_in_0_d_bits_size;
  logic [2:0] x_s0_auto_in_0_d_bits_size = '0, x_s1_auto_in_0_d_bits_size = '0;
  wire  [5:0] x_g_auto_in_0_d_bits_source, x_i_auto_in_0_d_bits_source;
  logic [5:0] x_s0_auto_in_0_d_bits_source = '0, x_s1_auto_in_0_d_bits_source = '0;
  wire  [9:0] x_g_auto_in_0_d_bits_sink, x_i_auto_in_0_d_bits_sink;
  logic [9:0] x_s0_auto_in_0_d_bits_sink = '0, x_s1_auto_in_0_d_bits_sink = '0;
  wire  x_g_auto_in_0_d_bits_denied, x_i_auto_in_0_d_bits_denied;
  logic x_s0_auto_in_0_d_bits_denied = '0, x_s1_auto_in_0_d_bits_denied = '0;
  wire  x_g_auto_in_0_d_bits_echo_isKeyword, x_i_auto_in_0_d_bits_echo_isKeyword;
  logic x_s0_auto_in_0_d_bits_echo_isKeyword = '0, x_s1_auto_in_0_d_bits_echo_isKeyword = '0;
  wire  [255:0] x_g_auto_in_0_d_bits_data, x_i_auto_in_0_d_bits_data;
  logic [255:0] x_s0_auto_in_0_d_bits_data = '0, x_s1_auto_in_0_d_bits_data = '0;
  wire  x_g_auto_in_0_d_bits_corrupt, x_i_auto_in_0_d_bits_corrupt;
  logic x_s0_auto_in_0_d_bits_corrupt = '0, x_s1_auto_in_0_d_bits_corrupt = '0;
  wire  x_g_auto_in_0_e_ready, x_i_auto_in_0_e_ready;
  logic x_s0_auto_in_0_e_ready = '0, x_s1_auto_in_0_e_ready = '0;
  logic x_auto_in_0_e_valid;
  logic [9:0] x_auto_in_0_e_bits_sink;
  logic x_auto_out_3_a_ready;
  wire  x_g_auto_out_3_a_valid, x_i_auto_out_3_a_valid;
  logic x_s0_auto_out_3_a_valid = '0, x_s1_auto_out_3_a_valid = '0;
  wire  [3:0] x_g_auto_out_3_a_bits_opcode, x_i_auto_out_3_a_bits_opcode;
  logic [3:0] x_s0_auto_out_3_a_bits_opcode = '0, x_s1_auto_out_3_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_3_a_bits_param, x_i_auto_out_3_a_bits_param;
  logic [2:0] x_s0_auto_out_3_a_bits_param = '0, x_s1_auto_out_3_a_bits_param = '0;
  wire  [2:0] x_g_auto_out_3_a_bits_size, x_i_auto_out_3_a_bits_size;
  logic [2:0] x_s0_auto_out_3_a_bits_size = '0, x_s1_auto_out_3_a_bits_size = '0;
  wire  [6:0] x_g_auto_out_3_a_bits_source, x_i_auto_out_3_a_bits_source;
  logic [6:0] x_s0_auto_out_3_a_bits_source = '0, x_s1_auto_out_3_a_bits_source = '0;
  wire  [47:0] x_g_auto_out_3_a_bits_address, x_i_auto_out_3_a_bits_address;
  logic [47:0] x_s0_auto_out_3_a_bits_address = '0, x_s1_auto_out_3_a_bits_address = '0;
  wire  [4:0] x_g_auto_out_3_a_bits_user_reqSource, x_i_auto_out_3_a_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_3_a_bits_user_reqSource = '0, x_s1_auto_out_3_a_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_3_a_bits_user_alias, x_i_auto_out_3_a_bits_user_alias;
  logic [1:0] x_s0_auto_out_3_a_bits_user_alias = '0, x_s1_auto_out_3_a_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_3_a_bits_user_vaddr, x_i_auto_out_3_a_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_3_a_bits_user_vaddr = '0, x_s1_auto_out_3_a_bits_user_vaddr = '0;
  wire  x_g_auto_out_3_a_bits_user_needHint, x_i_auto_out_3_a_bits_user_needHint;
  logic x_s0_auto_out_3_a_bits_user_needHint = '0, x_s1_auto_out_3_a_bits_user_needHint = '0;
  wire  x_g_auto_out_3_a_bits_echo_isKeyword, x_i_auto_out_3_a_bits_echo_isKeyword;
  logic x_s0_auto_out_3_a_bits_echo_isKeyword = '0, x_s1_auto_out_3_a_bits_echo_isKeyword = '0;
  wire  [31:0] x_g_auto_out_3_a_bits_mask, x_i_auto_out_3_a_bits_mask;
  logic [31:0] x_s0_auto_out_3_a_bits_mask = '0, x_s1_auto_out_3_a_bits_mask = '0;
  wire  [255:0] x_g_auto_out_3_a_bits_data, x_i_auto_out_3_a_bits_data;
  logic [255:0] x_s0_auto_out_3_a_bits_data = '0, x_s1_auto_out_3_a_bits_data = '0;
  wire  x_g_auto_out_3_a_bits_corrupt, x_i_auto_out_3_a_bits_corrupt;
  logic x_s0_auto_out_3_a_bits_corrupt = '0, x_s1_auto_out_3_a_bits_corrupt = '0;
  wire  x_g_auto_out_3_b_ready, x_i_auto_out_3_b_ready;
  logic x_s0_auto_out_3_b_ready = '0, x_s1_auto_out_3_b_ready = '0;
  logic x_auto_out_3_b_valid;
  logic [2:0] x_auto_out_3_b_bits_opcode;
  logic [1:0] x_auto_out_3_b_bits_param;
  logic [2:0] x_auto_out_3_b_bits_size;
  logic [6:0] x_auto_out_3_b_bits_source;
  logic [47:0] x_auto_out_3_b_bits_address;
  logic [31:0] x_auto_out_3_b_bits_mask;
  logic [255:0] x_auto_out_3_b_bits_data;
  logic x_auto_out_3_b_bits_corrupt;
  logic x_auto_out_3_c_ready;
  wire  x_g_auto_out_3_c_valid, x_i_auto_out_3_c_valid;
  logic x_s0_auto_out_3_c_valid = '0, x_s1_auto_out_3_c_valid = '0;
  wire  [2:0] x_g_auto_out_3_c_bits_opcode, x_i_auto_out_3_c_bits_opcode;
  logic [2:0] x_s0_auto_out_3_c_bits_opcode = '0, x_s1_auto_out_3_c_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_3_c_bits_param, x_i_auto_out_3_c_bits_param;
  logic [2:0] x_s0_auto_out_3_c_bits_param = '0, x_s1_auto_out_3_c_bits_param = '0;
  wire  [2:0] x_g_auto_out_3_c_bits_size, x_i_auto_out_3_c_bits_size;
  logic [2:0] x_s0_auto_out_3_c_bits_size = '0, x_s1_auto_out_3_c_bits_size = '0;
  wire  [6:0] x_g_auto_out_3_c_bits_source, x_i_auto_out_3_c_bits_source;
  logic [6:0] x_s0_auto_out_3_c_bits_source = '0, x_s1_auto_out_3_c_bits_source = '0;
  wire  [47:0] x_g_auto_out_3_c_bits_address, x_i_auto_out_3_c_bits_address;
  logic [47:0] x_s0_auto_out_3_c_bits_address = '0, x_s1_auto_out_3_c_bits_address = '0;
  wire  [4:0] x_g_auto_out_3_c_bits_user_reqSource, x_i_auto_out_3_c_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_3_c_bits_user_reqSource = '0, x_s1_auto_out_3_c_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_3_c_bits_user_alias, x_i_auto_out_3_c_bits_user_alias;
  logic [1:0] x_s0_auto_out_3_c_bits_user_alias = '0, x_s1_auto_out_3_c_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_3_c_bits_user_vaddr, x_i_auto_out_3_c_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_3_c_bits_user_vaddr = '0, x_s1_auto_out_3_c_bits_user_vaddr = '0;
  wire  x_g_auto_out_3_c_bits_user_needHint, x_i_auto_out_3_c_bits_user_needHint;
  logic x_s0_auto_out_3_c_bits_user_needHint = '0, x_s1_auto_out_3_c_bits_user_needHint = '0;
  wire  x_g_auto_out_3_c_bits_echo_isKeyword, x_i_auto_out_3_c_bits_echo_isKeyword;
  logic x_s0_auto_out_3_c_bits_echo_isKeyword = '0, x_s1_auto_out_3_c_bits_echo_isKeyword = '0;
  wire  [255:0] x_g_auto_out_3_c_bits_data, x_i_auto_out_3_c_bits_data;
  logic [255:0] x_s0_auto_out_3_c_bits_data = '0, x_s1_auto_out_3_c_bits_data = '0;
  wire  x_g_auto_out_3_c_bits_corrupt, x_i_auto_out_3_c_bits_corrupt;
  logic x_s0_auto_out_3_c_bits_corrupt = '0, x_s1_auto_out_3_c_bits_corrupt = '0;
  wire  x_g_auto_out_3_d_ready, x_i_auto_out_3_d_ready;
  logic x_s0_auto_out_3_d_ready = '0, x_s1_auto_out_3_d_ready = '0;
  logic x_auto_out_3_d_valid;
  logic [3:0] x_auto_out_3_d_bits_opcode;
  logic [1:0] x_auto_out_3_d_bits_param;
  logic [2:0] x_auto_out_3_d_bits_size;
  logic [6:0] x_auto_out_3_d_bits_source;
  logic [7:0] x_auto_out_3_d_bits_sink;
  logic x_auto_out_3_d_bits_denied;
  logic x_auto_out_3_d_bits_echo_isKeyword;
  logic [255:0] x_auto_out_3_d_bits_data;
  logic x_auto_out_3_d_bits_corrupt;
  logic x_auto_out_3_e_ready;
  wire  x_g_auto_out_3_e_valid, x_i_auto_out_3_e_valid;
  logic x_s0_auto_out_3_e_valid = '0, x_s1_auto_out_3_e_valid = '0;
  wire  [7:0] x_g_auto_out_3_e_bits_sink, x_i_auto_out_3_e_bits_sink;
  logic [7:0] x_s0_auto_out_3_e_bits_sink = '0, x_s1_auto_out_3_e_bits_sink = '0;
  logic x_auto_out_2_a_ready;
  wire  x_g_auto_out_2_a_valid, x_i_auto_out_2_a_valid;
  logic x_s0_auto_out_2_a_valid = '0, x_s1_auto_out_2_a_valid = '0;
  wire  [3:0] x_g_auto_out_2_a_bits_opcode, x_i_auto_out_2_a_bits_opcode;
  logic [3:0] x_s0_auto_out_2_a_bits_opcode = '0, x_s1_auto_out_2_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_2_a_bits_param, x_i_auto_out_2_a_bits_param;
  logic [2:0] x_s0_auto_out_2_a_bits_param = '0, x_s1_auto_out_2_a_bits_param = '0;
  wire  [2:0] x_g_auto_out_2_a_bits_size, x_i_auto_out_2_a_bits_size;
  logic [2:0] x_s0_auto_out_2_a_bits_size = '0, x_s1_auto_out_2_a_bits_size = '0;
  wire  [6:0] x_g_auto_out_2_a_bits_source, x_i_auto_out_2_a_bits_source;
  logic [6:0] x_s0_auto_out_2_a_bits_source = '0, x_s1_auto_out_2_a_bits_source = '0;
  wire  [47:0] x_g_auto_out_2_a_bits_address, x_i_auto_out_2_a_bits_address;
  logic [47:0] x_s0_auto_out_2_a_bits_address = '0, x_s1_auto_out_2_a_bits_address = '0;
  wire  [4:0] x_g_auto_out_2_a_bits_user_reqSource, x_i_auto_out_2_a_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_2_a_bits_user_reqSource = '0, x_s1_auto_out_2_a_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_2_a_bits_user_alias, x_i_auto_out_2_a_bits_user_alias;
  logic [1:0] x_s0_auto_out_2_a_bits_user_alias = '0, x_s1_auto_out_2_a_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_2_a_bits_user_vaddr, x_i_auto_out_2_a_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_2_a_bits_user_vaddr = '0, x_s1_auto_out_2_a_bits_user_vaddr = '0;
  wire  x_g_auto_out_2_a_bits_user_needHint, x_i_auto_out_2_a_bits_user_needHint;
  logic x_s0_auto_out_2_a_bits_user_needHint = '0, x_s1_auto_out_2_a_bits_user_needHint = '0;
  wire  x_g_auto_out_2_a_bits_echo_isKeyword, x_i_auto_out_2_a_bits_echo_isKeyword;
  logic x_s0_auto_out_2_a_bits_echo_isKeyword = '0, x_s1_auto_out_2_a_bits_echo_isKeyword = '0;
  wire  [31:0] x_g_auto_out_2_a_bits_mask, x_i_auto_out_2_a_bits_mask;
  logic [31:0] x_s0_auto_out_2_a_bits_mask = '0, x_s1_auto_out_2_a_bits_mask = '0;
  wire  [255:0] x_g_auto_out_2_a_bits_data, x_i_auto_out_2_a_bits_data;
  logic [255:0] x_s0_auto_out_2_a_bits_data = '0, x_s1_auto_out_2_a_bits_data = '0;
  wire  x_g_auto_out_2_a_bits_corrupt, x_i_auto_out_2_a_bits_corrupt;
  logic x_s0_auto_out_2_a_bits_corrupt = '0, x_s1_auto_out_2_a_bits_corrupt = '0;
  wire  x_g_auto_out_2_b_ready, x_i_auto_out_2_b_ready;
  logic x_s0_auto_out_2_b_ready = '0, x_s1_auto_out_2_b_ready = '0;
  logic x_auto_out_2_b_valid;
  logic [2:0] x_auto_out_2_b_bits_opcode;
  logic [1:0] x_auto_out_2_b_bits_param;
  logic [2:0] x_auto_out_2_b_bits_size;
  logic [6:0] x_auto_out_2_b_bits_source;
  logic [47:0] x_auto_out_2_b_bits_address;
  logic [31:0] x_auto_out_2_b_bits_mask;
  logic [255:0] x_auto_out_2_b_bits_data;
  logic x_auto_out_2_b_bits_corrupt;
  logic x_auto_out_2_c_ready;
  wire  x_g_auto_out_2_c_valid, x_i_auto_out_2_c_valid;
  logic x_s0_auto_out_2_c_valid = '0, x_s1_auto_out_2_c_valid = '0;
  wire  [2:0] x_g_auto_out_2_c_bits_opcode, x_i_auto_out_2_c_bits_opcode;
  logic [2:0] x_s0_auto_out_2_c_bits_opcode = '0, x_s1_auto_out_2_c_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_2_c_bits_param, x_i_auto_out_2_c_bits_param;
  logic [2:0] x_s0_auto_out_2_c_bits_param = '0, x_s1_auto_out_2_c_bits_param = '0;
  wire  [2:0] x_g_auto_out_2_c_bits_size, x_i_auto_out_2_c_bits_size;
  logic [2:0] x_s0_auto_out_2_c_bits_size = '0, x_s1_auto_out_2_c_bits_size = '0;
  wire  [6:0] x_g_auto_out_2_c_bits_source, x_i_auto_out_2_c_bits_source;
  logic [6:0] x_s0_auto_out_2_c_bits_source = '0, x_s1_auto_out_2_c_bits_source = '0;
  wire  [47:0] x_g_auto_out_2_c_bits_address, x_i_auto_out_2_c_bits_address;
  logic [47:0] x_s0_auto_out_2_c_bits_address = '0, x_s1_auto_out_2_c_bits_address = '0;
  wire  [4:0] x_g_auto_out_2_c_bits_user_reqSource, x_i_auto_out_2_c_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_2_c_bits_user_reqSource = '0, x_s1_auto_out_2_c_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_2_c_bits_user_alias, x_i_auto_out_2_c_bits_user_alias;
  logic [1:0] x_s0_auto_out_2_c_bits_user_alias = '0, x_s1_auto_out_2_c_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_2_c_bits_user_vaddr, x_i_auto_out_2_c_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_2_c_bits_user_vaddr = '0, x_s1_auto_out_2_c_bits_user_vaddr = '0;
  wire  x_g_auto_out_2_c_bits_user_needHint, x_i_auto_out_2_c_bits_user_needHint;
  logic x_s0_auto_out_2_c_bits_user_needHint = '0, x_s1_auto_out_2_c_bits_user_needHint = '0;
  wire  x_g_auto_out_2_c_bits_echo_isKeyword, x_i_auto_out_2_c_bits_echo_isKeyword;
  logic x_s0_auto_out_2_c_bits_echo_isKeyword = '0, x_s1_auto_out_2_c_bits_echo_isKeyword = '0;
  wire  [255:0] x_g_auto_out_2_c_bits_data, x_i_auto_out_2_c_bits_data;
  logic [255:0] x_s0_auto_out_2_c_bits_data = '0, x_s1_auto_out_2_c_bits_data = '0;
  wire  x_g_auto_out_2_c_bits_corrupt, x_i_auto_out_2_c_bits_corrupt;
  logic x_s0_auto_out_2_c_bits_corrupt = '0, x_s1_auto_out_2_c_bits_corrupt = '0;
  wire  x_g_auto_out_2_d_ready, x_i_auto_out_2_d_ready;
  logic x_s0_auto_out_2_d_ready = '0, x_s1_auto_out_2_d_ready = '0;
  logic x_auto_out_2_d_valid;
  logic [3:0] x_auto_out_2_d_bits_opcode;
  logic [1:0] x_auto_out_2_d_bits_param;
  logic [2:0] x_auto_out_2_d_bits_size;
  logic [6:0] x_auto_out_2_d_bits_source;
  logic [7:0] x_auto_out_2_d_bits_sink;
  logic x_auto_out_2_d_bits_denied;
  logic x_auto_out_2_d_bits_echo_isKeyword;
  logic [255:0] x_auto_out_2_d_bits_data;
  logic x_auto_out_2_d_bits_corrupt;
  logic x_auto_out_2_e_ready;
  wire  x_g_auto_out_2_e_valid, x_i_auto_out_2_e_valid;
  logic x_s0_auto_out_2_e_valid = '0, x_s1_auto_out_2_e_valid = '0;
  wire  [7:0] x_g_auto_out_2_e_bits_sink, x_i_auto_out_2_e_bits_sink;
  logic [7:0] x_s0_auto_out_2_e_bits_sink = '0, x_s1_auto_out_2_e_bits_sink = '0;
  logic x_auto_out_1_a_ready;
  wire  x_g_auto_out_1_a_valid, x_i_auto_out_1_a_valid;
  logic x_s0_auto_out_1_a_valid = '0, x_s1_auto_out_1_a_valid = '0;
  wire  [3:0] x_g_auto_out_1_a_bits_opcode, x_i_auto_out_1_a_bits_opcode;
  logic [3:0] x_s0_auto_out_1_a_bits_opcode = '0, x_s1_auto_out_1_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_1_a_bits_param, x_i_auto_out_1_a_bits_param;
  logic [2:0] x_s0_auto_out_1_a_bits_param = '0, x_s1_auto_out_1_a_bits_param = '0;
  wire  [2:0] x_g_auto_out_1_a_bits_size, x_i_auto_out_1_a_bits_size;
  logic [2:0] x_s0_auto_out_1_a_bits_size = '0, x_s1_auto_out_1_a_bits_size = '0;
  wire  [6:0] x_g_auto_out_1_a_bits_source, x_i_auto_out_1_a_bits_source;
  logic [6:0] x_s0_auto_out_1_a_bits_source = '0, x_s1_auto_out_1_a_bits_source = '0;
  wire  [47:0] x_g_auto_out_1_a_bits_address, x_i_auto_out_1_a_bits_address;
  logic [47:0] x_s0_auto_out_1_a_bits_address = '0, x_s1_auto_out_1_a_bits_address = '0;
  wire  [4:0] x_g_auto_out_1_a_bits_user_reqSource, x_i_auto_out_1_a_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_1_a_bits_user_reqSource = '0, x_s1_auto_out_1_a_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_1_a_bits_user_alias, x_i_auto_out_1_a_bits_user_alias;
  logic [1:0] x_s0_auto_out_1_a_bits_user_alias = '0, x_s1_auto_out_1_a_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_1_a_bits_user_vaddr, x_i_auto_out_1_a_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_1_a_bits_user_vaddr = '0, x_s1_auto_out_1_a_bits_user_vaddr = '0;
  wire  x_g_auto_out_1_a_bits_user_needHint, x_i_auto_out_1_a_bits_user_needHint;
  logic x_s0_auto_out_1_a_bits_user_needHint = '0, x_s1_auto_out_1_a_bits_user_needHint = '0;
  wire  x_g_auto_out_1_a_bits_echo_isKeyword, x_i_auto_out_1_a_bits_echo_isKeyword;
  logic x_s0_auto_out_1_a_bits_echo_isKeyword = '0, x_s1_auto_out_1_a_bits_echo_isKeyword = '0;
  wire  [31:0] x_g_auto_out_1_a_bits_mask, x_i_auto_out_1_a_bits_mask;
  logic [31:0] x_s0_auto_out_1_a_bits_mask = '0, x_s1_auto_out_1_a_bits_mask = '0;
  wire  [255:0] x_g_auto_out_1_a_bits_data, x_i_auto_out_1_a_bits_data;
  logic [255:0] x_s0_auto_out_1_a_bits_data = '0, x_s1_auto_out_1_a_bits_data = '0;
  wire  x_g_auto_out_1_a_bits_corrupt, x_i_auto_out_1_a_bits_corrupt;
  logic x_s0_auto_out_1_a_bits_corrupt = '0, x_s1_auto_out_1_a_bits_corrupt = '0;
  wire  x_g_auto_out_1_b_ready, x_i_auto_out_1_b_ready;
  logic x_s0_auto_out_1_b_ready = '0, x_s1_auto_out_1_b_ready = '0;
  logic x_auto_out_1_b_valid;
  logic [2:0] x_auto_out_1_b_bits_opcode;
  logic [1:0] x_auto_out_1_b_bits_param;
  logic [2:0] x_auto_out_1_b_bits_size;
  logic [6:0] x_auto_out_1_b_bits_source;
  logic [47:0] x_auto_out_1_b_bits_address;
  logic [31:0] x_auto_out_1_b_bits_mask;
  logic [255:0] x_auto_out_1_b_bits_data;
  logic x_auto_out_1_b_bits_corrupt;
  logic x_auto_out_1_c_ready;
  wire  x_g_auto_out_1_c_valid, x_i_auto_out_1_c_valid;
  logic x_s0_auto_out_1_c_valid = '0, x_s1_auto_out_1_c_valid = '0;
  wire  [2:0] x_g_auto_out_1_c_bits_opcode, x_i_auto_out_1_c_bits_opcode;
  logic [2:0] x_s0_auto_out_1_c_bits_opcode = '0, x_s1_auto_out_1_c_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_1_c_bits_param, x_i_auto_out_1_c_bits_param;
  logic [2:0] x_s0_auto_out_1_c_bits_param = '0, x_s1_auto_out_1_c_bits_param = '0;
  wire  [2:0] x_g_auto_out_1_c_bits_size, x_i_auto_out_1_c_bits_size;
  logic [2:0] x_s0_auto_out_1_c_bits_size = '0, x_s1_auto_out_1_c_bits_size = '0;
  wire  [6:0] x_g_auto_out_1_c_bits_source, x_i_auto_out_1_c_bits_source;
  logic [6:0] x_s0_auto_out_1_c_bits_source = '0, x_s1_auto_out_1_c_bits_source = '0;
  wire  [47:0] x_g_auto_out_1_c_bits_address, x_i_auto_out_1_c_bits_address;
  logic [47:0] x_s0_auto_out_1_c_bits_address = '0, x_s1_auto_out_1_c_bits_address = '0;
  wire  [4:0] x_g_auto_out_1_c_bits_user_reqSource, x_i_auto_out_1_c_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_1_c_bits_user_reqSource = '0, x_s1_auto_out_1_c_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_1_c_bits_user_alias, x_i_auto_out_1_c_bits_user_alias;
  logic [1:0] x_s0_auto_out_1_c_bits_user_alias = '0, x_s1_auto_out_1_c_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_1_c_bits_user_vaddr, x_i_auto_out_1_c_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_1_c_bits_user_vaddr = '0, x_s1_auto_out_1_c_bits_user_vaddr = '0;
  wire  x_g_auto_out_1_c_bits_user_needHint, x_i_auto_out_1_c_bits_user_needHint;
  logic x_s0_auto_out_1_c_bits_user_needHint = '0, x_s1_auto_out_1_c_bits_user_needHint = '0;
  wire  x_g_auto_out_1_c_bits_echo_isKeyword, x_i_auto_out_1_c_bits_echo_isKeyword;
  logic x_s0_auto_out_1_c_bits_echo_isKeyword = '0, x_s1_auto_out_1_c_bits_echo_isKeyword = '0;
  wire  [255:0] x_g_auto_out_1_c_bits_data, x_i_auto_out_1_c_bits_data;
  logic [255:0] x_s0_auto_out_1_c_bits_data = '0, x_s1_auto_out_1_c_bits_data = '0;
  wire  x_g_auto_out_1_c_bits_corrupt, x_i_auto_out_1_c_bits_corrupt;
  logic x_s0_auto_out_1_c_bits_corrupt = '0, x_s1_auto_out_1_c_bits_corrupt = '0;
  wire  x_g_auto_out_1_d_ready, x_i_auto_out_1_d_ready;
  logic x_s0_auto_out_1_d_ready = '0, x_s1_auto_out_1_d_ready = '0;
  logic x_auto_out_1_d_valid;
  logic [3:0] x_auto_out_1_d_bits_opcode;
  logic [1:0] x_auto_out_1_d_bits_param;
  logic [2:0] x_auto_out_1_d_bits_size;
  logic [6:0] x_auto_out_1_d_bits_source;
  logic [7:0] x_auto_out_1_d_bits_sink;
  logic x_auto_out_1_d_bits_denied;
  logic x_auto_out_1_d_bits_echo_isKeyword;
  logic [255:0] x_auto_out_1_d_bits_data;
  logic x_auto_out_1_d_bits_corrupt;
  logic x_auto_out_1_e_ready;
  wire  x_g_auto_out_1_e_valid, x_i_auto_out_1_e_valid;
  logic x_s0_auto_out_1_e_valid = '0, x_s1_auto_out_1_e_valid = '0;
  wire  [7:0] x_g_auto_out_1_e_bits_sink, x_i_auto_out_1_e_bits_sink;
  logic [7:0] x_s0_auto_out_1_e_bits_sink = '0, x_s1_auto_out_1_e_bits_sink = '0;
  logic x_auto_out_0_a_ready;
  wire  x_g_auto_out_0_a_valid, x_i_auto_out_0_a_valid;
  logic x_s0_auto_out_0_a_valid = '0, x_s1_auto_out_0_a_valid = '0;
  wire  [3:0] x_g_auto_out_0_a_bits_opcode, x_i_auto_out_0_a_bits_opcode;
  logic [3:0] x_s0_auto_out_0_a_bits_opcode = '0, x_s1_auto_out_0_a_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_0_a_bits_param, x_i_auto_out_0_a_bits_param;
  logic [2:0] x_s0_auto_out_0_a_bits_param = '0, x_s1_auto_out_0_a_bits_param = '0;
  wire  [2:0] x_g_auto_out_0_a_bits_size, x_i_auto_out_0_a_bits_size;
  logic [2:0] x_s0_auto_out_0_a_bits_size = '0, x_s1_auto_out_0_a_bits_size = '0;
  wire  [6:0] x_g_auto_out_0_a_bits_source, x_i_auto_out_0_a_bits_source;
  logic [6:0] x_s0_auto_out_0_a_bits_source = '0, x_s1_auto_out_0_a_bits_source = '0;
  wire  [47:0] x_g_auto_out_0_a_bits_address, x_i_auto_out_0_a_bits_address;
  logic [47:0] x_s0_auto_out_0_a_bits_address = '0, x_s1_auto_out_0_a_bits_address = '0;
  wire  [4:0] x_g_auto_out_0_a_bits_user_reqSource, x_i_auto_out_0_a_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_0_a_bits_user_reqSource = '0, x_s1_auto_out_0_a_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_0_a_bits_user_alias, x_i_auto_out_0_a_bits_user_alias;
  logic [1:0] x_s0_auto_out_0_a_bits_user_alias = '0, x_s1_auto_out_0_a_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_0_a_bits_user_vaddr, x_i_auto_out_0_a_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_0_a_bits_user_vaddr = '0, x_s1_auto_out_0_a_bits_user_vaddr = '0;
  wire  x_g_auto_out_0_a_bits_user_needHint, x_i_auto_out_0_a_bits_user_needHint;
  logic x_s0_auto_out_0_a_bits_user_needHint = '0, x_s1_auto_out_0_a_bits_user_needHint = '0;
  wire  x_g_auto_out_0_a_bits_echo_isKeyword, x_i_auto_out_0_a_bits_echo_isKeyword;
  logic x_s0_auto_out_0_a_bits_echo_isKeyword = '0, x_s1_auto_out_0_a_bits_echo_isKeyword = '0;
  wire  [31:0] x_g_auto_out_0_a_bits_mask, x_i_auto_out_0_a_bits_mask;
  logic [31:0] x_s0_auto_out_0_a_bits_mask = '0, x_s1_auto_out_0_a_bits_mask = '0;
  wire  [255:0] x_g_auto_out_0_a_bits_data, x_i_auto_out_0_a_bits_data;
  logic [255:0] x_s0_auto_out_0_a_bits_data = '0, x_s1_auto_out_0_a_bits_data = '0;
  wire  x_g_auto_out_0_a_bits_corrupt, x_i_auto_out_0_a_bits_corrupt;
  logic x_s0_auto_out_0_a_bits_corrupt = '0, x_s1_auto_out_0_a_bits_corrupt = '0;
  wire  x_g_auto_out_0_b_ready, x_i_auto_out_0_b_ready;
  logic x_s0_auto_out_0_b_ready = '0, x_s1_auto_out_0_b_ready = '0;
  logic x_auto_out_0_b_valid;
  logic [2:0] x_auto_out_0_b_bits_opcode;
  logic [1:0] x_auto_out_0_b_bits_param;
  logic [2:0] x_auto_out_0_b_bits_size;
  logic [6:0] x_auto_out_0_b_bits_source;
  logic [47:0] x_auto_out_0_b_bits_address;
  logic [31:0] x_auto_out_0_b_bits_mask;
  logic [255:0] x_auto_out_0_b_bits_data;
  logic x_auto_out_0_b_bits_corrupt;
  logic x_auto_out_0_c_ready;
  wire  x_g_auto_out_0_c_valid, x_i_auto_out_0_c_valid;
  logic x_s0_auto_out_0_c_valid = '0, x_s1_auto_out_0_c_valid = '0;
  wire  [2:0] x_g_auto_out_0_c_bits_opcode, x_i_auto_out_0_c_bits_opcode;
  logic [2:0] x_s0_auto_out_0_c_bits_opcode = '0, x_s1_auto_out_0_c_bits_opcode = '0;
  wire  [2:0] x_g_auto_out_0_c_bits_param, x_i_auto_out_0_c_bits_param;
  logic [2:0] x_s0_auto_out_0_c_bits_param = '0, x_s1_auto_out_0_c_bits_param = '0;
  wire  [2:0] x_g_auto_out_0_c_bits_size, x_i_auto_out_0_c_bits_size;
  logic [2:0] x_s0_auto_out_0_c_bits_size = '0, x_s1_auto_out_0_c_bits_size = '0;
  wire  [6:0] x_g_auto_out_0_c_bits_source, x_i_auto_out_0_c_bits_source;
  logic [6:0] x_s0_auto_out_0_c_bits_source = '0, x_s1_auto_out_0_c_bits_source = '0;
  wire  [47:0] x_g_auto_out_0_c_bits_address, x_i_auto_out_0_c_bits_address;
  logic [47:0] x_s0_auto_out_0_c_bits_address = '0, x_s1_auto_out_0_c_bits_address = '0;
  wire  [4:0] x_g_auto_out_0_c_bits_user_reqSource, x_i_auto_out_0_c_bits_user_reqSource;
  logic [4:0] x_s0_auto_out_0_c_bits_user_reqSource = '0, x_s1_auto_out_0_c_bits_user_reqSource = '0;
  wire  [1:0] x_g_auto_out_0_c_bits_user_alias, x_i_auto_out_0_c_bits_user_alias;
  logic [1:0] x_s0_auto_out_0_c_bits_user_alias = '0, x_s1_auto_out_0_c_bits_user_alias = '0;
  wire  [43:0] x_g_auto_out_0_c_bits_user_vaddr, x_i_auto_out_0_c_bits_user_vaddr;
  logic [43:0] x_s0_auto_out_0_c_bits_user_vaddr = '0, x_s1_auto_out_0_c_bits_user_vaddr = '0;
  wire  x_g_auto_out_0_c_bits_user_needHint, x_i_auto_out_0_c_bits_user_needHint;
  logic x_s0_auto_out_0_c_bits_user_needHint = '0, x_s1_auto_out_0_c_bits_user_needHint = '0;
  wire  x_g_auto_out_0_c_bits_echo_isKeyword, x_i_auto_out_0_c_bits_echo_isKeyword;
  logic x_s0_auto_out_0_c_bits_echo_isKeyword = '0, x_s1_auto_out_0_c_bits_echo_isKeyword = '0;
  wire  [255:0] x_g_auto_out_0_c_bits_data, x_i_auto_out_0_c_bits_data;
  logic [255:0] x_s0_auto_out_0_c_bits_data = '0, x_s1_auto_out_0_c_bits_data = '0;
  wire  x_g_auto_out_0_c_bits_corrupt, x_i_auto_out_0_c_bits_corrupt;
  logic x_s0_auto_out_0_c_bits_corrupt = '0, x_s1_auto_out_0_c_bits_corrupt = '0;
  wire  x_g_auto_out_0_d_ready, x_i_auto_out_0_d_ready;
  logic x_s0_auto_out_0_d_ready = '0, x_s1_auto_out_0_d_ready = '0;
  logic x_auto_out_0_d_valid;
  logic [3:0] x_auto_out_0_d_bits_opcode;
  logic [1:0] x_auto_out_0_d_bits_param;
  logic [2:0] x_auto_out_0_d_bits_size;
  logic [6:0] x_auto_out_0_d_bits_source;
  logic [7:0] x_auto_out_0_d_bits_sink;
  logic x_auto_out_0_d_bits_denied;
  logic x_auto_out_0_d_bits_echo_isKeyword;
  logic [255:0] x_auto_out_0_d_bits_data;
  logic x_auto_out_0_d_bits_corrupt;
  logic x_auto_out_0_e_ready;
  wire  x_g_auto_out_0_e_valid, x_i_auto_out_0_e_valid;
  logic x_s0_auto_out_0_e_valid = '0, x_s1_auto_out_0_e_valid = '0;
  wire  [7:0] x_g_auto_out_0_e_bits_sink, x_i_auto_out_0_e_bits_sink;
  logic [7:0] x_s0_auto_out_0_e_bits_sink = '0, x_s1_auto_out_0_e_bits_sink = '0;
  int x_cov_a_lock = 0;
  int x_cov_d_lock = 0;
  int x_cov_a0_fire = 0;
  int x_cov_a3_from_ptw = 0;
  int x_cov_a_contend = 0;
  int x_cov_b_fire = 0;
  int x_cov_c_fire = 0;
  int x_cov_d0_fire = 0;
  int x_cov_d1_fire = 0;
  int x_cov_d2_fire = 0;
  int x_cov_e_fire = 0;
  int x_cov_rr_flip = 0;
  logic [0:0] x_armed = '0;
  int x_armed_at = -1;
  TLXbar_5 x_u_gold (
    .clock(clk),
    .reset(x_reset),
    .auto_in_2_a_ready(x_g_auto_in_2_a_ready),
    .auto_in_2_a_valid(x_auto_in_2_a_valid),
    .auto_in_2_a_bits_opcode(x_auto_in_2_a_bits_opcode),
    .auto_in_2_a_bits_param(x_auto_in_2_a_bits_param),
    .auto_in_2_a_bits_size(x_auto_in_2_a_bits_size),
    .auto_in_2_a_bits_source(x_auto_in_2_a_bits_source),
    .auto_in_2_a_bits_address(x_auto_in_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource(x_auto_in_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_mask(x_auto_in_2_a_bits_mask),
    .auto_in_2_a_bits_data(x_auto_in_2_a_bits_data),
    .auto_in_2_a_bits_corrupt(x_auto_in_2_a_bits_corrupt),
    .auto_in_2_d_ready(x_auto_in_2_d_ready),
    .auto_in_2_d_valid(x_g_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode(x_g_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param(x_g_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size(x_g_auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source(x_g_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink(x_g_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied(x_g_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_data(x_g_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt(x_g_auto_in_2_d_bits_corrupt),
    .auto_in_1_a_ready(x_g_auto_in_1_a_ready),
    .auto_in_1_a_valid(x_auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(x_auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_param(x_auto_in_1_a_bits_param),
    .auto_in_1_a_bits_size(x_auto_in_1_a_bits_size),
    .auto_in_1_a_bits_source(x_auto_in_1_a_bits_source),
    .auto_in_1_a_bits_address(x_auto_in_1_a_bits_address),
    .auto_in_1_a_bits_user_alias(x_auto_in_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_reqSource(x_auto_in_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_needHint(x_auto_in_1_a_bits_user_needHint),
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
    .auto_in_0_a_bits_user_alias(x_auto_in_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr(x_auto_in_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_reqSource(x_auto_in_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_needHint(x_auto_in_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword(x_auto_in_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask(x_auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(x_auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(x_auto_in_0_a_bits_corrupt),
    .auto_in_0_b_ready(x_auto_in_0_b_ready),
    .auto_in_0_b_valid(x_g_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode(x_g_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param(x_g_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size(x_g_auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source(x_g_auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address(x_g_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask(x_g_auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data(x_g_auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt(x_g_auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready(x_g_auto_in_0_c_ready),
    .auto_in_0_c_valid(x_auto_in_0_c_valid),
    .auto_in_0_c_bits_opcode(x_auto_in_0_c_bits_opcode),
    .auto_in_0_c_bits_param(x_auto_in_0_c_bits_param),
    .auto_in_0_c_bits_size(x_auto_in_0_c_bits_size),
    .auto_in_0_c_bits_source(x_auto_in_0_c_bits_source),
    .auto_in_0_c_bits_address(x_auto_in_0_c_bits_address),
    .auto_in_0_c_bits_user_alias(x_auto_in_0_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr(x_auto_in_0_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_reqSource(x_auto_in_0_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_needHint(x_auto_in_0_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword(x_auto_in_0_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data(x_auto_in_0_c_bits_data),
    .auto_in_0_c_bits_corrupt(x_auto_in_0_c_bits_corrupt),
    .auto_in_0_d_ready(x_auto_in_0_d_ready),
    .auto_in_0_d_valid(x_g_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(x_g_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(x_g_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(x_g_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source(x_g_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink(x_g_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(x_g_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword(x_g_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data(x_g_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(x_g_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready(x_g_auto_in_0_e_ready),
    .auto_in_0_e_valid(x_auto_in_0_e_valid),
    .auto_in_0_e_bits_sink(x_auto_in_0_e_bits_sink),
    .auto_out_3_a_ready(x_auto_out_3_a_ready),
    .auto_out_3_a_valid(x_g_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode(x_g_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_param(x_g_auto_out_3_a_bits_param),
    .auto_out_3_a_bits_size(x_g_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source(x_g_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address(x_g_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_user_reqSource(x_g_auto_out_3_a_bits_user_reqSource),
    .auto_out_3_a_bits_user_alias(x_g_auto_out_3_a_bits_user_alias),
    .auto_out_3_a_bits_user_vaddr(x_g_auto_out_3_a_bits_user_vaddr),
    .auto_out_3_a_bits_user_needHint(x_g_auto_out_3_a_bits_user_needHint),
    .auto_out_3_a_bits_echo_isKeyword(x_g_auto_out_3_a_bits_echo_isKeyword),
    .auto_out_3_a_bits_mask(x_g_auto_out_3_a_bits_mask),
    .auto_out_3_a_bits_data(x_g_auto_out_3_a_bits_data),
    .auto_out_3_a_bits_corrupt(x_g_auto_out_3_a_bits_corrupt),
    .auto_out_3_b_ready(x_g_auto_out_3_b_ready),
    .auto_out_3_b_valid(x_auto_out_3_b_valid),
    .auto_out_3_b_bits_opcode(x_auto_out_3_b_bits_opcode),
    .auto_out_3_b_bits_param(x_auto_out_3_b_bits_param),
    .auto_out_3_b_bits_size(x_auto_out_3_b_bits_size),
    .auto_out_3_b_bits_source(x_auto_out_3_b_bits_source),
    .auto_out_3_b_bits_address(x_auto_out_3_b_bits_address),
    .auto_out_3_b_bits_mask(x_auto_out_3_b_bits_mask),
    .auto_out_3_b_bits_data(x_auto_out_3_b_bits_data),
    .auto_out_3_b_bits_corrupt(x_auto_out_3_b_bits_corrupt),
    .auto_out_3_c_ready(x_auto_out_3_c_ready),
    .auto_out_3_c_valid(x_g_auto_out_3_c_valid),
    .auto_out_3_c_bits_opcode(x_g_auto_out_3_c_bits_opcode),
    .auto_out_3_c_bits_param(x_g_auto_out_3_c_bits_param),
    .auto_out_3_c_bits_size(x_g_auto_out_3_c_bits_size),
    .auto_out_3_c_bits_source(x_g_auto_out_3_c_bits_source),
    .auto_out_3_c_bits_address(x_g_auto_out_3_c_bits_address),
    .auto_out_3_c_bits_user_reqSource(x_g_auto_out_3_c_bits_user_reqSource),
    .auto_out_3_c_bits_user_alias(x_g_auto_out_3_c_bits_user_alias),
    .auto_out_3_c_bits_user_vaddr(x_g_auto_out_3_c_bits_user_vaddr),
    .auto_out_3_c_bits_user_needHint(x_g_auto_out_3_c_bits_user_needHint),
    .auto_out_3_c_bits_echo_isKeyword(x_g_auto_out_3_c_bits_echo_isKeyword),
    .auto_out_3_c_bits_data(x_g_auto_out_3_c_bits_data),
    .auto_out_3_c_bits_corrupt(x_g_auto_out_3_c_bits_corrupt),
    .auto_out_3_d_ready(x_g_auto_out_3_d_ready),
    .auto_out_3_d_valid(x_auto_out_3_d_valid),
    .auto_out_3_d_bits_opcode(x_auto_out_3_d_bits_opcode),
    .auto_out_3_d_bits_param(x_auto_out_3_d_bits_param),
    .auto_out_3_d_bits_size(x_auto_out_3_d_bits_size),
    .auto_out_3_d_bits_source(x_auto_out_3_d_bits_source),
    .auto_out_3_d_bits_sink(x_auto_out_3_d_bits_sink),
    .auto_out_3_d_bits_denied(x_auto_out_3_d_bits_denied),
    .auto_out_3_d_bits_echo_isKeyword(x_auto_out_3_d_bits_echo_isKeyword),
    .auto_out_3_d_bits_data(x_auto_out_3_d_bits_data),
    .auto_out_3_d_bits_corrupt(x_auto_out_3_d_bits_corrupt),
    .auto_out_3_e_ready(x_auto_out_3_e_ready),
    .auto_out_3_e_valid(x_g_auto_out_3_e_valid),
    .auto_out_3_e_bits_sink(x_g_auto_out_3_e_bits_sink),
    .auto_out_2_a_ready(x_auto_out_2_a_ready),
    .auto_out_2_a_valid(x_g_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(x_g_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(x_g_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(x_g_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(x_g_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(x_g_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource(x_g_auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_user_alias(x_g_auto_out_2_a_bits_user_alias),
    .auto_out_2_a_bits_user_vaddr(x_g_auto_out_2_a_bits_user_vaddr),
    .auto_out_2_a_bits_user_needHint(x_g_auto_out_2_a_bits_user_needHint),
    .auto_out_2_a_bits_echo_isKeyword(x_g_auto_out_2_a_bits_echo_isKeyword),
    .auto_out_2_a_bits_mask(x_g_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(x_g_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(x_g_auto_out_2_a_bits_corrupt),
    .auto_out_2_b_ready(x_g_auto_out_2_b_ready),
    .auto_out_2_b_valid(x_auto_out_2_b_valid),
    .auto_out_2_b_bits_opcode(x_auto_out_2_b_bits_opcode),
    .auto_out_2_b_bits_param(x_auto_out_2_b_bits_param),
    .auto_out_2_b_bits_size(x_auto_out_2_b_bits_size),
    .auto_out_2_b_bits_source(x_auto_out_2_b_bits_source),
    .auto_out_2_b_bits_address(x_auto_out_2_b_bits_address),
    .auto_out_2_b_bits_mask(x_auto_out_2_b_bits_mask),
    .auto_out_2_b_bits_data(x_auto_out_2_b_bits_data),
    .auto_out_2_b_bits_corrupt(x_auto_out_2_b_bits_corrupt),
    .auto_out_2_c_ready(x_auto_out_2_c_ready),
    .auto_out_2_c_valid(x_g_auto_out_2_c_valid),
    .auto_out_2_c_bits_opcode(x_g_auto_out_2_c_bits_opcode),
    .auto_out_2_c_bits_param(x_g_auto_out_2_c_bits_param),
    .auto_out_2_c_bits_size(x_g_auto_out_2_c_bits_size),
    .auto_out_2_c_bits_source(x_g_auto_out_2_c_bits_source),
    .auto_out_2_c_bits_address(x_g_auto_out_2_c_bits_address),
    .auto_out_2_c_bits_user_reqSource(x_g_auto_out_2_c_bits_user_reqSource),
    .auto_out_2_c_bits_user_alias(x_g_auto_out_2_c_bits_user_alias),
    .auto_out_2_c_bits_user_vaddr(x_g_auto_out_2_c_bits_user_vaddr),
    .auto_out_2_c_bits_user_needHint(x_g_auto_out_2_c_bits_user_needHint),
    .auto_out_2_c_bits_echo_isKeyword(x_g_auto_out_2_c_bits_echo_isKeyword),
    .auto_out_2_c_bits_data(x_g_auto_out_2_c_bits_data),
    .auto_out_2_c_bits_corrupt(x_g_auto_out_2_c_bits_corrupt),
    .auto_out_2_d_ready(x_g_auto_out_2_d_ready),
    .auto_out_2_d_valid(x_auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(x_auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(x_auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(x_auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(x_auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(x_auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(x_auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_echo_isKeyword(x_auto_out_2_d_bits_echo_isKeyword),
    .auto_out_2_d_bits_data(x_auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(x_auto_out_2_d_bits_corrupt),
    .auto_out_2_e_ready(x_auto_out_2_e_ready),
    .auto_out_2_e_valid(x_g_auto_out_2_e_valid),
    .auto_out_2_e_bits_sink(x_g_auto_out_2_e_bits_sink),
    .auto_out_1_a_ready(x_auto_out_1_a_ready),
    .auto_out_1_a_valid(x_g_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(x_g_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(x_g_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(x_g_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(x_g_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(x_g_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_reqSource(x_g_auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_alias(x_g_auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_vaddr(x_g_auto_out_1_a_bits_user_vaddr),
    .auto_out_1_a_bits_user_needHint(x_g_auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_echo_isKeyword(x_g_auto_out_1_a_bits_echo_isKeyword),
    .auto_out_1_a_bits_mask(x_g_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(x_g_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(x_g_auto_out_1_a_bits_corrupt),
    .auto_out_1_b_ready(x_g_auto_out_1_b_ready),
    .auto_out_1_b_valid(x_auto_out_1_b_valid),
    .auto_out_1_b_bits_opcode(x_auto_out_1_b_bits_opcode),
    .auto_out_1_b_bits_param(x_auto_out_1_b_bits_param),
    .auto_out_1_b_bits_size(x_auto_out_1_b_bits_size),
    .auto_out_1_b_bits_source(x_auto_out_1_b_bits_source),
    .auto_out_1_b_bits_address(x_auto_out_1_b_bits_address),
    .auto_out_1_b_bits_mask(x_auto_out_1_b_bits_mask),
    .auto_out_1_b_bits_data(x_auto_out_1_b_bits_data),
    .auto_out_1_b_bits_corrupt(x_auto_out_1_b_bits_corrupt),
    .auto_out_1_c_ready(x_auto_out_1_c_ready),
    .auto_out_1_c_valid(x_g_auto_out_1_c_valid),
    .auto_out_1_c_bits_opcode(x_g_auto_out_1_c_bits_opcode),
    .auto_out_1_c_bits_param(x_g_auto_out_1_c_bits_param),
    .auto_out_1_c_bits_size(x_g_auto_out_1_c_bits_size),
    .auto_out_1_c_bits_source(x_g_auto_out_1_c_bits_source),
    .auto_out_1_c_bits_address(x_g_auto_out_1_c_bits_address),
    .auto_out_1_c_bits_user_reqSource(x_g_auto_out_1_c_bits_user_reqSource),
    .auto_out_1_c_bits_user_alias(x_g_auto_out_1_c_bits_user_alias),
    .auto_out_1_c_bits_user_vaddr(x_g_auto_out_1_c_bits_user_vaddr),
    .auto_out_1_c_bits_user_needHint(x_g_auto_out_1_c_bits_user_needHint),
    .auto_out_1_c_bits_echo_isKeyword(x_g_auto_out_1_c_bits_echo_isKeyword),
    .auto_out_1_c_bits_data(x_g_auto_out_1_c_bits_data),
    .auto_out_1_c_bits_corrupt(x_g_auto_out_1_c_bits_corrupt),
    .auto_out_1_d_ready(x_g_auto_out_1_d_ready),
    .auto_out_1_d_valid(x_auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(x_auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(x_auto_out_1_d_bits_param),
    .auto_out_1_d_bits_size(x_auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(x_auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(x_auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(x_auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_echo_isKeyword(x_auto_out_1_d_bits_echo_isKeyword),
    .auto_out_1_d_bits_data(x_auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(x_auto_out_1_d_bits_corrupt),
    .auto_out_1_e_ready(x_auto_out_1_e_ready),
    .auto_out_1_e_valid(x_g_auto_out_1_e_valid),
    .auto_out_1_e_bits_sink(x_g_auto_out_1_e_bits_sink),
    .auto_out_0_a_ready(x_auto_out_0_a_ready),
    .auto_out_0_a_valid(x_g_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(x_g_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(x_g_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(x_g_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(x_g_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(x_g_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_reqSource(x_g_auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_alias(x_g_auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr(x_g_auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_needHint(x_g_auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword(x_g_auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_mask(x_g_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(x_g_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(x_g_auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready(x_g_auto_out_0_b_ready),
    .auto_out_0_b_valid(x_auto_out_0_b_valid),
    .auto_out_0_b_bits_opcode(x_auto_out_0_b_bits_opcode),
    .auto_out_0_b_bits_param(x_auto_out_0_b_bits_param),
    .auto_out_0_b_bits_size(x_auto_out_0_b_bits_size),
    .auto_out_0_b_bits_source(x_auto_out_0_b_bits_source),
    .auto_out_0_b_bits_address(x_auto_out_0_b_bits_address),
    .auto_out_0_b_bits_mask(x_auto_out_0_b_bits_mask),
    .auto_out_0_b_bits_data(x_auto_out_0_b_bits_data),
    .auto_out_0_b_bits_corrupt(x_auto_out_0_b_bits_corrupt),
    .auto_out_0_c_ready(x_auto_out_0_c_ready),
    .auto_out_0_c_valid(x_g_auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode(x_g_auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param(x_g_auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size(x_g_auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source(x_g_auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address(x_g_auto_out_0_c_bits_address),
    .auto_out_0_c_bits_user_reqSource(x_g_auto_out_0_c_bits_user_reqSource),
    .auto_out_0_c_bits_user_alias(x_g_auto_out_0_c_bits_user_alias),
    .auto_out_0_c_bits_user_vaddr(x_g_auto_out_0_c_bits_user_vaddr),
    .auto_out_0_c_bits_user_needHint(x_g_auto_out_0_c_bits_user_needHint),
    .auto_out_0_c_bits_echo_isKeyword(x_g_auto_out_0_c_bits_echo_isKeyword),
    .auto_out_0_c_bits_data(x_g_auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt(x_g_auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready(x_g_auto_out_0_d_ready),
    .auto_out_0_d_valid(x_auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(x_auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(x_auto_out_0_d_bits_param),
    .auto_out_0_d_bits_size(x_auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(x_auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(x_auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(x_auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword(x_auto_out_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data(x_auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(x_auto_out_0_d_bits_corrupt),
    .auto_out_0_e_ready(x_auto_out_0_e_ready),
    .auto_out_0_e_valid(x_g_auto_out_0_e_valid),
    .auto_out_0_e_bits_sink(x_g_auto_out_0_e_bits_sink)
  );
  TLXbar_5_xs x_u_impl (
    .clock(clk),
    .reset(x_reset),
    .auto_in_2_a_ready(x_i_auto_in_2_a_ready),
    .auto_in_2_a_valid(x_auto_in_2_a_valid),
    .auto_in_2_a_bits_opcode(x_auto_in_2_a_bits_opcode),
    .auto_in_2_a_bits_param(x_auto_in_2_a_bits_param),
    .auto_in_2_a_bits_size(x_auto_in_2_a_bits_size),
    .auto_in_2_a_bits_source(x_auto_in_2_a_bits_source),
    .auto_in_2_a_bits_address(x_auto_in_2_a_bits_address),
    .auto_in_2_a_bits_user_reqSource(x_auto_in_2_a_bits_user_reqSource),
    .auto_in_2_a_bits_mask(x_auto_in_2_a_bits_mask),
    .auto_in_2_a_bits_data(x_auto_in_2_a_bits_data),
    .auto_in_2_a_bits_corrupt(x_auto_in_2_a_bits_corrupt),
    .auto_in_2_d_ready(x_auto_in_2_d_ready),
    .auto_in_2_d_valid(x_i_auto_in_2_d_valid),
    .auto_in_2_d_bits_opcode(x_i_auto_in_2_d_bits_opcode),
    .auto_in_2_d_bits_param(x_i_auto_in_2_d_bits_param),
    .auto_in_2_d_bits_size(x_i_auto_in_2_d_bits_size),
    .auto_in_2_d_bits_source(x_i_auto_in_2_d_bits_source),
    .auto_in_2_d_bits_sink(x_i_auto_in_2_d_bits_sink),
    .auto_in_2_d_bits_denied(x_i_auto_in_2_d_bits_denied),
    .auto_in_2_d_bits_data(x_i_auto_in_2_d_bits_data),
    .auto_in_2_d_bits_corrupt(x_i_auto_in_2_d_bits_corrupt),
    .auto_in_1_a_ready(x_i_auto_in_1_a_ready),
    .auto_in_1_a_valid(x_auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(x_auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_param(x_auto_in_1_a_bits_param),
    .auto_in_1_a_bits_size(x_auto_in_1_a_bits_size),
    .auto_in_1_a_bits_source(x_auto_in_1_a_bits_source),
    .auto_in_1_a_bits_address(x_auto_in_1_a_bits_address),
    .auto_in_1_a_bits_user_alias(x_auto_in_1_a_bits_user_alias),
    .auto_in_1_a_bits_user_reqSource(x_auto_in_1_a_bits_user_reqSource),
    .auto_in_1_a_bits_user_needHint(x_auto_in_1_a_bits_user_needHint),
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
    .auto_in_0_a_bits_user_alias(x_auto_in_0_a_bits_user_alias),
    .auto_in_0_a_bits_user_vaddr(x_auto_in_0_a_bits_user_vaddr),
    .auto_in_0_a_bits_user_reqSource(x_auto_in_0_a_bits_user_reqSource),
    .auto_in_0_a_bits_user_needHint(x_auto_in_0_a_bits_user_needHint),
    .auto_in_0_a_bits_echo_isKeyword(x_auto_in_0_a_bits_echo_isKeyword),
    .auto_in_0_a_bits_mask(x_auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(x_auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(x_auto_in_0_a_bits_corrupt),
    .auto_in_0_b_ready(x_auto_in_0_b_ready),
    .auto_in_0_b_valid(x_i_auto_in_0_b_valid),
    .auto_in_0_b_bits_opcode(x_i_auto_in_0_b_bits_opcode),
    .auto_in_0_b_bits_param(x_i_auto_in_0_b_bits_param),
    .auto_in_0_b_bits_size(x_i_auto_in_0_b_bits_size),
    .auto_in_0_b_bits_source(x_i_auto_in_0_b_bits_source),
    .auto_in_0_b_bits_address(x_i_auto_in_0_b_bits_address),
    .auto_in_0_b_bits_mask(x_i_auto_in_0_b_bits_mask),
    .auto_in_0_b_bits_data(x_i_auto_in_0_b_bits_data),
    .auto_in_0_b_bits_corrupt(x_i_auto_in_0_b_bits_corrupt),
    .auto_in_0_c_ready(x_i_auto_in_0_c_ready),
    .auto_in_0_c_valid(x_auto_in_0_c_valid),
    .auto_in_0_c_bits_opcode(x_auto_in_0_c_bits_opcode),
    .auto_in_0_c_bits_param(x_auto_in_0_c_bits_param),
    .auto_in_0_c_bits_size(x_auto_in_0_c_bits_size),
    .auto_in_0_c_bits_source(x_auto_in_0_c_bits_source),
    .auto_in_0_c_bits_address(x_auto_in_0_c_bits_address),
    .auto_in_0_c_bits_user_alias(x_auto_in_0_c_bits_user_alias),
    .auto_in_0_c_bits_user_vaddr(x_auto_in_0_c_bits_user_vaddr),
    .auto_in_0_c_bits_user_reqSource(x_auto_in_0_c_bits_user_reqSource),
    .auto_in_0_c_bits_user_needHint(x_auto_in_0_c_bits_user_needHint),
    .auto_in_0_c_bits_echo_isKeyword(x_auto_in_0_c_bits_echo_isKeyword),
    .auto_in_0_c_bits_data(x_auto_in_0_c_bits_data),
    .auto_in_0_c_bits_corrupt(x_auto_in_0_c_bits_corrupt),
    .auto_in_0_d_ready(x_auto_in_0_d_ready),
    .auto_in_0_d_valid(x_i_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(x_i_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(x_i_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(x_i_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source(x_i_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink(x_i_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(x_i_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_echo_isKeyword(x_i_auto_in_0_d_bits_echo_isKeyword),
    .auto_in_0_d_bits_data(x_i_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(x_i_auto_in_0_d_bits_corrupt),
    .auto_in_0_e_ready(x_i_auto_in_0_e_ready),
    .auto_in_0_e_valid(x_auto_in_0_e_valid),
    .auto_in_0_e_bits_sink(x_auto_in_0_e_bits_sink),
    .auto_out_3_a_ready(x_auto_out_3_a_ready),
    .auto_out_3_a_valid(x_i_auto_out_3_a_valid),
    .auto_out_3_a_bits_opcode(x_i_auto_out_3_a_bits_opcode),
    .auto_out_3_a_bits_param(x_i_auto_out_3_a_bits_param),
    .auto_out_3_a_bits_size(x_i_auto_out_3_a_bits_size),
    .auto_out_3_a_bits_source(x_i_auto_out_3_a_bits_source),
    .auto_out_3_a_bits_address(x_i_auto_out_3_a_bits_address),
    .auto_out_3_a_bits_user_reqSource(x_i_auto_out_3_a_bits_user_reqSource),
    .auto_out_3_a_bits_user_alias(x_i_auto_out_3_a_bits_user_alias),
    .auto_out_3_a_bits_user_vaddr(x_i_auto_out_3_a_bits_user_vaddr),
    .auto_out_3_a_bits_user_needHint(x_i_auto_out_3_a_bits_user_needHint),
    .auto_out_3_a_bits_echo_isKeyword(x_i_auto_out_3_a_bits_echo_isKeyword),
    .auto_out_3_a_bits_mask(x_i_auto_out_3_a_bits_mask),
    .auto_out_3_a_bits_data(x_i_auto_out_3_a_bits_data),
    .auto_out_3_a_bits_corrupt(x_i_auto_out_3_a_bits_corrupt),
    .auto_out_3_b_ready(x_i_auto_out_3_b_ready),
    .auto_out_3_b_valid(x_auto_out_3_b_valid),
    .auto_out_3_b_bits_opcode(x_auto_out_3_b_bits_opcode),
    .auto_out_3_b_bits_param(x_auto_out_3_b_bits_param),
    .auto_out_3_b_bits_size(x_auto_out_3_b_bits_size),
    .auto_out_3_b_bits_source(x_auto_out_3_b_bits_source),
    .auto_out_3_b_bits_address(x_auto_out_3_b_bits_address),
    .auto_out_3_b_bits_mask(x_auto_out_3_b_bits_mask),
    .auto_out_3_b_bits_data(x_auto_out_3_b_bits_data),
    .auto_out_3_b_bits_corrupt(x_auto_out_3_b_bits_corrupt),
    .auto_out_3_c_ready(x_auto_out_3_c_ready),
    .auto_out_3_c_valid(x_i_auto_out_3_c_valid),
    .auto_out_3_c_bits_opcode(x_i_auto_out_3_c_bits_opcode),
    .auto_out_3_c_bits_param(x_i_auto_out_3_c_bits_param),
    .auto_out_3_c_bits_size(x_i_auto_out_3_c_bits_size),
    .auto_out_3_c_bits_source(x_i_auto_out_3_c_bits_source),
    .auto_out_3_c_bits_address(x_i_auto_out_3_c_bits_address),
    .auto_out_3_c_bits_user_reqSource(x_i_auto_out_3_c_bits_user_reqSource),
    .auto_out_3_c_bits_user_alias(x_i_auto_out_3_c_bits_user_alias),
    .auto_out_3_c_bits_user_vaddr(x_i_auto_out_3_c_bits_user_vaddr),
    .auto_out_3_c_bits_user_needHint(x_i_auto_out_3_c_bits_user_needHint),
    .auto_out_3_c_bits_echo_isKeyword(x_i_auto_out_3_c_bits_echo_isKeyword),
    .auto_out_3_c_bits_data(x_i_auto_out_3_c_bits_data),
    .auto_out_3_c_bits_corrupt(x_i_auto_out_3_c_bits_corrupt),
    .auto_out_3_d_ready(x_i_auto_out_3_d_ready),
    .auto_out_3_d_valid(x_auto_out_3_d_valid),
    .auto_out_3_d_bits_opcode(x_auto_out_3_d_bits_opcode),
    .auto_out_3_d_bits_param(x_auto_out_3_d_bits_param),
    .auto_out_3_d_bits_size(x_auto_out_3_d_bits_size),
    .auto_out_3_d_bits_source(x_auto_out_3_d_bits_source),
    .auto_out_3_d_bits_sink(x_auto_out_3_d_bits_sink),
    .auto_out_3_d_bits_denied(x_auto_out_3_d_bits_denied),
    .auto_out_3_d_bits_echo_isKeyword(x_auto_out_3_d_bits_echo_isKeyword),
    .auto_out_3_d_bits_data(x_auto_out_3_d_bits_data),
    .auto_out_3_d_bits_corrupt(x_auto_out_3_d_bits_corrupt),
    .auto_out_3_e_ready(x_auto_out_3_e_ready),
    .auto_out_3_e_valid(x_i_auto_out_3_e_valid),
    .auto_out_3_e_bits_sink(x_i_auto_out_3_e_bits_sink),
    .auto_out_2_a_ready(x_auto_out_2_a_ready),
    .auto_out_2_a_valid(x_i_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(x_i_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(x_i_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(x_i_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(x_i_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(x_i_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_user_reqSource(x_i_auto_out_2_a_bits_user_reqSource),
    .auto_out_2_a_bits_user_alias(x_i_auto_out_2_a_bits_user_alias),
    .auto_out_2_a_bits_user_vaddr(x_i_auto_out_2_a_bits_user_vaddr),
    .auto_out_2_a_bits_user_needHint(x_i_auto_out_2_a_bits_user_needHint),
    .auto_out_2_a_bits_echo_isKeyword(x_i_auto_out_2_a_bits_echo_isKeyword),
    .auto_out_2_a_bits_mask(x_i_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(x_i_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(x_i_auto_out_2_a_bits_corrupt),
    .auto_out_2_b_ready(x_i_auto_out_2_b_ready),
    .auto_out_2_b_valid(x_auto_out_2_b_valid),
    .auto_out_2_b_bits_opcode(x_auto_out_2_b_bits_opcode),
    .auto_out_2_b_bits_param(x_auto_out_2_b_bits_param),
    .auto_out_2_b_bits_size(x_auto_out_2_b_bits_size),
    .auto_out_2_b_bits_source(x_auto_out_2_b_bits_source),
    .auto_out_2_b_bits_address(x_auto_out_2_b_bits_address),
    .auto_out_2_b_bits_mask(x_auto_out_2_b_bits_mask),
    .auto_out_2_b_bits_data(x_auto_out_2_b_bits_data),
    .auto_out_2_b_bits_corrupt(x_auto_out_2_b_bits_corrupt),
    .auto_out_2_c_ready(x_auto_out_2_c_ready),
    .auto_out_2_c_valid(x_i_auto_out_2_c_valid),
    .auto_out_2_c_bits_opcode(x_i_auto_out_2_c_bits_opcode),
    .auto_out_2_c_bits_param(x_i_auto_out_2_c_bits_param),
    .auto_out_2_c_bits_size(x_i_auto_out_2_c_bits_size),
    .auto_out_2_c_bits_source(x_i_auto_out_2_c_bits_source),
    .auto_out_2_c_bits_address(x_i_auto_out_2_c_bits_address),
    .auto_out_2_c_bits_user_reqSource(x_i_auto_out_2_c_bits_user_reqSource),
    .auto_out_2_c_bits_user_alias(x_i_auto_out_2_c_bits_user_alias),
    .auto_out_2_c_bits_user_vaddr(x_i_auto_out_2_c_bits_user_vaddr),
    .auto_out_2_c_bits_user_needHint(x_i_auto_out_2_c_bits_user_needHint),
    .auto_out_2_c_bits_echo_isKeyword(x_i_auto_out_2_c_bits_echo_isKeyword),
    .auto_out_2_c_bits_data(x_i_auto_out_2_c_bits_data),
    .auto_out_2_c_bits_corrupt(x_i_auto_out_2_c_bits_corrupt),
    .auto_out_2_d_ready(x_i_auto_out_2_d_ready),
    .auto_out_2_d_valid(x_auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(x_auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(x_auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(x_auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(x_auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(x_auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(x_auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_echo_isKeyword(x_auto_out_2_d_bits_echo_isKeyword),
    .auto_out_2_d_bits_data(x_auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(x_auto_out_2_d_bits_corrupt),
    .auto_out_2_e_ready(x_auto_out_2_e_ready),
    .auto_out_2_e_valid(x_i_auto_out_2_e_valid),
    .auto_out_2_e_bits_sink(x_i_auto_out_2_e_bits_sink),
    .auto_out_1_a_ready(x_auto_out_1_a_ready),
    .auto_out_1_a_valid(x_i_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(x_i_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_param(x_i_auto_out_1_a_bits_param),
    .auto_out_1_a_bits_size(x_i_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(x_i_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(x_i_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_reqSource(x_i_auto_out_1_a_bits_user_reqSource),
    .auto_out_1_a_bits_user_alias(x_i_auto_out_1_a_bits_user_alias),
    .auto_out_1_a_bits_user_vaddr(x_i_auto_out_1_a_bits_user_vaddr),
    .auto_out_1_a_bits_user_needHint(x_i_auto_out_1_a_bits_user_needHint),
    .auto_out_1_a_bits_echo_isKeyword(x_i_auto_out_1_a_bits_echo_isKeyword),
    .auto_out_1_a_bits_mask(x_i_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(x_i_auto_out_1_a_bits_data),
    .auto_out_1_a_bits_corrupt(x_i_auto_out_1_a_bits_corrupt),
    .auto_out_1_b_ready(x_i_auto_out_1_b_ready),
    .auto_out_1_b_valid(x_auto_out_1_b_valid),
    .auto_out_1_b_bits_opcode(x_auto_out_1_b_bits_opcode),
    .auto_out_1_b_bits_param(x_auto_out_1_b_bits_param),
    .auto_out_1_b_bits_size(x_auto_out_1_b_bits_size),
    .auto_out_1_b_bits_source(x_auto_out_1_b_bits_source),
    .auto_out_1_b_bits_address(x_auto_out_1_b_bits_address),
    .auto_out_1_b_bits_mask(x_auto_out_1_b_bits_mask),
    .auto_out_1_b_bits_data(x_auto_out_1_b_bits_data),
    .auto_out_1_b_bits_corrupt(x_auto_out_1_b_bits_corrupt),
    .auto_out_1_c_ready(x_auto_out_1_c_ready),
    .auto_out_1_c_valid(x_i_auto_out_1_c_valid),
    .auto_out_1_c_bits_opcode(x_i_auto_out_1_c_bits_opcode),
    .auto_out_1_c_bits_param(x_i_auto_out_1_c_bits_param),
    .auto_out_1_c_bits_size(x_i_auto_out_1_c_bits_size),
    .auto_out_1_c_bits_source(x_i_auto_out_1_c_bits_source),
    .auto_out_1_c_bits_address(x_i_auto_out_1_c_bits_address),
    .auto_out_1_c_bits_user_reqSource(x_i_auto_out_1_c_bits_user_reqSource),
    .auto_out_1_c_bits_user_alias(x_i_auto_out_1_c_bits_user_alias),
    .auto_out_1_c_bits_user_vaddr(x_i_auto_out_1_c_bits_user_vaddr),
    .auto_out_1_c_bits_user_needHint(x_i_auto_out_1_c_bits_user_needHint),
    .auto_out_1_c_bits_echo_isKeyword(x_i_auto_out_1_c_bits_echo_isKeyword),
    .auto_out_1_c_bits_data(x_i_auto_out_1_c_bits_data),
    .auto_out_1_c_bits_corrupt(x_i_auto_out_1_c_bits_corrupt),
    .auto_out_1_d_ready(x_i_auto_out_1_d_ready),
    .auto_out_1_d_valid(x_auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(x_auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_param(x_auto_out_1_d_bits_param),
    .auto_out_1_d_bits_size(x_auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(x_auto_out_1_d_bits_source),
    .auto_out_1_d_bits_sink(x_auto_out_1_d_bits_sink),
    .auto_out_1_d_bits_denied(x_auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_echo_isKeyword(x_auto_out_1_d_bits_echo_isKeyword),
    .auto_out_1_d_bits_data(x_auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(x_auto_out_1_d_bits_corrupt),
    .auto_out_1_e_ready(x_auto_out_1_e_ready),
    .auto_out_1_e_valid(x_i_auto_out_1_e_valid),
    .auto_out_1_e_bits_sink(x_i_auto_out_1_e_bits_sink),
    .auto_out_0_a_ready(x_auto_out_0_a_ready),
    .auto_out_0_a_valid(x_i_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(x_i_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(x_i_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(x_i_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(x_i_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(x_i_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_user_reqSource(x_i_auto_out_0_a_bits_user_reqSource),
    .auto_out_0_a_bits_user_alias(x_i_auto_out_0_a_bits_user_alias),
    .auto_out_0_a_bits_user_vaddr(x_i_auto_out_0_a_bits_user_vaddr),
    .auto_out_0_a_bits_user_needHint(x_i_auto_out_0_a_bits_user_needHint),
    .auto_out_0_a_bits_echo_isKeyword(x_i_auto_out_0_a_bits_echo_isKeyword),
    .auto_out_0_a_bits_mask(x_i_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(x_i_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(x_i_auto_out_0_a_bits_corrupt),
    .auto_out_0_b_ready(x_i_auto_out_0_b_ready),
    .auto_out_0_b_valid(x_auto_out_0_b_valid),
    .auto_out_0_b_bits_opcode(x_auto_out_0_b_bits_opcode),
    .auto_out_0_b_bits_param(x_auto_out_0_b_bits_param),
    .auto_out_0_b_bits_size(x_auto_out_0_b_bits_size),
    .auto_out_0_b_bits_source(x_auto_out_0_b_bits_source),
    .auto_out_0_b_bits_address(x_auto_out_0_b_bits_address),
    .auto_out_0_b_bits_mask(x_auto_out_0_b_bits_mask),
    .auto_out_0_b_bits_data(x_auto_out_0_b_bits_data),
    .auto_out_0_b_bits_corrupt(x_auto_out_0_b_bits_corrupt),
    .auto_out_0_c_ready(x_auto_out_0_c_ready),
    .auto_out_0_c_valid(x_i_auto_out_0_c_valid),
    .auto_out_0_c_bits_opcode(x_i_auto_out_0_c_bits_opcode),
    .auto_out_0_c_bits_param(x_i_auto_out_0_c_bits_param),
    .auto_out_0_c_bits_size(x_i_auto_out_0_c_bits_size),
    .auto_out_0_c_bits_source(x_i_auto_out_0_c_bits_source),
    .auto_out_0_c_bits_address(x_i_auto_out_0_c_bits_address),
    .auto_out_0_c_bits_user_reqSource(x_i_auto_out_0_c_bits_user_reqSource),
    .auto_out_0_c_bits_user_alias(x_i_auto_out_0_c_bits_user_alias),
    .auto_out_0_c_bits_user_vaddr(x_i_auto_out_0_c_bits_user_vaddr),
    .auto_out_0_c_bits_user_needHint(x_i_auto_out_0_c_bits_user_needHint),
    .auto_out_0_c_bits_echo_isKeyword(x_i_auto_out_0_c_bits_echo_isKeyword),
    .auto_out_0_c_bits_data(x_i_auto_out_0_c_bits_data),
    .auto_out_0_c_bits_corrupt(x_i_auto_out_0_c_bits_corrupt),
    .auto_out_0_d_ready(x_i_auto_out_0_d_ready),
    .auto_out_0_d_valid(x_auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(x_auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_param(x_auto_out_0_d_bits_param),
    .auto_out_0_d_bits_size(x_auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(x_auto_out_0_d_bits_source),
    .auto_out_0_d_bits_sink(x_auto_out_0_d_bits_sink),
    .auto_out_0_d_bits_denied(x_auto_out_0_d_bits_denied),
    .auto_out_0_d_bits_echo_isKeyword(x_auto_out_0_d_bits_echo_isKeyword),
    .auto_out_0_d_bits_data(x_auto_out_0_d_bits_data),
    .auto_out_0_d_bits_corrupt(x_auto_out_0_d_bits_corrupt),
    .auto_out_0_e_ready(x_auto_out_0_e_ready),
    .auto_out_0_e_valid(x_i_auto_out_0_e_valid),
    .auto_out_0_e_bits_sink(x_i_auto_out_0_e_bits_sink)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) x_mode = $urandom_range(0, 15);
      x_auto_in_2_a_valid = 1'($urandom);
      x_auto_in_2_a_bits_opcode = 4'($urandom);
      x_auto_in_2_a_bits_param = 3'($urandom);
      x_auto_in_2_a_bits_size = 3'($urandom);
      x_auto_in_2_a_bits_source = 4'($urandom);
      x_auto_in_2_a_bits_address = 48'({$urandom, $urandom});
      x_auto_in_2_a_bits_user_reqSource = 5'($urandom);
      x_auto_in_2_a_bits_mask = 32'($urandom);
      x_auto_in_2_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_in_2_a_bits_corrupt = 1'($urandom);
      x_auto_in_2_d_ready = 1'($urandom);
      x_auto_in_1_a_valid = 1'($urandom);
      x_auto_in_1_a_bits_opcode = 4'($urandom);
      x_auto_in_1_a_bits_param = 3'($urandom);
      x_auto_in_1_a_bits_size = 3'($urandom);
      x_auto_in_1_a_bits_source = 4'($urandom);
      x_auto_in_1_a_bits_address = 48'({$urandom, $urandom});
      x_auto_in_1_a_bits_user_alias = 2'($urandom);
      x_auto_in_1_a_bits_user_reqSource = 5'($urandom);
      x_auto_in_1_a_bits_user_needHint = 1'($urandom);
      x_auto_in_1_a_bits_mask = 32'($urandom);
      x_auto_in_1_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_in_1_a_bits_corrupt = 1'($urandom);
      x_auto_in_1_d_ready = 1'($urandom);
      x_auto_in_0_a_valid = 1'($urandom);
      x_auto_in_0_a_bits_opcode = 4'($urandom);
      x_auto_in_0_a_bits_param = 3'($urandom);
      x_auto_in_0_a_bits_size = 3'($urandom);
      x_auto_in_0_a_bits_source = 6'($urandom);
      x_auto_in_0_a_bits_address = 48'({$urandom, $urandom});
      x_auto_in_0_a_bits_user_alias = 2'($urandom);
      x_auto_in_0_a_bits_user_vaddr = 44'({$urandom, $urandom});
      x_auto_in_0_a_bits_user_reqSource = 5'($urandom);
      x_auto_in_0_a_bits_user_needHint = 1'($urandom);
      x_auto_in_0_a_bits_echo_isKeyword = 1'($urandom);
      x_auto_in_0_a_bits_mask = 32'($urandom);
      x_auto_in_0_a_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_in_0_a_bits_corrupt = 1'($urandom);
      x_auto_in_0_b_ready = 1'($urandom);
      x_auto_in_0_c_valid = 1'($urandom);
      x_auto_in_0_c_bits_opcode = 3'($urandom);
      x_auto_in_0_c_bits_param = 3'($urandom);
      x_auto_in_0_c_bits_size = 3'($urandom);
      x_auto_in_0_c_bits_source = 6'($urandom);
      x_auto_in_0_c_bits_address = 48'({$urandom, $urandom});
      x_auto_in_0_c_bits_user_alias = 2'($urandom);
      x_auto_in_0_c_bits_user_vaddr = 44'({$urandom, $urandom});
      x_auto_in_0_c_bits_user_reqSource = 5'($urandom);
      x_auto_in_0_c_bits_user_needHint = 1'($urandom);
      x_auto_in_0_c_bits_echo_isKeyword = 1'($urandom);
      x_auto_in_0_c_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_in_0_c_bits_corrupt = 1'($urandom);
      x_auto_in_0_d_ready = 1'($urandom);
      x_auto_in_0_e_valid = 1'($urandom);
      x_auto_in_0_e_bits_sink = 10'($urandom);
      x_auto_out_3_a_ready = 1'($urandom);
      x_auto_out_3_b_valid = 1'($urandom);
      x_auto_out_3_b_bits_opcode = 3'($urandom);
      x_auto_out_3_b_bits_param = 2'($urandom);
      x_auto_out_3_b_bits_size = 3'($urandom);
      x_auto_out_3_b_bits_source = 7'($urandom);
      x_auto_out_3_b_bits_address = 48'({$urandom, $urandom});
      x_auto_out_3_b_bits_mask = 32'($urandom);
      x_auto_out_3_b_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_3_b_bits_corrupt = 1'($urandom);
      x_auto_out_3_c_ready = 1'($urandom);
      x_auto_out_3_d_valid = 1'($urandom);
      x_auto_out_3_d_bits_opcode = 4'($urandom);
      x_auto_out_3_d_bits_param = 2'($urandom);
      x_auto_out_3_d_bits_size = 3'($urandom);
      x_auto_out_3_d_bits_source = 7'($urandom);
      x_auto_out_3_d_bits_sink = 8'($urandom);
      x_auto_out_3_d_bits_denied = 1'($urandom);
      x_auto_out_3_d_bits_echo_isKeyword = 1'($urandom);
      x_auto_out_3_d_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_3_d_bits_corrupt = 1'($urandom);
      x_auto_out_3_e_ready = 1'($urandom);
      x_auto_out_2_a_ready = 1'($urandom);
      x_auto_out_2_b_valid = 1'($urandom);
      x_auto_out_2_b_bits_opcode = 3'($urandom);
      x_auto_out_2_b_bits_param = 2'($urandom);
      x_auto_out_2_b_bits_size = 3'($urandom);
      x_auto_out_2_b_bits_source = 7'($urandom);
      x_auto_out_2_b_bits_address = 48'({$urandom, $urandom});
      x_auto_out_2_b_bits_mask = 32'($urandom);
      x_auto_out_2_b_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_2_b_bits_corrupt = 1'($urandom);
      x_auto_out_2_c_ready = 1'($urandom);
      x_auto_out_2_d_valid = 1'($urandom);
      x_auto_out_2_d_bits_opcode = 4'($urandom);
      x_auto_out_2_d_bits_param = 2'($urandom);
      x_auto_out_2_d_bits_size = 3'($urandom);
      x_auto_out_2_d_bits_source = 7'($urandom);
      x_auto_out_2_d_bits_sink = 8'($urandom);
      x_auto_out_2_d_bits_denied = 1'($urandom);
      x_auto_out_2_d_bits_echo_isKeyword = 1'($urandom);
      x_auto_out_2_d_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_2_d_bits_corrupt = 1'($urandom);
      x_auto_out_2_e_ready = 1'($urandom);
      x_auto_out_1_a_ready = 1'($urandom);
      x_auto_out_1_b_valid = 1'($urandom);
      x_auto_out_1_b_bits_opcode = 3'($urandom);
      x_auto_out_1_b_bits_param = 2'($urandom);
      x_auto_out_1_b_bits_size = 3'($urandom);
      x_auto_out_1_b_bits_source = 7'($urandom);
      x_auto_out_1_b_bits_address = 48'({$urandom, $urandom});
      x_auto_out_1_b_bits_mask = 32'($urandom);
      x_auto_out_1_b_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_1_b_bits_corrupt = 1'($urandom);
      x_auto_out_1_c_ready = 1'($urandom);
      x_auto_out_1_d_valid = 1'($urandom);
      x_auto_out_1_d_bits_opcode = 4'($urandom);
      x_auto_out_1_d_bits_param = 2'($urandom);
      x_auto_out_1_d_bits_size = 3'($urandom);
      x_auto_out_1_d_bits_source = 7'($urandom);
      x_auto_out_1_d_bits_sink = 8'($urandom);
      x_auto_out_1_d_bits_denied = 1'($urandom);
      x_auto_out_1_d_bits_echo_isKeyword = 1'($urandom);
      x_auto_out_1_d_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_1_d_bits_corrupt = 1'($urandom);
      x_auto_out_1_e_ready = 1'($urandom);
      x_auto_out_0_a_ready = 1'($urandom);
      x_auto_out_0_b_valid = 1'($urandom);
      x_auto_out_0_b_bits_opcode = 3'($urandom);
      x_auto_out_0_b_bits_param = 2'($urandom);
      x_auto_out_0_b_bits_size = 3'($urandom);
      x_auto_out_0_b_bits_source = 7'($urandom);
      x_auto_out_0_b_bits_address = 48'({$urandom, $urandom});
      x_auto_out_0_b_bits_mask = 32'($urandom);
      x_auto_out_0_b_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_0_b_bits_corrupt = 1'($urandom);
      x_auto_out_0_c_ready = 1'($urandom);
      x_auto_out_0_d_valid = 1'($urandom);
      x_auto_out_0_d_bits_opcode = 4'($urandom);
      x_auto_out_0_d_bits_param = 2'($urandom);
      x_auto_out_0_d_bits_size = 3'($urandom);
      x_auto_out_0_d_bits_source = 7'($urandom);
      x_auto_out_0_d_bits_sink = 8'($urandom);
      x_auto_out_0_d_bits_denied = 1'($urandom);
      x_auto_out_0_d_bits_echo_isKeyword = 1'($urandom);
      x_auto_out_0_d_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      x_auto_out_0_d_bits_corrupt = 1'($urandom);
      x_auto_out_0_e_ready = 1'($urandom);
      x_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_x
        if ($urandom_range(0, 3)) x_auto_out_0_d_bits_source = 7'({3'($urandom_range(0, 7) < 4 ? $urandom_range(0, 3) : ($urandom_range(0, 1) ? 5 : 4)), 4'($urandom)});
        if ($urandom_range(0, 3)) x_auto_out_1_d_bits_source = 7'({3'($urandom_range(0, 7) < 4 ? $urandom_range(0, 3) : ($urandom_range(0, 1) ? 5 : 4)), 4'($urandom)});
        if ($urandom_range(0, 3)) x_auto_out_2_d_bits_source = 7'({3'($urandom_range(0, 7) < 4 ? $urandom_range(0, 3) : ($urandom_range(0, 1) ? 5 : 4)), 4'($urandom)});
        if ($urandom_range(0, 3)) x_auto_out_3_d_bits_source = 7'({3'($urandom_range(0, 7) < 4 ? $urandom_range(0, 3) : ($urandom_range(0, 1) ? 5 : 4)), 4'($urandom)});
        
        if (x_mode >= 10) begin
          x_auto_out_0_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_out_1_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_out_2_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_out_3_a_ready = ($urandom_range(0, 7) == 0);
          x_auto_in_0_d_ready  = ($urandom_range(0, 7) == 0);
          x_auto_in_1_d_ready  = ($urandom_range(0, 7) == 0);
          x_auto_in_2_d_ready  = ($urandom_range(0, 7) == 0);
          x_auto_in_0_b_ready  = ($urandom_range(0, 7) == 0);
        end
      end
      #4;
      x_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&x_armed)) begin
        checks++;
        if (x_g_auto_in_2_a_ready !== x_i_auto_in_2_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_a_ready g=%h i=%h", cyc, x_g_auto_in_2_a_ready, x_i_auto_in_2_a_ready);
        end
        x_s1_auto_in_2_a_ready |= x_g_auto_in_2_a_ready;
        x_s0_auto_in_2_a_ready |= ~x_g_auto_in_2_a_ready;
        checks++;
        if (x_g_auto_in_2_d_valid !== x_i_auto_in_2_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_valid g=%h i=%h", cyc, x_g_auto_in_2_d_valid, x_i_auto_in_2_d_valid);
        end
        x_s1_auto_in_2_d_valid |= x_g_auto_in_2_d_valid;
        x_s0_auto_in_2_d_valid |= ~x_g_auto_in_2_d_valid;
        checks++;
        if (x_g_auto_in_2_d_bits_opcode !== x_i_auto_in_2_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_opcode g=%h i=%h", cyc, x_g_auto_in_2_d_bits_opcode, x_i_auto_in_2_d_bits_opcode);
        end
        x_s1_auto_in_2_d_bits_opcode |= x_g_auto_in_2_d_bits_opcode;
        x_s0_auto_in_2_d_bits_opcode |= ~x_g_auto_in_2_d_bits_opcode;
        checks++;
        if (x_g_auto_in_2_d_bits_param !== x_i_auto_in_2_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_param g=%h i=%h", cyc, x_g_auto_in_2_d_bits_param, x_i_auto_in_2_d_bits_param);
        end
        x_s1_auto_in_2_d_bits_param |= x_g_auto_in_2_d_bits_param;
        x_s0_auto_in_2_d_bits_param |= ~x_g_auto_in_2_d_bits_param;
        checks++;
        if (x_g_auto_in_2_d_bits_size !== x_i_auto_in_2_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_size g=%h i=%h", cyc, x_g_auto_in_2_d_bits_size, x_i_auto_in_2_d_bits_size);
        end
        x_s1_auto_in_2_d_bits_size |= x_g_auto_in_2_d_bits_size;
        x_s0_auto_in_2_d_bits_size |= ~x_g_auto_in_2_d_bits_size;
        checks++;
        if (x_g_auto_in_2_d_bits_source !== x_i_auto_in_2_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_source g=%h i=%h", cyc, x_g_auto_in_2_d_bits_source, x_i_auto_in_2_d_bits_source);
        end
        x_s1_auto_in_2_d_bits_source |= x_g_auto_in_2_d_bits_source;
        x_s0_auto_in_2_d_bits_source |= ~x_g_auto_in_2_d_bits_source;
        checks++;
        if (x_g_auto_in_2_d_bits_sink !== x_i_auto_in_2_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_sink g=%h i=%h", cyc, x_g_auto_in_2_d_bits_sink, x_i_auto_in_2_d_bits_sink);
        end
        x_s1_auto_in_2_d_bits_sink |= x_g_auto_in_2_d_bits_sink;
        x_s0_auto_in_2_d_bits_sink |= ~x_g_auto_in_2_d_bits_sink;
        checks++;
        if (x_g_auto_in_2_d_bits_denied !== x_i_auto_in_2_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_denied g=%h i=%h", cyc, x_g_auto_in_2_d_bits_denied, x_i_auto_in_2_d_bits_denied);
        end
        x_s1_auto_in_2_d_bits_denied |= x_g_auto_in_2_d_bits_denied;
        x_s0_auto_in_2_d_bits_denied |= ~x_g_auto_in_2_d_bits_denied;
        checks++;
        if (x_g_auto_in_2_d_bits_data !== x_i_auto_in_2_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_data g=%h i=%h", cyc, x_g_auto_in_2_d_bits_data, x_i_auto_in_2_d_bits_data);
        end
        x_s1_auto_in_2_d_bits_data |= x_g_auto_in_2_d_bits_data;
        x_s0_auto_in_2_d_bits_data |= ~x_g_auto_in_2_d_bits_data;
        checks++;
        if (x_g_auto_in_2_d_bits_corrupt !== x_i_auto_in_2_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_2_d_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_2_d_bits_corrupt, x_i_auto_in_2_d_bits_corrupt);
        end
        x_s1_auto_in_2_d_bits_corrupt |= x_g_auto_in_2_d_bits_corrupt;
        x_s0_auto_in_2_d_bits_corrupt |= ~x_g_auto_in_2_d_bits_corrupt;
        checks++;
        if (x_g_auto_in_1_a_ready !== x_i_auto_in_1_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_a_ready g=%h i=%h", cyc, x_g_auto_in_1_a_ready, x_i_auto_in_1_a_ready);
        end
        x_s1_auto_in_1_a_ready |= x_g_auto_in_1_a_ready;
        x_s0_auto_in_1_a_ready |= ~x_g_auto_in_1_a_ready;
        checks++;
        if (x_g_auto_in_1_d_valid !== x_i_auto_in_1_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_valid g=%h i=%h", cyc, x_g_auto_in_1_d_valid, x_i_auto_in_1_d_valid);
        end
        x_s1_auto_in_1_d_valid |= x_g_auto_in_1_d_valid;
        x_s0_auto_in_1_d_valid |= ~x_g_auto_in_1_d_valid;
        checks++;
        if (x_g_auto_in_1_d_bits_opcode !== x_i_auto_in_1_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_opcode g=%h i=%h", cyc, x_g_auto_in_1_d_bits_opcode, x_i_auto_in_1_d_bits_opcode);
        end
        x_s1_auto_in_1_d_bits_opcode |= x_g_auto_in_1_d_bits_opcode;
        x_s0_auto_in_1_d_bits_opcode |= ~x_g_auto_in_1_d_bits_opcode;
        checks++;
        if (x_g_auto_in_1_d_bits_param !== x_i_auto_in_1_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_param g=%h i=%h", cyc, x_g_auto_in_1_d_bits_param, x_i_auto_in_1_d_bits_param);
        end
        x_s1_auto_in_1_d_bits_param |= x_g_auto_in_1_d_bits_param;
        x_s0_auto_in_1_d_bits_param |= ~x_g_auto_in_1_d_bits_param;
        checks++;
        if (x_g_auto_in_1_d_bits_size !== x_i_auto_in_1_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_size g=%h i=%h", cyc, x_g_auto_in_1_d_bits_size, x_i_auto_in_1_d_bits_size);
        end
        x_s1_auto_in_1_d_bits_size |= x_g_auto_in_1_d_bits_size;
        x_s0_auto_in_1_d_bits_size |= ~x_g_auto_in_1_d_bits_size;
        checks++;
        if (x_g_auto_in_1_d_bits_source !== x_i_auto_in_1_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_source g=%h i=%h", cyc, x_g_auto_in_1_d_bits_source, x_i_auto_in_1_d_bits_source);
        end
        x_s1_auto_in_1_d_bits_source |= x_g_auto_in_1_d_bits_source;
        x_s0_auto_in_1_d_bits_source |= ~x_g_auto_in_1_d_bits_source;
        checks++;
        if (x_g_auto_in_1_d_bits_sink !== x_i_auto_in_1_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_sink g=%h i=%h", cyc, x_g_auto_in_1_d_bits_sink, x_i_auto_in_1_d_bits_sink);
        end
        x_s1_auto_in_1_d_bits_sink |= x_g_auto_in_1_d_bits_sink;
        x_s0_auto_in_1_d_bits_sink |= ~x_g_auto_in_1_d_bits_sink;
        checks++;
        if (x_g_auto_in_1_d_bits_denied !== x_i_auto_in_1_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_denied g=%h i=%h", cyc, x_g_auto_in_1_d_bits_denied, x_i_auto_in_1_d_bits_denied);
        end
        x_s1_auto_in_1_d_bits_denied |= x_g_auto_in_1_d_bits_denied;
        x_s0_auto_in_1_d_bits_denied |= ~x_g_auto_in_1_d_bits_denied;
        checks++;
        if (x_g_auto_in_1_d_bits_data !== x_i_auto_in_1_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_data g=%h i=%h", cyc, x_g_auto_in_1_d_bits_data, x_i_auto_in_1_d_bits_data);
        end
        x_s1_auto_in_1_d_bits_data |= x_g_auto_in_1_d_bits_data;
        x_s0_auto_in_1_d_bits_data |= ~x_g_auto_in_1_d_bits_data;
        checks++;
        if (x_g_auto_in_1_d_bits_corrupt !== x_i_auto_in_1_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_1_d_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_1_d_bits_corrupt, x_i_auto_in_1_d_bits_corrupt);
        end
        x_s1_auto_in_1_d_bits_corrupt |= x_g_auto_in_1_d_bits_corrupt;
        x_s0_auto_in_1_d_bits_corrupt |= ~x_g_auto_in_1_d_bits_corrupt;
        checks++;
        if (x_g_auto_in_0_a_ready !== x_i_auto_in_0_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_a_ready g=%h i=%h", cyc, x_g_auto_in_0_a_ready, x_i_auto_in_0_a_ready);
        end
        x_s1_auto_in_0_a_ready |= x_g_auto_in_0_a_ready;
        x_s0_auto_in_0_a_ready |= ~x_g_auto_in_0_a_ready;
        checks++;
        if (x_g_auto_in_0_b_valid !== x_i_auto_in_0_b_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_valid g=%h i=%h", cyc, x_g_auto_in_0_b_valid, x_i_auto_in_0_b_valid);
        end
        x_s1_auto_in_0_b_valid |= x_g_auto_in_0_b_valid;
        x_s0_auto_in_0_b_valid |= ~x_g_auto_in_0_b_valid;
        checks++;
        if (x_g_auto_in_0_b_bits_opcode !== x_i_auto_in_0_b_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_opcode g=%h i=%h", cyc, x_g_auto_in_0_b_bits_opcode, x_i_auto_in_0_b_bits_opcode);
        end
        x_s1_auto_in_0_b_bits_opcode |= x_g_auto_in_0_b_bits_opcode;
        x_s0_auto_in_0_b_bits_opcode |= ~x_g_auto_in_0_b_bits_opcode;
        checks++;
        if (x_g_auto_in_0_b_bits_param !== x_i_auto_in_0_b_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_param g=%h i=%h", cyc, x_g_auto_in_0_b_bits_param, x_i_auto_in_0_b_bits_param);
        end
        x_s1_auto_in_0_b_bits_param |= x_g_auto_in_0_b_bits_param;
        x_s0_auto_in_0_b_bits_param |= ~x_g_auto_in_0_b_bits_param;
        checks++;
        if (x_g_auto_in_0_b_bits_size !== x_i_auto_in_0_b_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_size g=%h i=%h", cyc, x_g_auto_in_0_b_bits_size, x_i_auto_in_0_b_bits_size);
        end
        x_s1_auto_in_0_b_bits_size |= x_g_auto_in_0_b_bits_size;
        x_s0_auto_in_0_b_bits_size |= ~x_g_auto_in_0_b_bits_size;
        checks++;
        if (x_g_auto_in_0_b_bits_source !== x_i_auto_in_0_b_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_source g=%h i=%h", cyc, x_g_auto_in_0_b_bits_source, x_i_auto_in_0_b_bits_source);
        end
        x_s1_auto_in_0_b_bits_source |= x_g_auto_in_0_b_bits_source;
        x_s0_auto_in_0_b_bits_source |= ~x_g_auto_in_0_b_bits_source;
        checks++;
        if (x_g_auto_in_0_b_bits_address !== x_i_auto_in_0_b_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_address g=%h i=%h", cyc, x_g_auto_in_0_b_bits_address, x_i_auto_in_0_b_bits_address);
        end
        x_s1_auto_in_0_b_bits_address |= x_g_auto_in_0_b_bits_address;
        x_s0_auto_in_0_b_bits_address |= ~x_g_auto_in_0_b_bits_address;
        checks++;
        if (x_g_auto_in_0_b_bits_mask !== x_i_auto_in_0_b_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_mask g=%h i=%h", cyc, x_g_auto_in_0_b_bits_mask, x_i_auto_in_0_b_bits_mask);
        end
        x_s1_auto_in_0_b_bits_mask |= x_g_auto_in_0_b_bits_mask;
        x_s0_auto_in_0_b_bits_mask |= ~x_g_auto_in_0_b_bits_mask;
        checks++;
        if (x_g_auto_in_0_b_bits_data !== x_i_auto_in_0_b_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_data g=%h i=%h", cyc, x_g_auto_in_0_b_bits_data, x_i_auto_in_0_b_bits_data);
        end
        x_s1_auto_in_0_b_bits_data |= x_g_auto_in_0_b_bits_data;
        x_s0_auto_in_0_b_bits_data |= ~x_g_auto_in_0_b_bits_data;
        checks++;
        if (x_g_auto_in_0_b_bits_corrupt !== x_i_auto_in_0_b_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_b_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_0_b_bits_corrupt, x_i_auto_in_0_b_bits_corrupt);
        end
        x_s1_auto_in_0_b_bits_corrupt |= x_g_auto_in_0_b_bits_corrupt;
        x_s0_auto_in_0_b_bits_corrupt |= ~x_g_auto_in_0_b_bits_corrupt;
        checks++;
        if (x_g_auto_in_0_c_ready !== x_i_auto_in_0_c_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_c_ready g=%h i=%h", cyc, x_g_auto_in_0_c_ready, x_i_auto_in_0_c_ready);
        end
        x_s1_auto_in_0_c_ready |= x_g_auto_in_0_c_ready;
        x_s0_auto_in_0_c_ready |= ~x_g_auto_in_0_c_ready;
        checks++;
        if (x_g_auto_in_0_d_valid !== x_i_auto_in_0_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_valid g=%h i=%h", cyc, x_g_auto_in_0_d_valid, x_i_auto_in_0_d_valid);
        end
        x_s1_auto_in_0_d_valid |= x_g_auto_in_0_d_valid;
        x_s0_auto_in_0_d_valid |= ~x_g_auto_in_0_d_valid;
        checks++;
        if (x_g_auto_in_0_d_bits_opcode !== x_i_auto_in_0_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_opcode g=%h i=%h", cyc, x_g_auto_in_0_d_bits_opcode, x_i_auto_in_0_d_bits_opcode);
        end
        x_s1_auto_in_0_d_bits_opcode |= x_g_auto_in_0_d_bits_opcode;
        x_s0_auto_in_0_d_bits_opcode |= ~x_g_auto_in_0_d_bits_opcode;
        checks++;
        if (x_g_auto_in_0_d_bits_param !== x_i_auto_in_0_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_param g=%h i=%h", cyc, x_g_auto_in_0_d_bits_param, x_i_auto_in_0_d_bits_param);
        end
        x_s1_auto_in_0_d_bits_param |= x_g_auto_in_0_d_bits_param;
        x_s0_auto_in_0_d_bits_param |= ~x_g_auto_in_0_d_bits_param;
        checks++;
        if (x_g_auto_in_0_d_bits_size !== x_i_auto_in_0_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_size g=%h i=%h", cyc, x_g_auto_in_0_d_bits_size, x_i_auto_in_0_d_bits_size);
        end
        x_s1_auto_in_0_d_bits_size |= x_g_auto_in_0_d_bits_size;
        x_s0_auto_in_0_d_bits_size |= ~x_g_auto_in_0_d_bits_size;
        checks++;
        if (x_g_auto_in_0_d_bits_source !== x_i_auto_in_0_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_source g=%h i=%h", cyc, x_g_auto_in_0_d_bits_source, x_i_auto_in_0_d_bits_source);
        end
        x_s1_auto_in_0_d_bits_source |= x_g_auto_in_0_d_bits_source;
        x_s0_auto_in_0_d_bits_source |= ~x_g_auto_in_0_d_bits_source;
        checks++;
        if (x_g_auto_in_0_d_bits_sink !== x_i_auto_in_0_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_sink g=%h i=%h", cyc, x_g_auto_in_0_d_bits_sink, x_i_auto_in_0_d_bits_sink);
        end
        x_s1_auto_in_0_d_bits_sink |= x_g_auto_in_0_d_bits_sink;
        x_s0_auto_in_0_d_bits_sink |= ~x_g_auto_in_0_d_bits_sink;
        checks++;
        if (x_g_auto_in_0_d_bits_denied !== x_i_auto_in_0_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_denied g=%h i=%h", cyc, x_g_auto_in_0_d_bits_denied, x_i_auto_in_0_d_bits_denied);
        end
        x_s1_auto_in_0_d_bits_denied |= x_g_auto_in_0_d_bits_denied;
        x_s0_auto_in_0_d_bits_denied |= ~x_g_auto_in_0_d_bits_denied;
        checks++;
        if (x_g_auto_in_0_d_bits_echo_isKeyword !== x_i_auto_in_0_d_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_in_0_d_bits_echo_isKeyword, x_i_auto_in_0_d_bits_echo_isKeyword);
        end
        x_s1_auto_in_0_d_bits_echo_isKeyword |= x_g_auto_in_0_d_bits_echo_isKeyword;
        x_s0_auto_in_0_d_bits_echo_isKeyword |= ~x_g_auto_in_0_d_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_in_0_d_bits_data !== x_i_auto_in_0_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_data g=%h i=%h", cyc, x_g_auto_in_0_d_bits_data, x_i_auto_in_0_d_bits_data);
        end
        x_s1_auto_in_0_d_bits_data |= x_g_auto_in_0_d_bits_data;
        x_s0_auto_in_0_d_bits_data |= ~x_g_auto_in_0_d_bits_data;
        checks++;
        if (x_g_auto_in_0_d_bits_corrupt !== x_i_auto_in_0_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_d_bits_corrupt g=%h i=%h", cyc, x_g_auto_in_0_d_bits_corrupt, x_i_auto_in_0_d_bits_corrupt);
        end
        x_s1_auto_in_0_d_bits_corrupt |= x_g_auto_in_0_d_bits_corrupt;
        x_s0_auto_in_0_d_bits_corrupt |= ~x_g_auto_in_0_d_bits_corrupt;
        checks++;
        if (x_g_auto_in_0_e_ready !== x_i_auto_in_0_e_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_in_0_e_ready g=%h i=%h", cyc, x_g_auto_in_0_e_ready, x_i_auto_in_0_e_ready);
        end
        x_s1_auto_in_0_e_ready |= x_g_auto_in_0_e_ready;
        x_s0_auto_in_0_e_ready |= ~x_g_auto_in_0_e_ready;
        checks++;
        if (x_g_auto_out_3_a_valid !== x_i_auto_out_3_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_valid g=%h i=%h", cyc, x_g_auto_out_3_a_valid, x_i_auto_out_3_a_valid);
        end
        x_s1_auto_out_3_a_valid |= x_g_auto_out_3_a_valid;
        x_s0_auto_out_3_a_valid |= ~x_g_auto_out_3_a_valid;
        checks++;
        if (x_g_auto_out_3_a_bits_opcode !== x_i_auto_out_3_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_3_a_bits_opcode, x_i_auto_out_3_a_bits_opcode);
        end
        x_s1_auto_out_3_a_bits_opcode |= x_g_auto_out_3_a_bits_opcode;
        x_s0_auto_out_3_a_bits_opcode |= ~x_g_auto_out_3_a_bits_opcode;
        checks++;
        if (x_g_auto_out_3_a_bits_param !== x_i_auto_out_3_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_param g=%h i=%h", cyc, x_g_auto_out_3_a_bits_param, x_i_auto_out_3_a_bits_param);
        end
        x_s1_auto_out_3_a_bits_param |= x_g_auto_out_3_a_bits_param;
        x_s0_auto_out_3_a_bits_param |= ~x_g_auto_out_3_a_bits_param;
        checks++;
        if (x_g_auto_out_3_a_bits_size !== x_i_auto_out_3_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_size g=%h i=%h", cyc, x_g_auto_out_3_a_bits_size, x_i_auto_out_3_a_bits_size);
        end
        x_s1_auto_out_3_a_bits_size |= x_g_auto_out_3_a_bits_size;
        x_s0_auto_out_3_a_bits_size |= ~x_g_auto_out_3_a_bits_size;
        checks++;
        if (x_g_auto_out_3_a_bits_source !== x_i_auto_out_3_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_source g=%h i=%h", cyc, x_g_auto_out_3_a_bits_source, x_i_auto_out_3_a_bits_source);
        end
        x_s1_auto_out_3_a_bits_source |= x_g_auto_out_3_a_bits_source;
        x_s0_auto_out_3_a_bits_source |= ~x_g_auto_out_3_a_bits_source;
        checks++;
        if (x_g_auto_out_3_a_bits_address !== x_i_auto_out_3_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_address g=%h i=%h", cyc, x_g_auto_out_3_a_bits_address, x_i_auto_out_3_a_bits_address);
        end
        x_s1_auto_out_3_a_bits_address |= x_g_auto_out_3_a_bits_address;
        x_s0_auto_out_3_a_bits_address |= ~x_g_auto_out_3_a_bits_address;
        checks++;
        if (x_g_auto_out_3_a_bits_user_reqSource !== x_i_auto_out_3_a_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_3_a_bits_user_reqSource, x_i_auto_out_3_a_bits_user_reqSource);
        end
        x_s1_auto_out_3_a_bits_user_reqSource |= x_g_auto_out_3_a_bits_user_reqSource;
        x_s0_auto_out_3_a_bits_user_reqSource |= ~x_g_auto_out_3_a_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_3_a_bits_user_alias !== x_i_auto_out_3_a_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_3_a_bits_user_alias, x_i_auto_out_3_a_bits_user_alias);
        end
        x_s1_auto_out_3_a_bits_user_alias |= x_g_auto_out_3_a_bits_user_alias;
        x_s0_auto_out_3_a_bits_user_alias |= ~x_g_auto_out_3_a_bits_user_alias;
        checks++;
        if (x_g_auto_out_3_a_bits_user_vaddr !== x_i_auto_out_3_a_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_3_a_bits_user_vaddr, x_i_auto_out_3_a_bits_user_vaddr);
        end
        x_s1_auto_out_3_a_bits_user_vaddr |= x_g_auto_out_3_a_bits_user_vaddr;
        x_s0_auto_out_3_a_bits_user_vaddr |= ~x_g_auto_out_3_a_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_3_a_bits_user_needHint !== x_i_auto_out_3_a_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_3_a_bits_user_needHint, x_i_auto_out_3_a_bits_user_needHint);
        end
        x_s1_auto_out_3_a_bits_user_needHint |= x_g_auto_out_3_a_bits_user_needHint;
        x_s0_auto_out_3_a_bits_user_needHint |= ~x_g_auto_out_3_a_bits_user_needHint;
        checks++;
        if (x_g_auto_out_3_a_bits_echo_isKeyword !== x_i_auto_out_3_a_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_3_a_bits_echo_isKeyword, x_i_auto_out_3_a_bits_echo_isKeyword);
        end
        x_s1_auto_out_3_a_bits_echo_isKeyword |= x_g_auto_out_3_a_bits_echo_isKeyword;
        x_s0_auto_out_3_a_bits_echo_isKeyword |= ~x_g_auto_out_3_a_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_3_a_bits_mask !== x_i_auto_out_3_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_3_a_bits_mask, x_i_auto_out_3_a_bits_mask);
        end
        x_s1_auto_out_3_a_bits_mask |= x_g_auto_out_3_a_bits_mask;
        x_s0_auto_out_3_a_bits_mask |= ~x_g_auto_out_3_a_bits_mask;
        checks++;
        if (x_g_auto_out_3_a_bits_data !== x_i_auto_out_3_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_data g=%h i=%h", cyc, x_g_auto_out_3_a_bits_data, x_i_auto_out_3_a_bits_data);
        end
        x_s1_auto_out_3_a_bits_data |= x_g_auto_out_3_a_bits_data;
        x_s0_auto_out_3_a_bits_data |= ~x_g_auto_out_3_a_bits_data;
        checks++;
        if (x_g_auto_out_3_a_bits_corrupt !== x_i_auto_out_3_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_3_a_bits_corrupt, x_i_auto_out_3_a_bits_corrupt);
        end
        x_s1_auto_out_3_a_bits_corrupt |= x_g_auto_out_3_a_bits_corrupt;
        x_s0_auto_out_3_a_bits_corrupt |= ~x_g_auto_out_3_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_3_b_ready !== x_i_auto_out_3_b_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_b_ready g=%h i=%h", cyc, x_g_auto_out_3_b_ready, x_i_auto_out_3_b_ready);
        end
        x_s1_auto_out_3_b_ready |= x_g_auto_out_3_b_ready;
        x_s0_auto_out_3_b_ready |= ~x_g_auto_out_3_b_ready;
        checks++;
        if (x_g_auto_out_3_c_valid !== x_i_auto_out_3_c_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_valid g=%h i=%h", cyc, x_g_auto_out_3_c_valid, x_i_auto_out_3_c_valid);
        end
        x_s1_auto_out_3_c_valid |= x_g_auto_out_3_c_valid;
        x_s0_auto_out_3_c_valid |= ~x_g_auto_out_3_c_valid;
        checks++;
        if (x_g_auto_out_3_c_bits_opcode !== x_i_auto_out_3_c_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_opcode g=%h i=%h", cyc, x_g_auto_out_3_c_bits_opcode, x_i_auto_out_3_c_bits_opcode);
        end
        x_s1_auto_out_3_c_bits_opcode |= x_g_auto_out_3_c_bits_opcode;
        x_s0_auto_out_3_c_bits_opcode |= ~x_g_auto_out_3_c_bits_opcode;
        checks++;
        if (x_g_auto_out_3_c_bits_param !== x_i_auto_out_3_c_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_param g=%h i=%h", cyc, x_g_auto_out_3_c_bits_param, x_i_auto_out_3_c_bits_param);
        end
        x_s1_auto_out_3_c_bits_param |= x_g_auto_out_3_c_bits_param;
        x_s0_auto_out_3_c_bits_param |= ~x_g_auto_out_3_c_bits_param;
        checks++;
        if (x_g_auto_out_3_c_bits_size !== x_i_auto_out_3_c_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_size g=%h i=%h", cyc, x_g_auto_out_3_c_bits_size, x_i_auto_out_3_c_bits_size);
        end
        x_s1_auto_out_3_c_bits_size |= x_g_auto_out_3_c_bits_size;
        x_s0_auto_out_3_c_bits_size |= ~x_g_auto_out_3_c_bits_size;
        checks++;
        if (x_g_auto_out_3_c_bits_source !== x_i_auto_out_3_c_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_source g=%h i=%h", cyc, x_g_auto_out_3_c_bits_source, x_i_auto_out_3_c_bits_source);
        end
        x_s1_auto_out_3_c_bits_source |= x_g_auto_out_3_c_bits_source;
        x_s0_auto_out_3_c_bits_source |= ~x_g_auto_out_3_c_bits_source;
        checks++;
        if (x_g_auto_out_3_c_bits_address !== x_i_auto_out_3_c_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_address g=%h i=%h", cyc, x_g_auto_out_3_c_bits_address, x_i_auto_out_3_c_bits_address);
        end
        x_s1_auto_out_3_c_bits_address |= x_g_auto_out_3_c_bits_address;
        x_s0_auto_out_3_c_bits_address |= ~x_g_auto_out_3_c_bits_address;
        checks++;
        if (x_g_auto_out_3_c_bits_user_reqSource !== x_i_auto_out_3_c_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_3_c_bits_user_reqSource, x_i_auto_out_3_c_bits_user_reqSource);
        end
        x_s1_auto_out_3_c_bits_user_reqSource |= x_g_auto_out_3_c_bits_user_reqSource;
        x_s0_auto_out_3_c_bits_user_reqSource |= ~x_g_auto_out_3_c_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_3_c_bits_user_alias !== x_i_auto_out_3_c_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_3_c_bits_user_alias, x_i_auto_out_3_c_bits_user_alias);
        end
        x_s1_auto_out_3_c_bits_user_alias |= x_g_auto_out_3_c_bits_user_alias;
        x_s0_auto_out_3_c_bits_user_alias |= ~x_g_auto_out_3_c_bits_user_alias;
        checks++;
        if (x_g_auto_out_3_c_bits_user_vaddr !== x_i_auto_out_3_c_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_3_c_bits_user_vaddr, x_i_auto_out_3_c_bits_user_vaddr);
        end
        x_s1_auto_out_3_c_bits_user_vaddr |= x_g_auto_out_3_c_bits_user_vaddr;
        x_s0_auto_out_3_c_bits_user_vaddr |= ~x_g_auto_out_3_c_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_3_c_bits_user_needHint !== x_i_auto_out_3_c_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_3_c_bits_user_needHint, x_i_auto_out_3_c_bits_user_needHint);
        end
        x_s1_auto_out_3_c_bits_user_needHint |= x_g_auto_out_3_c_bits_user_needHint;
        x_s0_auto_out_3_c_bits_user_needHint |= ~x_g_auto_out_3_c_bits_user_needHint;
        checks++;
        if (x_g_auto_out_3_c_bits_echo_isKeyword !== x_i_auto_out_3_c_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_3_c_bits_echo_isKeyword, x_i_auto_out_3_c_bits_echo_isKeyword);
        end
        x_s1_auto_out_3_c_bits_echo_isKeyword |= x_g_auto_out_3_c_bits_echo_isKeyword;
        x_s0_auto_out_3_c_bits_echo_isKeyword |= ~x_g_auto_out_3_c_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_3_c_bits_data !== x_i_auto_out_3_c_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_data g=%h i=%h", cyc, x_g_auto_out_3_c_bits_data, x_i_auto_out_3_c_bits_data);
        end
        x_s1_auto_out_3_c_bits_data |= x_g_auto_out_3_c_bits_data;
        x_s0_auto_out_3_c_bits_data |= ~x_g_auto_out_3_c_bits_data;
        checks++;
        if (x_g_auto_out_3_c_bits_corrupt !== x_i_auto_out_3_c_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_c_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_3_c_bits_corrupt, x_i_auto_out_3_c_bits_corrupt);
        end
        x_s1_auto_out_3_c_bits_corrupt |= x_g_auto_out_3_c_bits_corrupt;
        x_s0_auto_out_3_c_bits_corrupt |= ~x_g_auto_out_3_c_bits_corrupt;
        checks++;
        if (x_g_auto_out_3_d_ready !== x_i_auto_out_3_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_d_ready g=%h i=%h", cyc, x_g_auto_out_3_d_ready, x_i_auto_out_3_d_ready);
        end
        x_s1_auto_out_3_d_ready |= x_g_auto_out_3_d_ready;
        x_s0_auto_out_3_d_ready |= ~x_g_auto_out_3_d_ready;
        checks++;
        if (x_g_auto_out_3_e_valid !== x_i_auto_out_3_e_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_e_valid g=%h i=%h", cyc, x_g_auto_out_3_e_valid, x_i_auto_out_3_e_valid);
        end
        x_s1_auto_out_3_e_valid |= x_g_auto_out_3_e_valid;
        x_s0_auto_out_3_e_valid |= ~x_g_auto_out_3_e_valid;
        checks++;
        if (x_g_auto_out_3_e_bits_sink !== x_i_auto_out_3_e_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_3_e_bits_sink g=%h i=%h", cyc, x_g_auto_out_3_e_bits_sink, x_i_auto_out_3_e_bits_sink);
        end
        x_s1_auto_out_3_e_bits_sink |= x_g_auto_out_3_e_bits_sink;
        x_s0_auto_out_3_e_bits_sink |= ~x_g_auto_out_3_e_bits_sink;
        checks++;
        if (x_g_auto_out_2_a_valid !== x_i_auto_out_2_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_valid g=%h i=%h", cyc, x_g_auto_out_2_a_valid, x_i_auto_out_2_a_valid);
        end
        x_s1_auto_out_2_a_valid |= x_g_auto_out_2_a_valid;
        x_s0_auto_out_2_a_valid |= ~x_g_auto_out_2_a_valid;
        checks++;
        if (x_g_auto_out_2_a_bits_opcode !== x_i_auto_out_2_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_2_a_bits_opcode, x_i_auto_out_2_a_bits_opcode);
        end
        x_s1_auto_out_2_a_bits_opcode |= x_g_auto_out_2_a_bits_opcode;
        x_s0_auto_out_2_a_bits_opcode |= ~x_g_auto_out_2_a_bits_opcode;
        checks++;
        if (x_g_auto_out_2_a_bits_param !== x_i_auto_out_2_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_param g=%h i=%h", cyc, x_g_auto_out_2_a_bits_param, x_i_auto_out_2_a_bits_param);
        end
        x_s1_auto_out_2_a_bits_param |= x_g_auto_out_2_a_bits_param;
        x_s0_auto_out_2_a_bits_param |= ~x_g_auto_out_2_a_bits_param;
        checks++;
        if (x_g_auto_out_2_a_bits_size !== x_i_auto_out_2_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_size g=%h i=%h", cyc, x_g_auto_out_2_a_bits_size, x_i_auto_out_2_a_bits_size);
        end
        x_s1_auto_out_2_a_bits_size |= x_g_auto_out_2_a_bits_size;
        x_s0_auto_out_2_a_bits_size |= ~x_g_auto_out_2_a_bits_size;
        checks++;
        if (x_g_auto_out_2_a_bits_source !== x_i_auto_out_2_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_source g=%h i=%h", cyc, x_g_auto_out_2_a_bits_source, x_i_auto_out_2_a_bits_source);
        end
        x_s1_auto_out_2_a_bits_source |= x_g_auto_out_2_a_bits_source;
        x_s0_auto_out_2_a_bits_source |= ~x_g_auto_out_2_a_bits_source;
        checks++;
        if (x_g_auto_out_2_a_bits_address !== x_i_auto_out_2_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_address g=%h i=%h", cyc, x_g_auto_out_2_a_bits_address, x_i_auto_out_2_a_bits_address);
        end
        x_s1_auto_out_2_a_bits_address |= x_g_auto_out_2_a_bits_address;
        x_s0_auto_out_2_a_bits_address |= ~x_g_auto_out_2_a_bits_address;
        checks++;
        if (x_g_auto_out_2_a_bits_user_reqSource !== x_i_auto_out_2_a_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_reqSource, x_i_auto_out_2_a_bits_user_reqSource);
        end
        x_s1_auto_out_2_a_bits_user_reqSource |= x_g_auto_out_2_a_bits_user_reqSource;
        x_s0_auto_out_2_a_bits_user_reqSource |= ~x_g_auto_out_2_a_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_2_a_bits_user_alias !== x_i_auto_out_2_a_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_alias, x_i_auto_out_2_a_bits_user_alias);
        end
        x_s1_auto_out_2_a_bits_user_alias |= x_g_auto_out_2_a_bits_user_alias;
        x_s0_auto_out_2_a_bits_user_alias |= ~x_g_auto_out_2_a_bits_user_alias;
        checks++;
        if (x_g_auto_out_2_a_bits_user_vaddr !== x_i_auto_out_2_a_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_vaddr, x_i_auto_out_2_a_bits_user_vaddr);
        end
        x_s1_auto_out_2_a_bits_user_vaddr |= x_g_auto_out_2_a_bits_user_vaddr;
        x_s0_auto_out_2_a_bits_user_vaddr |= ~x_g_auto_out_2_a_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_2_a_bits_user_needHint !== x_i_auto_out_2_a_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_2_a_bits_user_needHint, x_i_auto_out_2_a_bits_user_needHint);
        end
        x_s1_auto_out_2_a_bits_user_needHint |= x_g_auto_out_2_a_bits_user_needHint;
        x_s0_auto_out_2_a_bits_user_needHint |= ~x_g_auto_out_2_a_bits_user_needHint;
        checks++;
        if (x_g_auto_out_2_a_bits_echo_isKeyword !== x_i_auto_out_2_a_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_2_a_bits_echo_isKeyword, x_i_auto_out_2_a_bits_echo_isKeyword);
        end
        x_s1_auto_out_2_a_bits_echo_isKeyword |= x_g_auto_out_2_a_bits_echo_isKeyword;
        x_s0_auto_out_2_a_bits_echo_isKeyword |= ~x_g_auto_out_2_a_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_2_a_bits_mask !== x_i_auto_out_2_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_2_a_bits_mask, x_i_auto_out_2_a_bits_mask);
        end
        x_s1_auto_out_2_a_bits_mask |= x_g_auto_out_2_a_bits_mask;
        x_s0_auto_out_2_a_bits_mask |= ~x_g_auto_out_2_a_bits_mask;
        checks++;
        if (x_g_auto_out_2_a_bits_data !== x_i_auto_out_2_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_data g=%h i=%h", cyc, x_g_auto_out_2_a_bits_data, x_i_auto_out_2_a_bits_data);
        end
        x_s1_auto_out_2_a_bits_data |= x_g_auto_out_2_a_bits_data;
        x_s0_auto_out_2_a_bits_data |= ~x_g_auto_out_2_a_bits_data;
        checks++;
        if (x_g_auto_out_2_a_bits_corrupt !== x_i_auto_out_2_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_2_a_bits_corrupt, x_i_auto_out_2_a_bits_corrupt);
        end
        x_s1_auto_out_2_a_bits_corrupt |= x_g_auto_out_2_a_bits_corrupt;
        x_s0_auto_out_2_a_bits_corrupt |= ~x_g_auto_out_2_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_2_b_ready !== x_i_auto_out_2_b_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_b_ready g=%h i=%h", cyc, x_g_auto_out_2_b_ready, x_i_auto_out_2_b_ready);
        end
        x_s1_auto_out_2_b_ready |= x_g_auto_out_2_b_ready;
        x_s0_auto_out_2_b_ready |= ~x_g_auto_out_2_b_ready;
        checks++;
        if (x_g_auto_out_2_c_valid !== x_i_auto_out_2_c_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_valid g=%h i=%h", cyc, x_g_auto_out_2_c_valid, x_i_auto_out_2_c_valid);
        end
        x_s1_auto_out_2_c_valid |= x_g_auto_out_2_c_valid;
        x_s0_auto_out_2_c_valid |= ~x_g_auto_out_2_c_valid;
        checks++;
        if (x_g_auto_out_2_c_bits_opcode !== x_i_auto_out_2_c_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_opcode g=%h i=%h", cyc, x_g_auto_out_2_c_bits_opcode, x_i_auto_out_2_c_bits_opcode);
        end
        x_s1_auto_out_2_c_bits_opcode |= x_g_auto_out_2_c_bits_opcode;
        x_s0_auto_out_2_c_bits_opcode |= ~x_g_auto_out_2_c_bits_opcode;
        checks++;
        if (x_g_auto_out_2_c_bits_param !== x_i_auto_out_2_c_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_param g=%h i=%h", cyc, x_g_auto_out_2_c_bits_param, x_i_auto_out_2_c_bits_param);
        end
        x_s1_auto_out_2_c_bits_param |= x_g_auto_out_2_c_bits_param;
        x_s0_auto_out_2_c_bits_param |= ~x_g_auto_out_2_c_bits_param;
        checks++;
        if (x_g_auto_out_2_c_bits_size !== x_i_auto_out_2_c_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_size g=%h i=%h", cyc, x_g_auto_out_2_c_bits_size, x_i_auto_out_2_c_bits_size);
        end
        x_s1_auto_out_2_c_bits_size |= x_g_auto_out_2_c_bits_size;
        x_s0_auto_out_2_c_bits_size |= ~x_g_auto_out_2_c_bits_size;
        checks++;
        if (x_g_auto_out_2_c_bits_source !== x_i_auto_out_2_c_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_source g=%h i=%h", cyc, x_g_auto_out_2_c_bits_source, x_i_auto_out_2_c_bits_source);
        end
        x_s1_auto_out_2_c_bits_source |= x_g_auto_out_2_c_bits_source;
        x_s0_auto_out_2_c_bits_source |= ~x_g_auto_out_2_c_bits_source;
        checks++;
        if (x_g_auto_out_2_c_bits_address !== x_i_auto_out_2_c_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_address g=%h i=%h", cyc, x_g_auto_out_2_c_bits_address, x_i_auto_out_2_c_bits_address);
        end
        x_s1_auto_out_2_c_bits_address |= x_g_auto_out_2_c_bits_address;
        x_s0_auto_out_2_c_bits_address |= ~x_g_auto_out_2_c_bits_address;
        checks++;
        if (x_g_auto_out_2_c_bits_user_reqSource !== x_i_auto_out_2_c_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_2_c_bits_user_reqSource, x_i_auto_out_2_c_bits_user_reqSource);
        end
        x_s1_auto_out_2_c_bits_user_reqSource |= x_g_auto_out_2_c_bits_user_reqSource;
        x_s0_auto_out_2_c_bits_user_reqSource |= ~x_g_auto_out_2_c_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_2_c_bits_user_alias !== x_i_auto_out_2_c_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_2_c_bits_user_alias, x_i_auto_out_2_c_bits_user_alias);
        end
        x_s1_auto_out_2_c_bits_user_alias |= x_g_auto_out_2_c_bits_user_alias;
        x_s0_auto_out_2_c_bits_user_alias |= ~x_g_auto_out_2_c_bits_user_alias;
        checks++;
        if (x_g_auto_out_2_c_bits_user_vaddr !== x_i_auto_out_2_c_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_2_c_bits_user_vaddr, x_i_auto_out_2_c_bits_user_vaddr);
        end
        x_s1_auto_out_2_c_bits_user_vaddr |= x_g_auto_out_2_c_bits_user_vaddr;
        x_s0_auto_out_2_c_bits_user_vaddr |= ~x_g_auto_out_2_c_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_2_c_bits_user_needHint !== x_i_auto_out_2_c_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_2_c_bits_user_needHint, x_i_auto_out_2_c_bits_user_needHint);
        end
        x_s1_auto_out_2_c_bits_user_needHint |= x_g_auto_out_2_c_bits_user_needHint;
        x_s0_auto_out_2_c_bits_user_needHint |= ~x_g_auto_out_2_c_bits_user_needHint;
        checks++;
        if (x_g_auto_out_2_c_bits_echo_isKeyword !== x_i_auto_out_2_c_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_2_c_bits_echo_isKeyword, x_i_auto_out_2_c_bits_echo_isKeyword);
        end
        x_s1_auto_out_2_c_bits_echo_isKeyword |= x_g_auto_out_2_c_bits_echo_isKeyword;
        x_s0_auto_out_2_c_bits_echo_isKeyword |= ~x_g_auto_out_2_c_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_2_c_bits_data !== x_i_auto_out_2_c_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_data g=%h i=%h", cyc, x_g_auto_out_2_c_bits_data, x_i_auto_out_2_c_bits_data);
        end
        x_s1_auto_out_2_c_bits_data |= x_g_auto_out_2_c_bits_data;
        x_s0_auto_out_2_c_bits_data |= ~x_g_auto_out_2_c_bits_data;
        checks++;
        if (x_g_auto_out_2_c_bits_corrupt !== x_i_auto_out_2_c_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_c_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_2_c_bits_corrupt, x_i_auto_out_2_c_bits_corrupt);
        end
        x_s1_auto_out_2_c_bits_corrupt |= x_g_auto_out_2_c_bits_corrupt;
        x_s0_auto_out_2_c_bits_corrupt |= ~x_g_auto_out_2_c_bits_corrupt;
        checks++;
        if (x_g_auto_out_2_d_ready !== x_i_auto_out_2_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_d_ready g=%h i=%h", cyc, x_g_auto_out_2_d_ready, x_i_auto_out_2_d_ready);
        end
        x_s1_auto_out_2_d_ready |= x_g_auto_out_2_d_ready;
        x_s0_auto_out_2_d_ready |= ~x_g_auto_out_2_d_ready;
        checks++;
        if (x_g_auto_out_2_e_valid !== x_i_auto_out_2_e_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_e_valid g=%h i=%h", cyc, x_g_auto_out_2_e_valid, x_i_auto_out_2_e_valid);
        end
        x_s1_auto_out_2_e_valid |= x_g_auto_out_2_e_valid;
        x_s0_auto_out_2_e_valid |= ~x_g_auto_out_2_e_valid;
        checks++;
        if (x_g_auto_out_2_e_bits_sink !== x_i_auto_out_2_e_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_2_e_bits_sink g=%h i=%h", cyc, x_g_auto_out_2_e_bits_sink, x_i_auto_out_2_e_bits_sink);
        end
        x_s1_auto_out_2_e_bits_sink |= x_g_auto_out_2_e_bits_sink;
        x_s0_auto_out_2_e_bits_sink |= ~x_g_auto_out_2_e_bits_sink;
        checks++;
        if (x_g_auto_out_1_a_valid !== x_i_auto_out_1_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_valid g=%h i=%h", cyc, x_g_auto_out_1_a_valid, x_i_auto_out_1_a_valid);
        end
        x_s1_auto_out_1_a_valid |= x_g_auto_out_1_a_valid;
        x_s0_auto_out_1_a_valid |= ~x_g_auto_out_1_a_valid;
        checks++;
        if (x_g_auto_out_1_a_bits_opcode !== x_i_auto_out_1_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_1_a_bits_opcode, x_i_auto_out_1_a_bits_opcode);
        end
        x_s1_auto_out_1_a_bits_opcode |= x_g_auto_out_1_a_bits_opcode;
        x_s0_auto_out_1_a_bits_opcode |= ~x_g_auto_out_1_a_bits_opcode;
        checks++;
        if (x_g_auto_out_1_a_bits_param !== x_i_auto_out_1_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_param g=%h i=%h", cyc, x_g_auto_out_1_a_bits_param, x_i_auto_out_1_a_bits_param);
        end
        x_s1_auto_out_1_a_bits_param |= x_g_auto_out_1_a_bits_param;
        x_s0_auto_out_1_a_bits_param |= ~x_g_auto_out_1_a_bits_param;
        checks++;
        if (x_g_auto_out_1_a_bits_size !== x_i_auto_out_1_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_size g=%h i=%h", cyc, x_g_auto_out_1_a_bits_size, x_i_auto_out_1_a_bits_size);
        end
        x_s1_auto_out_1_a_bits_size |= x_g_auto_out_1_a_bits_size;
        x_s0_auto_out_1_a_bits_size |= ~x_g_auto_out_1_a_bits_size;
        checks++;
        if (x_g_auto_out_1_a_bits_source !== x_i_auto_out_1_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_source g=%h i=%h", cyc, x_g_auto_out_1_a_bits_source, x_i_auto_out_1_a_bits_source);
        end
        x_s1_auto_out_1_a_bits_source |= x_g_auto_out_1_a_bits_source;
        x_s0_auto_out_1_a_bits_source |= ~x_g_auto_out_1_a_bits_source;
        checks++;
        if (x_g_auto_out_1_a_bits_address !== x_i_auto_out_1_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_address g=%h i=%h", cyc, x_g_auto_out_1_a_bits_address, x_i_auto_out_1_a_bits_address);
        end
        x_s1_auto_out_1_a_bits_address |= x_g_auto_out_1_a_bits_address;
        x_s0_auto_out_1_a_bits_address |= ~x_g_auto_out_1_a_bits_address;
        checks++;
        if (x_g_auto_out_1_a_bits_user_reqSource !== x_i_auto_out_1_a_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_1_a_bits_user_reqSource, x_i_auto_out_1_a_bits_user_reqSource);
        end
        x_s1_auto_out_1_a_bits_user_reqSource |= x_g_auto_out_1_a_bits_user_reqSource;
        x_s0_auto_out_1_a_bits_user_reqSource |= ~x_g_auto_out_1_a_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_1_a_bits_user_alias !== x_i_auto_out_1_a_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_1_a_bits_user_alias, x_i_auto_out_1_a_bits_user_alias);
        end
        x_s1_auto_out_1_a_bits_user_alias |= x_g_auto_out_1_a_bits_user_alias;
        x_s0_auto_out_1_a_bits_user_alias |= ~x_g_auto_out_1_a_bits_user_alias;
        checks++;
        if (x_g_auto_out_1_a_bits_user_vaddr !== x_i_auto_out_1_a_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_1_a_bits_user_vaddr, x_i_auto_out_1_a_bits_user_vaddr);
        end
        x_s1_auto_out_1_a_bits_user_vaddr |= x_g_auto_out_1_a_bits_user_vaddr;
        x_s0_auto_out_1_a_bits_user_vaddr |= ~x_g_auto_out_1_a_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_1_a_bits_user_needHint !== x_i_auto_out_1_a_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_1_a_bits_user_needHint, x_i_auto_out_1_a_bits_user_needHint);
        end
        x_s1_auto_out_1_a_bits_user_needHint |= x_g_auto_out_1_a_bits_user_needHint;
        x_s0_auto_out_1_a_bits_user_needHint |= ~x_g_auto_out_1_a_bits_user_needHint;
        checks++;
        if (x_g_auto_out_1_a_bits_echo_isKeyword !== x_i_auto_out_1_a_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_1_a_bits_echo_isKeyword, x_i_auto_out_1_a_bits_echo_isKeyword);
        end
        x_s1_auto_out_1_a_bits_echo_isKeyword |= x_g_auto_out_1_a_bits_echo_isKeyword;
        x_s0_auto_out_1_a_bits_echo_isKeyword |= ~x_g_auto_out_1_a_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_1_a_bits_mask !== x_i_auto_out_1_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_1_a_bits_mask, x_i_auto_out_1_a_bits_mask);
        end
        x_s1_auto_out_1_a_bits_mask |= x_g_auto_out_1_a_bits_mask;
        x_s0_auto_out_1_a_bits_mask |= ~x_g_auto_out_1_a_bits_mask;
        checks++;
        if (x_g_auto_out_1_a_bits_data !== x_i_auto_out_1_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_data g=%h i=%h", cyc, x_g_auto_out_1_a_bits_data, x_i_auto_out_1_a_bits_data);
        end
        x_s1_auto_out_1_a_bits_data |= x_g_auto_out_1_a_bits_data;
        x_s0_auto_out_1_a_bits_data |= ~x_g_auto_out_1_a_bits_data;
        checks++;
        if (x_g_auto_out_1_a_bits_corrupt !== x_i_auto_out_1_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_1_a_bits_corrupt, x_i_auto_out_1_a_bits_corrupt);
        end
        x_s1_auto_out_1_a_bits_corrupt |= x_g_auto_out_1_a_bits_corrupt;
        x_s0_auto_out_1_a_bits_corrupt |= ~x_g_auto_out_1_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_1_b_ready !== x_i_auto_out_1_b_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_b_ready g=%h i=%h", cyc, x_g_auto_out_1_b_ready, x_i_auto_out_1_b_ready);
        end
        x_s1_auto_out_1_b_ready |= x_g_auto_out_1_b_ready;
        x_s0_auto_out_1_b_ready |= ~x_g_auto_out_1_b_ready;
        checks++;
        if (x_g_auto_out_1_c_valid !== x_i_auto_out_1_c_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_valid g=%h i=%h", cyc, x_g_auto_out_1_c_valid, x_i_auto_out_1_c_valid);
        end
        x_s1_auto_out_1_c_valid |= x_g_auto_out_1_c_valid;
        x_s0_auto_out_1_c_valid |= ~x_g_auto_out_1_c_valid;
        checks++;
        if (x_g_auto_out_1_c_bits_opcode !== x_i_auto_out_1_c_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_opcode g=%h i=%h", cyc, x_g_auto_out_1_c_bits_opcode, x_i_auto_out_1_c_bits_opcode);
        end
        x_s1_auto_out_1_c_bits_opcode |= x_g_auto_out_1_c_bits_opcode;
        x_s0_auto_out_1_c_bits_opcode |= ~x_g_auto_out_1_c_bits_opcode;
        checks++;
        if (x_g_auto_out_1_c_bits_param !== x_i_auto_out_1_c_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_param g=%h i=%h", cyc, x_g_auto_out_1_c_bits_param, x_i_auto_out_1_c_bits_param);
        end
        x_s1_auto_out_1_c_bits_param |= x_g_auto_out_1_c_bits_param;
        x_s0_auto_out_1_c_bits_param |= ~x_g_auto_out_1_c_bits_param;
        checks++;
        if (x_g_auto_out_1_c_bits_size !== x_i_auto_out_1_c_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_size g=%h i=%h", cyc, x_g_auto_out_1_c_bits_size, x_i_auto_out_1_c_bits_size);
        end
        x_s1_auto_out_1_c_bits_size |= x_g_auto_out_1_c_bits_size;
        x_s0_auto_out_1_c_bits_size |= ~x_g_auto_out_1_c_bits_size;
        checks++;
        if (x_g_auto_out_1_c_bits_source !== x_i_auto_out_1_c_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_source g=%h i=%h", cyc, x_g_auto_out_1_c_bits_source, x_i_auto_out_1_c_bits_source);
        end
        x_s1_auto_out_1_c_bits_source |= x_g_auto_out_1_c_bits_source;
        x_s0_auto_out_1_c_bits_source |= ~x_g_auto_out_1_c_bits_source;
        checks++;
        if (x_g_auto_out_1_c_bits_address !== x_i_auto_out_1_c_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_address g=%h i=%h", cyc, x_g_auto_out_1_c_bits_address, x_i_auto_out_1_c_bits_address);
        end
        x_s1_auto_out_1_c_bits_address |= x_g_auto_out_1_c_bits_address;
        x_s0_auto_out_1_c_bits_address |= ~x_g_auto_out_1_c_bits_address;
        checks++;
        if (x_g_auto_out_1_c_bits_user_reqSource !== x_i_auto_out_1_c_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_1_c_bits_user_reqSource, x_i_auto_out_1_c_bits_user_reqSource);
        end
        x_s1_auto_out_1_c_bits_user_reqSource |= x_g_auto_out_1_c_bits_user_reqSource;
        x_s0_auto_out_1_c_bits_user_reqSource |= ~x_g_auto_out_1_c_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_1_c_bits_user_alias !== x_i_auto_out_1_c_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_1_c_bits_user_alias, x_i_auto_out_1_c_bits_user_alias);
        end
        x_s1_auto_out_1_c_bits_user_alias |= x_g_auto_out_1_c_bits_user_alias;
        x_s0_auto_out_1_c_bits_user_alias |= ~x_g_auto_out_1_c_bits_user_alias;
        checks++;
        if (x_g_auto_out_1_c_bits_user_vaddr !== x_i_auto_out_1_c_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_1_c_bits_user_vaddr, x_i_auto_out_1_c_bits_user_vaddr);
        end
        x_s1_auto_out_1_c_bits_user_vaddr |= x_g_auto_out_1_c_bits_user_vaddr;
        x_s0_auto_out_1_c_bits_user_vaddr |= ~x_g_auto_out_1_c_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_1_c_bits_user_needHint !== x_i_auto_out_1_c_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_1_c_bits_user_needHint, x_i_auto_out_1_c_bits_user_needHint);
        end
        x_s1_auto_out_1_c_bits_user_needHint |= x_g_auto_out_1_c_bits_user_needHint;
        x_s0_auto_out_1_c_bits_user_needHint |= ~x_g_auto_out_1_c_bits_user_needHint;
        checks++;
        if (x_g_auto_out_1_c_bits_echo_isKeyword !== x_i_auto_out_1_c_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_1_c_bits_echo_isKeyword, x_i_auto_out_1_c_bits_echo_isKeyword);
        end
        x_s1_auto_out_1_c_bits_echo_isKeyword |= x_g_auto_out_1_c_bits_echo_isKeyword;
        x_s0_auto_out_1_c_bits_echo_isKeyword |= ~x_g_auto_out_1_c_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_1_c_bits_data !== x_i_auto_out_1_c_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_data g=%h i=%h", cyc, x_g_auto_out_1_c_bits_data, x_i_auto_out_1_c_bits_data);
        end
        x_s1_auto_out_1_c_bits_data |= x_g_auto_out_1_c_bits_data;
        x_s0_auto_out_1_c_bits_data |= ~x_g_auto_out_1_c_bits_data;
        checks++;
        if (x_g_auto_out_1_c_bits_corrupt !== x_i_auto_out_1_c_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_c_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_1_c_bits_corrupt, x_i_auto_out_1_c_bits_corrupt);
        end
        x_s1_auto_out_1_c_bits_corrupt |= x_g_auto_out_1_c_bits_corrupt;
        x_s0_auto_out_1_c_bits_corrupt |= ~x_g_auto_out_1_c_bits_corrupt;
        checks++;
        if (x_g_auto_out_1_d_ready !== x_i_auto_out_1_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_d_ready g=%h i=%h", cyc, x_g_auto_out_1_d_ready, x_i_auto_out_1_d_ready);
        end
        x_s1_auto_out_1_d_ready |= x_g_auto_out_1_d_ready;
        x_s0_auto_out_1_d_ready |= ~x_g_auto_out_1_d_ready;
        checks++;
        if (x_g_auto_out_1_e_valid !== x_i_auto_out_1_e_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_e_valid g=%h i=%h", cyc, x_g_auto_out_1_e_valid, x_i_auto_out_1_e_valid);
        end
        x_s1_auto_out_1_e_valid |= x_g_auto_out_1_e_valid;
        x_s0_auto_out_1_e_valid |= ~x_g_auto_out_1_e_valid;
        checks++;
        if (x_g_auto_out_1_e_bits_sink !== x_i_auto_out_1_e_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_1_e_bits_sink g=%h i=%h", cyc, x_g_auto_out_1_e_bits_sink, x_i_auto_out_1_e_bits_sink);
        end
        x_s1_auto_out_1_e_bits_sink |= x_g_auto_out_1_e_bits_sink;
        x_s0_auto_out_1_e_bits_sink |= ~x_g_auto_out_1_e_bits_sink;
        checks++;
        if (x_g_auto_out_0_a_valid !== x_i_auto_out_0_a_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_valid g=%h i=%h", cyc, x_g_auto_out_0_a_valid, x_i_auto_out_0_a_valid);
        end
        x_s1_auto_out_0_a_valid |= x_g_auto_out_0_a_valid;
        x_s0_auto_out_0_a_valid |= ~x_g_auto_out_0_a_valid;
        checks++;
        if (x_g_auto_out_0_a_bits_opcode !== x_i_auto_out_0_a_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_opcode g=%h i=%h", cyc, x_g_auto_out_0_a_bits_opcode, x_i_auto_out_0_a_bits_opcode);
        end
        x_s1_auto_out_0_a_bits_opcode |= x_g_auto_out_0_a_bits_opcode;
        x_s0_auto_out_0_a_bits_opcode |= ~x_g_auto_out_0_a_bits_opcode;
        checks++;
        if (x_g_auto_out_0_a_bits_param !== x_i_auto_out_0_a_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_param g=%h i=%h", cyc, x_g_auto_out_0_a_bits_param, x_i_auto_out_0_a_bits_param);
        end
        x_s1_auto_out_0_a_bits_param |= x_g_auto_out_0_a_bits_param;
        x_s0_auto_out_0_a_bits_param |= ~x_g_auto_out_0_a_bits_param;
        checks++;
        if (x_g_auto_out_0_a_bits_size !== x_i_auto_out_0_a_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_size g=%h i=%h", cyc, x_g_auto_out_0_a_bits_size, x_i_auto_out_0_a_bits_size);
        end
        x_s1_auto_out_0_a_bits_size |= x_g_auto_out_0_a_bits_size;
        x_s0_auto_out_0_a_bits_size |= ~x_g_auto_out_0_a_bits_size;
        checks++;
        if (x_g_auto_out_0_a_bits_source !== x_i_auto_out_0_a_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_source g=%h i=%h", cyc, x_g_auto_out_0_a_bits_source, x_i_auto_out_0_a_bits_source);
        end
        x_s1_auto_out_0_a_bits_source |= x_g_auto_out_0_a_bits_source;
        x_s0_auto_out_0_a_bits_source |= ~x_g_auto_out_0_a_bits_source;
        checks++;
        if (x_g_auto_out_0_a_bits_address !== x_i_auto_out_0_a_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_address g=%h i=%h", cyc, x_g_auto_out_0_a_bits_address, x_i_auto_out_0_a_bits_address);
        end
        x_s1_auto_out_0_a_bits_address |= x_g_auto_out_0_a_bits_address;
        x_s0_auto_out_0_a_bits_address |= ~x_g_auto_out_0_a_bits_address;
        checks++;
        if (x_g_auto_out_0_a_bits_user_reqSource !== x_i_auto_out_0_a_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_0_a_bits_user_reqSource, x_i_auto_out_0_a_bits_user_reqSource);
        end
        x_s1_auto_out_0_a_bits_user_reqSource |= x_g_auto_out_0_a_bits_user_reqSource;
        x_s0_auto_out_0_a_bits_user_reqSource |= ~x_g_auto_out_0_a_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_0_a_bits_user_alias !== x_i_auto_out_0_a_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_0_a_bits_user_alias, x_i_auto_out_0_a_bits_user_alias);
        end
        x_s1_auto_out_0_a_bits_user_alias |= x_g_auto_out_0_a_bits_user_alias;
        x_s0_auto_out_0_a_bits_user_alias |= ~x_g_auto_out_0_a_bits_user_alias;
        checks++;
        if (x_g_auto_out_0_a_bits_user_vaddr !== x_i_auto_out_0_a_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_0_a_bits_user_vaddr, x_i_auto_out_0_a_bits_user_vaddr);
        end
        x_s1_auto_out_0_a_bits_user_vaddr |= x_g_auto_out_0_a_bits_user_vaddr;
        x_s0_auto_out_0_a_bits_user_vaddr |= ~x_g_auto_out_0_a_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_0_a_bits_user_needHint !== x_i_auto_out_0_a_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_0_a_bits_user_needHint, x_i_auto_out_0_a_bits_user_needHint);
        end
        x_s1_auto_out_0_a_bits_user_needHint |= x_g_auto_out_0_a_bits_user_needHint;
        x_s0_auto_out_0_a_bits_user_needHint |= ~x_g_auto_out_0_a_bits_user_needHint;
        checks++;
        if (x_g_auto_out_0_a_bits_echo_isKeyword !== x_i_auto_out_0_a_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_0_a_bits_echo_isKeyword, x_i_auto_out_0_a_bits_echo_isKeyword);
        end
        x_s1_auto_out_0_a_bits_echo_isKeyword |= x_g_auto_out_0_a_bits_echo_isKeyword;
        x_s0_auto_out_0_a_bits_echo_isKeyword |= ~x_g_auto_out_0_a_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_0_a_bits_mask !== x_i_auto_out_0_a_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_mask g=%h i=%h", cyc, x_g_auto_out_0_a_bits_mask, x_i_auto_out_0_a_bits_mask);
        end
        x_s1_auto_out_0_a_bits_mask |= x_g_auto_out_0_a_bits_mask;
        x_s0_auto_out_0_a_bits_mask |= ~x_g_auto_out_0_a_bits_mask;
        checks++;
        if (x_g_auto_out_0_a_bits_data !== x_i_auto_out_0_a_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_data g=%h i=%h", cyc, x_g_auto_out_0_a_bits_data, x_i_auto_out_0_a_bits_data);
        end
        x_s1_auto_out_0_a_bits_data |= x_g_auto_out_0_a_bits_data;
        x_s0_auto_out_0_a_bits_data |= ~x_g_auto_out_0_a_bits_data;
        checks++;
        if (x_g_auto_out_0_a_bits_corrupt !== x_i_auto_out_0_a_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_a_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_0_a_bits_corrupt, x_i_auto_out_0_a_bits_corrupt);
        end
        x_s1_auto_out_0_a_bits_corrupt |= x_g_auto_out_0_a_bits_corrupt;
        x_s0_auto_out_0_a_bits_corrupt |= ~x_g_auto_out_0_a_bits_corrupt;
        checks++;
        if (x_g_auto_out_0_b_ready !== x_i_auto_out_0_b_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_b_ready g=%h i=%h", cyc, x_g_auto_out_0_b_ready, x_i_auto_out_0_b_ready);
        end
        x_s1_auto_out_0_b_ready |= x_g_auto_out_0_b_ready;
        x_s0_auto_out_0_b_ready |= ~x_g_auto_out_0_b_ready;
        checks++;
        if (x_g_auto_out_0_c_valid !== x_i_auto_out_0_c_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_valid g=%h i=%h", cyc, x_g_auto_out_0_c_valid, x_i_auto_out_0_c_valid);
        end
        x_s1_auto_out_0_c_valid |= x_g_auto_out_0_c_valid;
        x_s0_auto_out_0_c_valid |= ~x_g_auto_out_0_c_valid;
        checks++;
        if (x_g_auto_out_0_c_bits_opcode !== x_i_auto_out_0_c_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_opcode g=%h i=%h", cyc, x_g_auto_out_0_c_bits_opcode, x_i_auto_out_0_c_bits_opcode);
        end
        x_s1_auto_out_0_c_bits_opcode |= x_g_auto_out_0_c_bits_opcode;
        x_s0_auto_out_0_c_bits_opcode |= ~x_g_auto_out_0_c_bits_opcode;
        checks++;
        if (x_g_auto_out_0_c_bits_param !== x_i_auto_out_0_c_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_param g=%h i=%h", cyc, x_g_auto_out_0_c_bits_param, x_i_auto_out_0_c_bits_param);
        end
        x_s1_auto_out_0_c_bits_param |= x_g_auto_out_0_c_bits_param;
        x_s0_auto_out_0_c_bits_param |= ~x_g_auto_out_0_c_bits_param;
        checks++;
        if (x_g_auto_out_0_c_bits_size !== x_i_auto_out_0_c_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_size g=%h i=%h", cyc, x_g_auto_out_0_c_bits_size, x_i_auto_out_0_c_bits_size);
        end
        x_s1_auto_out_0_c_bits_size |= x_g_auto_out_0_c_bits_size;
        x_s0_auto_out_0_c_bits_size |= ~x_g_auto_out_0_c_bits_size;
        checks++;
        if (x_g_auto_out_0_c_bits_source !== x_i_auto_out_0_c_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_source g=%h i=%h", cyc, x_g_auto_out_0_c_bits_source, x_i_auto_out_0_c_bits_source);
        end
        x_s1_auto_out_0_c_bits_source |= x_g_auto_out_0_c_bits_source;
        x_s0_auto_out_0_c_bits_source |= ~x_g_auto_out_0_c_bits_source;
        checks++;
        if (x_g_auto_out_0_c_bits_address !== x_i_auto_out_0_c_bits_address) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_address g=%h i=%h", cyc, x_g_auto_out_0_c_bits_address, x_i_auto_out_0_c_bits_address);
        end
        x_s1_auto_out_0_c_bits_address |= x_g_auto_out_0_c_bits_address;
        x_s0_auto_out_0_c_bits_address |= ~x_g_auto_out_0_c_bits_address;
        checks++;
        if (x_g_auto_out_0_c_bits_user_reqSource !== x_i_auto_out_0_c_bits_user_reqSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_user_reqSource g=%h i=%h", cyc, x_g_auto_out_0_c_bits_user_reqSource, x_i_auto_out_0_c_bits_user_reqSource);
        end
        x_s1_auto_out_0_c_bits_user_reqSource |= x_g_auto_out_0_c_bits_user_reqSource;
        x_s0_auto_out_0_c_bits_user_reqSource |= ~x_g_auto_out_0_c_bits_user_reqSource;
        checks++;
        if (x_g_auto_out_0_c_bits_user_alias !== x_i_auto_out_0_c_bits_user_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_user_alias g=%h i=%h", cyc, x_g_auto_out_0_c_bits_user_alias, x_i_auto_out_0_c_bits_user_alias);
        end
        x_s1_auto_out_0_c_bits_user_alias |= x_g_auto_out_0_c_bits_user_alias;
        x_s0_auto_out_0_c_bits_user_alias |= ~x_g_auto_out_0_c_bits_user_alias;
        checks++;
        if (x_g_auto_out_0_c_bits_user_vaddr !== x_i_auto_out_0_c_bits_user_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_user_vaddr g=%h i=%h", cyc, x_g_auto_out_0_c_bits_user_vaddr, x_i_auto_out_0_c_bits_user_vaddr);
        end
        x_s1_auto_out_0_c_bits_user_vaddr |= x_g_auto_out_0_c_bits_user_vaddr;
        x_s0_auto_out_0_c_bits_user_vaddr |= ~x_g_auto_out_0_c_bits_user_vaddr;
        checks++;
        if (x_g_auto_out_0_c_bits_user_needHint !== x_i_auto_out_0_c_bits_user_needHint) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_user_needHint g=%h i=%h", cyc, x_g_auto_out_0_c_bits_user_needHint, x_i_auto_out_0_c_bits_user_needHint);
        end
        x_s1_auto_out_0_c_bits_user_needHint |= x_g_auto_out_0_c_bits_user_needHint;
        x_s0_auto_out_0_c_bits_user_needHint |= ~x_g_auto_out_0_c_bits_user_needHint;
        checks++;
        if (x_g_auto_out_0_c_bits_echo_isKeyword !== x_i_auto_out_0_c_bits_echo_isKeyword) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_echo_isKeyword g=%h i=%h", cyc, x_g_auto_out_0_c_bits_echo_isKeyword, x_i_auto_out_0_c_bits_echo_isKeyword);
        end
        x_s1_auto_out_0_c_bits_echo_isKeyword |= x_g_auto_out_0_c_bits_echo_isKeyword;
        x_s0_auto_out_0_c_bits_echo_isKeyword |= ~x_g_auto_out_0_c_bits_echo_isKeyword;
        checks++;
        if (x_g_auto_out_0_c_bits_data !== x_i_auto_out_0_c_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_data g=%h i=%h", cyc, x_g_auto_out_0_c_bits_data, x_i_auto_out_0_c_bits_data);
        end
        x_s1_auto_out_0_c_bits_data |= x_g_auto_out_0_c_bits_data;
        x_s0_auto_out_0_c_bits_data |= ~x_g_auto_out_0_c_bits_data;
        checks++;
        if (x_g_auto_out_0_c_bits_corrupt !== x_i_auto_out_0_c_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_c_bits_corrupt g=%h i=%h", cyc, x_g_auto_out_0_c_bits_corrupt, x_i_auto_out_0_c_bits_corrupt);
        end
        x_s1_auto_out_0_c_bits_corrupt |= x_g_auto_out_0_c_bits_corrupt;
        x_s0_auto_out_0_c_bits_corrupt |= ~x_g_auto_out_0_c_bits_corrupt;
        checks++;
        if (x_g_auto_out_0_d_ready !== x_i_auto_out_0_d_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_d_ready g=%h i=%h", cyc, x_g_auto_out_0_d_ready, x_i_auto_out_0_d_ready);
        end
        x_s1_auto_out_0_d_ready |= x_g_auto_out_0_d_ready;
        x_s0_auto_out_0_d_ready |= ~x_g_auto_out_0_d_ready;
        checks++;
        if (x_g_auto_out_0_e_valid !== x_i_auto_out_0_e_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_e_valid g=%h i=%h", cyc, x_g_auto_out_0_e_valid, x_i_auto_out_0_e_valid);
        end
        x_s1_auto_out_0_e_valid |= x_g_auto_out_0_e_valid;
        x_s0_auto_out_0_e_valid |= ~x_g_auto_out_0_e_valid;
        checks++;
        if (x_g_auto_out_0_e_bits_sink !== x_i_auto_out_0_e_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TLXbar_5.auto_out_0_e_bits_sink g=%h i=%h", cyc, x_g_auto_out_0_e_bits_sink, x_i_auto_out_0_e_bits_sink);
        end
        x_s1_auto_out_0_e_bits_sink |= x_g_auto_out_0_e_bits_sink;
        x_s0_auto_out_0_e_bits_sink |= ~x_g_auto_out_0_e_bits_sink;
        if (x_u_gold.beatsLeft || x_u_gold.beatsLeft_1 || x_u_gold.beatsLeft_2 || x_u_gold.beatsLeft_3) x_cov_a_lock++;
        if (x_u_gold.beatsLeft_5 || x_u_gold.beatsLeft_6 || x_u_gold.beatsLeft_7) x_cov_d_lock++;
        if (x_g_auto_out_0_a_valid && x_auto_out_0_a_ready) x_cov_a0_fire++;
        if (x_g_auto_out_3_a_valid && x_auto_out_3_a_ready && x_g_auto_out_3_a_bits_source[6:4] == 3'h4) x_cov_a3_from_ptw++;
        if (x_auto_in_0_a_valid && x_auto_in_1_a_valid && x_auto_in_2_a_valid && x_auto_in_0_a_bits_address[7:6] == x_auto_in_1_a_bits_address[7:6] && x_auto_in_1_a_bits_address[7:6] == x_auto_in_2_a_bits_address[7:6]) x_cov_a_contend++;
        if (x_g_auto_in_0_b_valid && x_auto_in_0_b_ready) x_cov_b_fire++;
        if (x_auto_in_0_c_valid && x_g_auto_in_0_c_ready) x_cov_c_fire++;
        if (x_g_auto_in_0_d_valid && x_auto_in_0_d_ready) x_cov_d0_fire++;
        if (x_g_auto_in_1_d_valid && x_auto_in_1_d_ready) x_cov_d1_fire++;
        if (x_g_auto_in_2_d_valid && x_auto_in_2_d_ready) x_cov_d2_fire++;
        if (x_auto_in_0_e_valid && x_g_auto_in_0_e_ready) x_cov_e_fire++;
        if (x_g_auto_in_0_d_valid && !x_u_gold.readys_mask_5[0]) x_cov_rr_flip++;
      end
      if (x_armed_at < 0 && (&x_armed)) x_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(x_s0_auto_in_2_a_ready && x_s1_auto_in_2_a_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_a_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_valid && x_s1_auto_in_2_d_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_opcode[0] && x_s1_auto_in_2_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_opcode[1] && x_s1_auto_in_2_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_opcode[2] && x_s1_auto_in_2_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_opcode[3] && x_s1_auto_in_2_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_param[0] && x_s1_auto_in_2_d_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_param[1] && x_s1_auto_in_2_d_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_size[0] && x_s1_auto_in_2_d_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_size[1] && x_s1_auto_in_2_d_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_size[2] && x_s1_auto_in_2_d_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_source[0] && x_s1_auto_in_2_d_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_source[1] && x_s1_auto_in_2_d_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_source[2] && x_s1_auto_in_2_d_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_source[3] && x_s1_auto_in_2_d_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[0] && x_s1_auto_in_2_d_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[1] && x_s1_auto_in_2_d_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[2] && x_s1_auto_in_2_d_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[3] && x_s1_auto_in_2_d_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[4] && x_s1_auto_in_2_d_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[5] && x_s1_auto_in_2_d_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[6] && x_s1_auto_in_2_d_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[7] && x_s1_auto_in_2_d_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[8] && x_s1_auto_in_2_d_bits_sink[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_sink[9] && x_s1_auto_in_2_d_bits_sink[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_sink[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_denied && x_s1_auto_in_2_d_bits_denied)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_denied 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[0] && x_s1_auto_in_2_d_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[1] && x_s1_auto_in_2_d_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[2] && x_s1_auto_in_2_d_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[3] && x_s1_auto_in_2_d_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[4] && x_s1_auto_in_2_d_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[5] && x_s1_auto_in_2_d_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[6] && x_s1_auto_in_2_d_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[7] && x_s1_auto_in_2_d_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[8] && x_s1_auto_in_2_d_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[9] && x_s1_auto_in_2_d_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[10] && x_s1_auto_in_2_d_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[11] && x_s1_auto_in_2_d_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[12] && x_s1_auto_in_2_d_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[13] && x_s1_auto_in_2_d_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[14] && x_s1_auto_in_2_d_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[15] && x_s1_auto_in_2_d_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[16] && x_s1_auto_in_2_d_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[17] && x_s1_auto_in_2_d_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[18] && x_s1_auto_in_2_d_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[19] && x_s1_auto_in_2_d_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[20] && x_s1_auto_in_2_d_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[21] && x_s1_auto_in_2_d_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[22] && x_s1_auto_in_2_d_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[23] && x_s1_auto_in_2_d_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[24] && x_s1_auto_in_2_d_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[25] && x_s1_auto_in_2_d_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[26] && x_s1_auto_in_2_d_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[27] && x_s1_auto_in_2_d_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[28] && x_s1_auto_in_2_d_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[29] && x_s1_auto_in_2_d_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[30] && x_s1_auto_in_2_d_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[31] && x_s1_auto_in_2_d_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[32] && x_s1_auto_in_2_d_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[33] && x_s1_auto_in_2_d_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[34] && x_s1_auto_in_2_d_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[35] && x_s1_auto_in_2_d_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[36] && x_s1_auto_in_2_d_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[37] && x_s1_auto_in_2_d_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[38] && x_s1_auto_in_2_d_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[39] && x_s1_auto_in_2_d_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[40] && x_s1_auto_in_2_d_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[41] && x_s1_auto_in_2_d_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[42] && x_s1_auto_in_2_d_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[43] && x_s1_auto_in_2_d_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[44] && x_s1_auto_in_2_d_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[45] && x_s1_auto_in_2_d_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[46] && x_s1_auto_in_2_d_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[47] && x_s1_auto_in_2_d_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[48] && x_s1_auto_in_2_d_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[49] && x_s1_auto_in_2_d_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[50] && x_s1_auto_in_2_d_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[51] && x_s1_auto_in_2_d_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[52] && x_s1_auto_in_2_d_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[53] && x_s1_auto_in_2_d_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[54] && x_s1_auto_in_2_d_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[55] && x_s1_auto_in_2_d_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[56] && x_s1_auto_in_2_d_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[57] && x_s1_auto_in_2_d_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[58] && x_s1_auto_in_2_d_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[59] && x_s1_auto_in_2_d_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[60] && x_s1_auto_in_2_d_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[61] && x_s1_auto_in_2_d_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[62] && x_s1_auto_in_2_d_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[63] && x_s1_auto_in_2_d_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[64] && x_s1_auto_in_2_d_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[65] && x_s1_auto_in_2_d_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[66] && x_s1_auto_in_2_d_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[67] && x_s1_auto_in_2_d_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[68] && x_s1_auto_in_2_d_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[69] && x_s1_auto_in_2_d_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[70] && x_s1_auto_in_2_d_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[71] && x_s1_auto_in_2_d_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[72] && x_s1_auto_in_2_d_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[73] && x_s1_auto_in_2_d_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[74] && x_s1_auto_in_2_d_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[75] && x_s1_auto_in_2_d_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[76] && x_s1_auto_in_2_d_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[77] && x_s1_auto_in_2_d_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[78] && x_s1_auto_in_2_d_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[79] && x_s1_auto_in_2_d_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[80] && x_s1_auto_in_2_d_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[81] && x_s1_auto_in_2_d_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[82] && x_s1_auto_in_2_d_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[83] && x_s1_auto_in_2_d_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[84] && x_s1_auto_in_2_d_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[85] && x_s1_auto_in_2_d_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[86] && x_s1_auto_in_2_d_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[87] && x_s1_auto_in_2_d_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[88] && x_s1_auto_in_2_d_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[89] && x_s1_auto_in_2_d_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[90] && x_s1_auto_in_2_d_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[91] && x_s1_auto_in_2_d_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[92] && x_s1_auto_in_2_d_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[93] && x_s1_auto_in_2_d_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[94] && x_s1_auto_in_2_d_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[95] && x_s1_auto_in_2_d_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[96] && x_s1_auto_in_2_d_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[97] && x_s1_auto_in_2_d_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[98] && x_s1_auto_in_2_d_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[99] && x_s1_auto_in_2_d_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[100] && x_s1_auto_in_2_d_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[101] && x_s1_auto_in_2_d_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[102] && x_s1_auto_in_2_d_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[103] && x_s1_auto_in_2_d_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[104] && x_s1_auto_in_2_d_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[105] && x_s1_auto_in_2_d_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[106] && x_s1_auto_in_2_d_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[107] && x_s1_auto_in_2_d_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[108] && x_s1_auto_in_2_d_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[109] && x_s1_auto_in_2_d_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[110] && x_s1_auto_in_2_d_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[111] && x_s1_auto_in_2_d_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[112] && x_s1_auto_in_2_d_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[113] && x_s1_auto_in_2_d_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[114] && x_s1_auto_in_2_d_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[115] && x_s1_auto_in_2_d_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[116] && x_s1_auto_in_2_d_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[117] && x_s1_auto_in_2_d_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[118] && x_s1_auto_in_2_d_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[119] && x_s1_auto_in_2_d_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[120] && x_s1_auto_in_2_d_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[121] && x_s1_auto_in_2_d_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[122] && x_s1_auto_in_2_d_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[123] && x_s1_auto_in_2_d_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[124] && x_s1_auto_in_2_d_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[125] && x_s1_auto_in_2_d_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[126] && x_s1_auto_in_2_d_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[127] && x_s1_auto_in_2_d_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[128] && x_s1_auto_in_2_d_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[129] && x_s1_auto_in_2_d_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[130] && x_s1_auto_in_2_d_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[131] && x_s1_auto_in_2_d_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[132] && x_s1_auto_in_2_d_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[133] && x_s1_auto_in_2_d_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[134] && x_s1_auto_in_2_d_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[135] && x_s1_auto_in_2_d_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[136] && x_s1_auto_in_2_d_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[137] && x_s1_auto_in_2_d_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[138] && x_s1_auto_in_2_d_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[139] && x_s1_auto_in_2_d_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[140] && x_s1_auto_in_2_d_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[141] && x_s1_auto_in_2_d_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[142] && x_s1_auto_in_2_d_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[143] && x_s1_auto_in_2_d_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[144] && x_s1_auto_in_2_d_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[145] && x_s1_auto_in_2_d_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[146] && x_s1_auto_in_2_d_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[147] && x_s1_auto_in_2_d_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[148] && x_s1_auto_in_2_d_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[149] && x_s1_auto_in_2_d_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[150] && x_s1_auto_in_2_d_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[151] && x_s1_auto_in_2_d_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[152] && x_s1_auto_in_2_d_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[153] && x_s1_auto_in_2_d_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[154] && x_s1_auto_in_2_d_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[155] && x_s1_auto_in_2_d_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[156] && x_s1_auto_in_2_d_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[157] && x_s1_auto_in_2_d_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[158] && x_s1_auto_in_2_d_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[159] && x_s1_auto_in_2_d_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[160] && x_s1_auto_in_2_d_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[161] && x_s1_auto_in_2_d_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[162] && x_s1_auto_in_2_d_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[163] && x_s1_auto_in_2_d_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[164] && x_s1_auto_in_2_d_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[165] && x_s1_auto_in_2_d_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[166] && x_s1_auto_in_2_d_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[167] && x_s1_auto_in_2_d_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[168] && x_s1_auto_in_2_d_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[169] && x_s1_auto_in_2_d_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[170] && x_s1_auto_in_2_d_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[171] && x_s1_auto_in_2_d_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[172] && x_s1_auto_in_2_d_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[173] && x_s1_auto_in_2_d_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[174] && x_s1_auto_in_2_d_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[175] && x_s1_auto_in_2_d_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[176] && x_s1_auto_in_2_d_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[177] && x_s1_auto_in_2_d_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[178] && x_s1_auto_in_2_d_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[179] && x_s1_auto_in_2_d_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[180] && x_s1_auto_in_2_d_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[181] && x_s1_auto_in_2_d_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[182] && x_s1_auto_in_2_d_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[183] && x_s1_auto_in_2_d_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[184] && x_s1_auto_in_2_d_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[185] && x_s1_auto_in_2_d_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[186] && x_s1_auto_in_2_d_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[187] && x_s1_auto_in_2_d_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[188] && x_s1_auto_in_2_d_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[189] && x_s1_auto_in_2_d_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[190] && x_s1_auto_in_2_d_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[191] && x_s1_auto_in_2_d_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[192] && x_s1_auto_in_2_d_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[193] && x_s1_auto_in_2_d_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[194] && x_s1_auto_in_2_d_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[195] && x_s1_auto_in_2_d_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[196] && x_s1_auto_in_2_d_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[197] && x_s1_auto_in_2_d_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[198] && x_s1_auto_in_2_d_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[199] && x_s1_auto_in_2_d_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[200] && x_s1_auto_in_2_d_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[201] && x_s1_auto_in_2_d_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[202] && x_s1_auto_in_2_d_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[203] && x_s1_auto_in_2_d_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[204] && x_s1_auto_in_2_d_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[205] && x_s1_auto_in_2_d_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[206] && x_s1_auto_in_2_d_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[207] && x_s1_auto_in_2_d_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[208] && x_s1_auto_in_2_d_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[209] && x_s1_auto_in_2_d_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[210] && x_s1_auto_in_2_d_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[211] && x_s1_auto_in_2_d_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[212] && x_s1_auto_in_2_d_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[213] && x_s1_auto_in_2_d_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[214] && x_s1_auto_in_2_d_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[215] && x_s1_auto_in_2_d_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[216] && x_s1_auto_in_2_d_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[217] && x_s1_auto_in_2_d_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[218] && x_s1_auto_in_2_d_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[219] && x_s1_auto_in_2_d_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[220] && x_s1_auto_in_2_d_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[221] && x_s1_auto_in_2_d_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[222] && x_s1_auto_in_2_d_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[223] && x_s1_auto_in_2_d_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[224] && x_s1_auto_in_2_d_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[225] && x_s1_auto_in_2_d_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[226] && x_s1_auto_in_2_d_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[227] && x_s1_auto_in_2_d_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[228] && x_s1_auto_in_2_d_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[229] && x_s1_auto_in_2_d_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[230] && x_s1_auto_in_2_d_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[231] && x_s1_auto_in_2_d_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[232] && x_s1_auto_in_2_d_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[233] && x_s1_auto_in_2_d_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[234] && x_s1_auto_in_2_d_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[235] && x_s1_auto_in_2_d_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[236] && x_s1_auto_in_2_d_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[237] && x_s1_auto_in_2_d_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[238] && x_s1_auto_in_2_d_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[239] && x_s1_auto_in_2_d_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[240] && x_s1_auto_in_2_d_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[241] && x_s1_auto_in_2_d_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[242] && x_s1_auto_in_2_d_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[243] && x_s1_auto_in_2_d_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[244] && x_s1_auto_in_2_d_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[245] && x_s1_auto_in_2_d_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[246] && x_s1_auto_in_2_d_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[247] && x_s1_auto_in_2_d_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[248] && x_s1_auto_in_2_d_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[249] && x_s1_auto_in_2_d_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[250] && x_s1_auto_in_2_d_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[251] && x_s1_auto_in_2_d_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[252] && x_s1_auto_in_2_d_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[253] && x_s1_auto_in_2_d_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[254] && x_s1_auto_in_2_d_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_data[255] && x_s1_auto_in_2_d_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_2_d_bits_corrupt && x_s1_auto_in_2_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_2_d_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_a_ready && x_s1_auto_in_1_a_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_a_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_valid && x_s1_auto_in_1_d_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[0] && x_s1_auto_in_1_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[1] && x_s1_auto_in_1_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[2] && x_s1_auto_in_1_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_opcode[3] && x_s1_auto_in_1_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_param[0] && x_s1_auto_in_1_d_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_param[1] && x_s1_auto_in_1_d_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_size[0] && x_s1_auto_in_1_d_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_size[1] && x_s1_auto_in_1_d_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_size[2] && x_s1_auto_in_1_d_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[0] && x_s1_auto_in_1_d_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[1] && x_s1_auto_in_1_d_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[2] && x_s1_auto_in_1_d_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_source[3] && x_s1_auto_in_1_d_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[0] && x_s1_auto_in_1_d_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[1] && x_s1_auto_in_1_d_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[2] && x_s1_auto_in_1_d_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[3] && x_s1_auto_in_1_d_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[4] && x_s1_auto_in_1_d_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[5] && x_s1_auto_in_1_d_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[6] && x_s1_auto_in_1_d_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[7] && x_s1_auto_in_1_d_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[8] && x_s1_auto_in_1_d_bits_sink[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_sink[9] && x_s1_auto_in_1_d_bits_sink[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_sink[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_denied && x_s1_auto_in_1_d_bits_denied)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_denied 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[0] && x_s1_auto_in_1_d_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[1] && x_s1_auto_in_1_d_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[2] && x_s1_auto_in_1_d_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[3] && x_s1_auto_in_1_d_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[4] && x_s1_auto_in_1_d_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[5] && x_s1_auto_in_1_d_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[6] && x_s1_auto_in_1_d_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[7] && x_s1_auto_in_1_d_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[8] && x_s1_auto_in_1_d_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[9] && x_s1_auto_in_1_d_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[10] && x_s1_auto_in_1_d_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[11] && x_s1_auto_in_1_d_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[12] && x_s1_auto_in_1_d_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[13] && x_s1_auto_in_1_d_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[14] && x_s1_auto_in_1_d_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[15] && x_s1_auto_in_1_d_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[16] && x_s1_auto_in_1_d_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[17] && x_s1_auto_in_1_d_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[18] && x_s1_auto_in_1_d_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[19] && x_s1_auto_in_1_d_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[20] && x_s1_auto_in_1_d_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[21] && x_s1_auto_in_1_d_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[22] && x_s1_auto_in_1_d_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[23] && x_s1_auto_in_1_d_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[24] && x_s1_auto_in_1_d_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[25] && x_s1_auto_in_1_d_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[26] && x_s1_auto_in_1_d_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[27] && x_s1_auto_in_1_d_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[28] && x_s1_auto_in_1_d_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[29] && x_s1_auto_in_1_d_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[30] && x_s1_auto_in_1_d_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[31] && x_s1_auto_in_1_d_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[32] && x_s1_auto_in_1_d_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[33] && x_s1_auto_in_1_d_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[34] && x_s1_auto_in_1_d_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[35] && x_s1_auto_in_1_d_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[36] && x_s1_auto_in_1_d_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[37] && x_s1_auto_in_1_d_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[38] && x_s1_auto_in_1_d_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[39] && x_s1_auto_in_1_d_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[40] && x_s1_auto_in_1_d_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[41] && x_s1_auto_in_1_d_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[42] && x_s1_auto_in_1_d_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[43] && x_s1_auto_in_1_d_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[44] && x_s1_auto_in_1_d_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[45] && x_s1_auto_in_1_d_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[46] && x_s1_auto_in_1_d_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[47] && x_s1_auto_in_1_d_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[48] && x_s1_auto_in_1_d_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[49] && x_s1_auto_in_1_d_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[50] && x_s1_auto_in_1_d_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[51] && x_s1_auto_in_1_d_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[52] && x_s1_auto_in_1_d_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[53] && x_s1_auto_in_1_d_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[54] && x_s1_auto_in_1_d_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[55] && x_s1_auto_in_1_d_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[56] && x_s1_auto_in_1_d_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[57] && x_s1_auto_in_1_d_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[58] && x_s1_auto_in_1_d_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[59] && x_s1_auto_in_1_d_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[60] && x_s1_auto_in_1_d_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[61] && x_s1_auto_in_1_d_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[62] && x_s1_auto_in_1_d_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[63] && x_s1_auto_in_1_d_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[64] && x_s1_auto_in_1_d_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[65] && x_s1_auto_in_1_d_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[66] && x_s1_auto_in_1_d_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[67] && x_s1_auto_in_1_d_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[68] && x_s1_auto_in_1_d_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[69] && x_s1_auto_in_1_d_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[70] && x_s1_auto_in_1_d_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[71] && x_s1_auto_in_1_d_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[72] && x_s1_auto_in_1_d_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[73] && x_s1_auto_in_1_d_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[74] && x_s1_auto_in_1_d_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[75] && x_s1_auto_in_1_d_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[76] && x_s1_auto_in_1_d_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[77] && x_s1_auto_in_1_d_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[78] && x_s1_auto_in_1_d_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[79] && x_s1_auto_in_1_d_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[80] && x_s1_auto_in_1_d_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[81] && x_s1_auto_in_1_d_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[82] && x_s1_auto_in_1_d_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[83] && x_s1_auto_in_1_d_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[84] && x_s1_auto_in_1_d_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[85] && x_s1_auto_in_1_d_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[86] && x_s1_auto_in_1_d_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[87] && x_s1_auto_in_1_d_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[88] && x_s1_auto_in_1_d_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[89] && x_s1_auto_in_1_d_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[90] && x_s1_auto_in_1_d_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[91] && x_s1_auto_in_1_d_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[92] && x_s1_auto_in_1_d_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[93] && x_s1_auto_in_1_d_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[94] && x_s1_auto_in_1_d_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[95] && x_s1_auto_in_1_d_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[96] && x_s1_auto_in_1_d_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[97] && x_s1_auto_in_1_d_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[98] && x_s1_auto_in_1_d_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[99] && x_s1_auto_in_1_d_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[100] && x_s1_auto_in_1_d_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[101] && x_s1_auto_in_1_d_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[102] && x_s1_auto_in_1_d_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[103] && x_s1_auto_in_1_d_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[104] && x_s1_auto_in_1_d_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[105] && x_s1_auto_in_1_d_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[106] && x_s1_auto_in_1_d_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[107] && x_s1_auto_in_1_d_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[108] && x_s1_auto_in_1_d_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[109] && x_s1_auto_in_1_d_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[110] && x_s1_auto_in_1_d_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[111] && x_s1_auto_in_1_d_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[112] && x_s1_auto_in_1_d_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[113] && x_s1_auto_in_1_d_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[114] && x_s1_auto_in_1_d_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[115] && x_s1_auto_in_1_d_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[116] && x_s1_auto_in_1_d_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[117] && x_s1_auto_in_1_d_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[118] && x_s1_auto_in_1_d_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[119] && x_s1_auto_in_1_d_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[120] && x_s1_auto_in_1_d_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[121] && x_s1_auto_in_1_d_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[122] && x_s1_auto_in_1_d_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[123] && x_s1_auto_in_1_d_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[124] && x_s1_auto_in_1_d_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[125] && x_s1_auto_in_1_d_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[126] && x_s1_auto_in_1_d_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[127] && x_s1_auto_in_1_d_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[128] && x_s1_auto_in_1_d_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[129] && x_s1_auto_in_1_d_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[130] && x_s1_auto_in_1_d_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[131] && x_s1_auto_in_1_d_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[132] && x_s1_auto_in_1_d_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[133] && x_s1_auto_in_1_d_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[134] && x_s1_auto_in_1_d_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[135] && x_s1_auto_in_1_d_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[136] && x_s1_auto_in_1_d_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[137] && x_s1_auto_in_1_d_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[138] && x_s1_auto_in_1_d_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[139] && x_s1_auto_in_1_d_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[140] && x_s1_auto_in_1_d_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[141] && x_s1_auto_in_1_d_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[142] && x_s1_auto_in_1_d_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[143] && x_s1_auto_in_1_d_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[144] && x_s1_auto_in_1_d_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[145] && x_s1_auto_in_1_d_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[146] && x_s1_auto_in_1_d_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[147] && x_s1_auto_in_1_d_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[148] && x_s1_auto_in_1_d_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[149] && x_s1_auto_in_1_d_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[150] && x_s1_auto_in_1_d_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[151] && x_s1_auto_in_1_d_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[152] && x_s1_auto_in_1_d_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[153] && x_s1_auto_in_1_d_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[154] && x_s1_auto_in_1_d_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[155] && x_s1_auto_in_1_d_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[156] && x_s1_auto_in_1_d_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[157] && x_s1_auto_in_1_d_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[158] && x_s1_auto_in_1_d_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[159] && x_s1_auto_in_1_d_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[160] && x_s1_auto_in_1_d_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[161] && x_s1_auto_in_1_d_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[162] && x_s1_auto_in_1_d_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[163] && x_s1_auto_in_1_d_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[164] && x_s1_auto_in_1_d_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[165] && x_s1_auto_in_1_d_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[166] && x_s1_auto_in_1_d_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[167] && x_s1_auto_in_1_d_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[168] && x_s1_auto_in_1_d_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[169] && x_s1_auto_in_1_d_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[170] && x_s1_auto_in_1_d_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[171] && x_s1_auto_in_1_d_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[172] && x_s1_auto_in_1_d_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[173] && x_s1_auto_in_1_d_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[174] && x_s1_auto_in_1_d_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[175] && x_s1_auto_in_1_d_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[176] && x_s1_auto_in_1_d_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[177] && x_s1_auto_in_1_d_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[178] && x_s1_auto_in_1_d_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[179] && x_s1_auto_in_1_d_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[180] && x_s1_auto_in_1_d_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[181] && x_s1_auto_in_1_d_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[182] && x_s1_auto_in_1_d_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[183] && x_s1_auto_in_1_d_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[184] && x_s1_auto_in_1_d_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[185] && x_s1_auto_in_1_d_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[186] && x_s1_auto_in_1_d_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[187] && x_s1_auto_in_1_d_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[188] && x_s1_auto_in_1_d_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[189] && x_s1_auto_in_1_d_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[190] && x_s1_auto_in_1_d_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[191] && x_s1_auto_in_1_d_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[192] && x_s1_auto_in_1_d_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[193] && x_s1_auto_in_1_d_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[194] && x_s1_auto_in_1_d_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[195] && x_s1_auto_in_1_d_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[196] && x_s1_auto_in_1_d_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[197] && x_s1_auto_in_1_d_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[198] && x_s1_auto_in_1_d_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[199] && x_s1_auto_in_1_d_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[200] && x_s1_auto_in_1_d_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[201] && x_s1_auto_in_1_d_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[202] && x_s1_auto_in_1_d_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[203] && x_s1_auto_in_1_d_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[204] && x_s1_auto_in_1_d_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[205] && x_s1_auto_in_1_d_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[206] && x_s1_auto_in_1_d_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[207] && x_s1_auto_in_1_d_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[208] && x_s1_auto_in_1_d_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[209] && x_s1_auto_in_1_d_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[210] && x_s1_auto_in_1_d_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[211] && x_s1_auto_in_1_d_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[212] && x_s1_auto_in_1_d_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[213] && x_s1_auto_in_1_d_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[214] && x_s1_auto_in_1_d_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[215] && x_s1_auto_in_1_d_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[216] && x_s1_auto_in_1_d_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[217] && x_s1_auto_in_1_d_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[218] && x_s1_auto_in_1_d_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[219] && x_s1_auto_in_1_d_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[220] && x_s1_auto_in_1_d_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[221] && x_s1_auto_in_1_d_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[222] && x_s1_auto_in_1_d_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[223] && x_s1_auto_in_1_d_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[224] && x_s1_auto_in_1_d_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[225] && x_s1_auto_in_1_d_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[226] && x_s1_auto_in_1_d_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[227] && x_s1_auto_in_1_d_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[228] && x_s1_auto_in_1_d_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[229] && x_s1_auto_in_1_d_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[230] && x_s1_auto_in_1_d_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[231] && x_s1_auto_in_1_d_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[232] && x_s1_auto_in_1_d_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[233] && x_s1_auto_in_1_d_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[234] && x_s1_auto_in_1_d_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[235] && x_s1_auto_in_1_d_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[236] && x_s1_auto_in_1_d_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[237] && x_s1_auto_in_1_d_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[238] && x_s1_auto_in_1_d_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[239] && x_s1_auto_in_1_d_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[240] && x_s1_auto_in_1_d_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[241] && x_s1_auto_in_1_d_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[242] && x_s1_auto_in_1_d_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[243] && x_s1_auto_in_1_d_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[244] && x_s1_auto_in_1_d_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[245] && x_s1_auto_in_1_d_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[246] && x_s1_auto_in_1_d_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[247] && x_s1_auto_in_1_d_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[248] && x_s1_auto_in_1_d_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[249] && x_s1_auto_in_1_d_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[250] && x_s1_auto_in_1_d_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[251] && x_s1_auto_in_1_d_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[252] && x_s1_auto_in_1_d_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[253] && x_s1_auto_in_1_d_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[254] && x_s1_auto_in_1_d_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_data[255] && x_s1_auto_in_1_d_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_1_d_bits_corrupt && x_s1_auto_in_1_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_1_d_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_a_ready && x_s1_auto_in_0_a_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_a_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_valid && x_s1_auto_in_0_b_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_opcode[0] && x_s1_auto_in_0_b_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_opcode[1] && x_s1_auto_in_0_b_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_opcode[2] && x_s1_auto_in_0_b_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_param[0] && x_s1_auto_in_0_b_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_param[1] && x_s1_auto_in_0_b_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_size[0] && x_s1_auto_in_0_b_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_size[1] && x_s1_auto_in_0_b_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_size[2] && x_s1_auto_in_0_b_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[0] && x_s1_auto_in_0_b_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[1] && x_s1_auto_in_0_b_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[2] && x_s1_auto_in_0_b_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[3] && x_s1_auto_in_0_b_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[4] && x_s1_auto_in_0_b_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_source[5] && x_s1_auto_in_0_b_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[0] && x_s1_auto_in_0_b_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[1] && x_s1_auto_in_0_b_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[2] && x_s1_auto_in_0_b_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[3] && x_s1_auto_in_0_b_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[4] && x_s1_auto_in_0_b_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[5] && x_s1_auto_in_0_b_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[6] && x_s1_auto_in_0_b_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[7] && x_s1_auto_in_0_b_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[8] && x_s1_auto_in_0_b_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[9] && x_s1_auto_in_0_b_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[10] && x_s1_auto_in_0_b_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[11] && x_s1_auto_in_0_b_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[12] && x_s1_auto_in_0_b_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[13] && x_s1_auto_in_0_b_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[14] && x_s1_auto_in_0_b_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[15] && x_s1_auto_in_0_b_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[16] && x_s1_auto_in_0_b_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[17] && x_s1_auto_in_0_b_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[18] && x_s1_auto_in_0_b_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[19] && x_s1_auto_in_0_b_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[20] && x_s1_auto_in_0_b_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[21] && x_s1_auto_in_0_b_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[22] && x_s1_auto_in_0_b_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[23] && x_s1_auto_in_0_b_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[24] && x_s1_auto_in_0_b_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[25] && x_s1_auto_in_0_b_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[26] && x_s1_auto_in_0_b_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[27] && x_s1_auto_in_0_b_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[28] && x_s1_auto_in_0_b_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[29] && x_s1_auto_in_0_b_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[30] && x_s1_auto_in_0_b_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[31] && x_s1_auto_in_0_b_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[32] && x_s1_auto_in_0_b_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[33] && x_s1_auto_in_0_b_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[34] && x_s1_auto_in_0_b_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[35] && x_s1_auto_in_0_b_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[36] && x_s1_auto_in_0_b_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[37] && x_s1_auto_in_0_b_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[38] && x_s1_auto_in_0_b_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[39] && x_s1_auto_in_0_b_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[40] && x_s1_auto_in_0_b_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[41] && x_s1_auto_in_0_b_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[42] && x_s1_auto_in_0_b_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[43] && x_s1_auto_in_0_b_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[44] && x_s1_auto_in_0_b_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[45] && x_s1_auto_in_0_b_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[46] && x_s1_auto_in_0_b_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_address[47] && x_s1_auto_in_0_b_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[0] && x_s1_auto_in_0_b_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[1] && x_s1_auto_in_0_b_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[2] && x_s1_auto_in_0_b_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[3] && x_s1_auto_in_0_b_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[4] && x_s1_auto_in_0_b_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[5] && x_s1_auto_in_0_b_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[6] && x_s1_auto_in_0_b_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[7] && x_s1_auto_in_0_b_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[8] && x_s1_auto_in_0_b_bits_mask[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[9] && x_s1_auto_in_0_b_bits_mask[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[10] && x_s1_auto_in_0_b_bits_mask[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[11] && x_s1_auto_in_0_b_bits_mask[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[12] && x_s1_auto_in_0_b_bits_mask[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[13] && x_s1_auto_in_0_b_bits_mask[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[14] && x_s1_auto_in_0_b_bits_mask[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[15] && x_s1_auto_in_0_b_bits_mask[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[16] && x_s1_auto_in_0_b_bits_mask[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[17] && x_s1_auto_in_0_b_bits_mask[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[18] && x_s1_auto_in_0_b_bits_mask[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[19] && x_s1_auto_in_0_b_bits_mask[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[20] && x_s1_auto_in_0_b_bits_mask[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[21] && x_s1_auto_in_0_b_bits_mask[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[22] && x_s1_auto_in_0_b_bits_mask[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[23] && x_s1_auto_in_0_b_bits_mask[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[24] && x_s1_auto_in_0_b_bits_mask[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[25] && x_s1_auto_in_0_b_bits_mask[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[26] && x_s1_auto_in_0_b_bits_mask[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[27] && x_s1_auto_in_0_b_bits_mask[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[28] && x_s1_auto_in_0_b_bits_mask[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[29] && x_s1_auto_in_0_b_bits_mask[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[30] && x_s1_auto_in_0_b_bits_mask[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_mask[31] && x_s1_auto_in_0_b_bits_mask[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_mask[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[0] && x_s1_auto_in_0_b_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[1] && x_s1_auto_in_0_b_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[2] && x_s1_auto_in_0_b_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[3] && x_s1_auto_in_0_b_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[4] && x_s1_auto_in_0_b_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[5] && x_s1_auto_in_0_b_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[6] && x_s1_auto_in_0_b_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[7] && x_s1_auto_in_0_b_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[8] && x_s1_auto_in_0_b_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[9] && x_s1_auto_in_0_b_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[10] && x_s1_auto_in_0_b_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[11] && x_s1_auto_in_0_b_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[12] && x_s1_auto_in_0_b_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[13] && x_s1_auto_in_0_b_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[14] && x_s1_auto_in_0_b_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[15] && x_s1_auto_in_0_b_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[16] && x_s1_auto_in_0_b_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[17] && x_s1_auto_in_0_b_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[18] && x_s1_auto_in_0_b_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[19] && x_s1_auto_in_0_b_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[20] && x_s1_auto_in_0_b_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[21] && x_s1_auto_in_0_b_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[22] && x_s1_auto_in_0_b_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[23] && x_s1_auto_in_0_b_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[24] && x_s1_auto_in_0_b_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[25] && x_s1_auto_in_0_b_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[26] && x_s1_auto_in_0_b_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[27] && x_s1_auto_in_0_b_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[28] && x_s1_auto_in_0_b_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[29] && x_s1_auto_in_0_b_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[30] && x_s1_auto_in_0_b_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[31] && x_s1_auto_in_0_b_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[32] && x_s1_auto_in_0_b_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[33] && x_s1_auto_in_0_b_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[34] && x_s1_auto_in_0_b_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[35] && x_s1_auto_in_0_b_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[36] && x_s1_auto_in_0_b_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[37] && x_s1_auto_in_0_b_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[38] && x_s1_auto_in_0_b_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[39] && x_s1_auto_in_0_b_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[40] && x_s1_auto_in_0_b_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[41] && x_s1_auto_in_0_b_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[42] && x_s1_auto_in_0_b_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[43] && x_s1_auto_in_0_b_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[44] && x_s1_auto_in_0_b_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[45] && x_s1_auto_in_0_b_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[46] && x_s1_auto_in_0_b_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[47] && x_s1_auto_in_0_b_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[48] && x_s1_auto_in_0_b_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[49] && x_s1_auto_in_0_b_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[50] && x_s1_auto_in_0_b_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[51] && x_s1_auto_in_0_b_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[52] && x_s1_auto_in_0_b_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[53] && x_s1_auto_in_0_b_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[54] && x_s1_auto_in_0_b_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[55] && x_s1_auto_in_0_b_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[56] && x_s1_auto_in_0_b_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[57] && x_s1_auto_in_0_b_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[58] && x_s1_auto_in_0_b_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[59] && x_s1_auto_in_0_b_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[60] && x_s1_auto_in_0_b_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[61] && x_s1_auto_in_0_b_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[62] && x_s1_auto_in_0_b_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[63] && x_s1_auto_in_0_b_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[64] && x_s1_auto_in_0_b_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[65] && x_s1_auto_in_0_b_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[66] && x_s1_auto_in_0_b_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[67] && x_s1_auto_in_0_b_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[68] && x_s1_auto_in_0_b_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[69] && x_s1_auto_in_0_b_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[70] && x_s1_auto_in_0_b_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[71] && x_s1_auto_in_0_b_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[72] && x_s1_auto_in_0_b_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[73] && x_s1_auto_in_0_b_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[74] && x_s1_auto_in_0_b_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[75] && x_s1_auto_in_0_b_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[76] && x_s1_auto_in_0_b_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[77] && x_s1_auto_in_0_b_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[78] && x_s1_auto_in_0_b_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[79] && x_s1_auto_in_0_b_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[80] && x_s1_auto_in_0_b_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[81] && x_s1_auto_in_0_b_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[82] && x_s1_auto_in_0_b_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[83] && x_s1_auto_in_0_b_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[84] && x_s1_auto_in_0_b_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[85] && x_s1_auto_in_0_b_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[86] && x_s1_auto_in_0_b_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[87] && x_s1_auto_in_0_b_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[88] && x_s1_auto_in_0_b_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[89] && x_s1_auto_in_0_b_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[90] && x_s1_auto_in_0_b_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[91] && x_s1_auto_in_0_b_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[92] && x_s1_auto_in_0_b_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[93] && x_s1_auto_in_0_b_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[94] && x_s1_auto_in_0_b_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[95] && x_s1_auto_in_0_b_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[96] && x_s1_auto_in_0_b_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[97] && x_s1_auto_in_0_b_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[98] && x_s1_auto_in_0_b_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[99] && x_s1_auto_in_0_b_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[100] && x_s1_auto_in_0_b_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[101] && x_s1_auto_in_0_b_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[102] && x_s1_auto_in_0_b_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[103] && x_s1_auto_in_0_b_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[104] && x_s1_auto_in_0_b_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[105] && x_s1_auto_in_0_b_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[106] && x_s1_auto_in_0_b_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[107] && x_s1_auto_in_0_b_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[108] && x_s1_auto_in_0_b_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[109] && x_s1_auto_in_0_b_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[110] && x_s1_auto_in_0_b_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[111] && x_s1_auto_in_0_b_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[112] && x_s1_auto_in_0_b_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[113] && x_s1_auto_in_0_b_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[114] && x_s1_auto_in_0_b_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[115] && x_s1_auto_in_0_b_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[116] && x_s1_auto_in_0_b_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[117] && x_s1_auto_in_0_b_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[118] && x_s1_auto_in_0_b_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[119] && x_s1_auto_in_0_b_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[120] && x_s1_auto_in_0_b_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[121] && x_s1_auto_in_0_b_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[122] && x_s1_auto_in_0_b_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[123] && x_s1_auto_in_0_b_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[124] && x_s1_auto_in_0_b_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[125] && x_s1_auto_in_0_b_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[126] && x_s1_auto_in_0_b_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[127] && x_s1_auto_in_0_b_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[128] && x_s1_auto_in_0_b_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[129] && x_s1_auto_in_0_b_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[130] && x_s1_auto_in_0_b_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[131] && x_s1_auto_in_0_b_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[132] && x_s1_auto_in_0_b_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[133] && x_s1_auto_in_0_b_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[134] && x_s1_auto_in_0_b_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[135] && x_s1_auto_in_0_b_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[136] && x_s1_auto_in_0_b_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[137] && x_s1_auto_in_0_b_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[138] && x_s1_auto_in_0_b_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[139] && x_s1_auto_in_0_b_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[140] && x_s1_auto_in_0_b_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[141] && x_s1_auto_in_0_b_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[142] && x_s1_auto_in_0_b_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[143] && x_s1_auto_in_0_b_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[144] && x_s1_auto_in_0_b_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[145] && x_s1_auto_in_0_b_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[146] && x_s1_auto_in_0_b_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[147] && x_s1_auto_in_0_b_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[148] && x_s1_auto_in_0_b_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[149] && x_s1_auto_in_0_b_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[150] && x_s1_auto_in_0_b_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[151] && x_s1_auto_in_0_b_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[152] && x_s1_auto_in_0_b_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[153] && x_s1_auto_in_0_b_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[154] && x_s1_auto_in_0_b_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[155] && x_s1_auto_in_0_b_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[156] && x_s1_auto_in_0_b_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[157] && x_s1_auto_in_0_b_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[158] && x_s1_auto_in_0_b_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[159] && x_s1_auto_in_0_b_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[160] && x_s1_auto_in_0_b_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[161] && x_s1_auto_in_0_b_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[162] && x_s1_auto_in_0_b_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[163] && x_s1_auto_in_0_b_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[164] && x_s1_auto_in_0_b_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[165] && x_s1_auto_in_0_b_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[166] && x_s1_auto_in_0_b_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[167] && x_s1_auto_in_0_b_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[168] && x_s1_auto_in_0_b_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[169] && x_s1_auto_in_0_b_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[170] && x_s1_auto_in_0_b_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[171] && x_s1_auto_in_0_b_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[172] && x_s1_auto_in_0_b_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[173] && x_s1_auto_in_0_b_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[174] && x_s1_auto_in_0_b_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[175] && x_s1_auto_in_0_b_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[176] && x_s1_auto_in_0_b_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[177] && x_s1_auto_in_0_b_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[178] && x_s1_auto_in_0_b_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[179] && x_s1_auto_in_0_b_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[180] && x_s1_auto_in_0_b_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[181] && x_s1_auto_in_0_b_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[182] && x_s1_auto_in_0_b_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[183] && x_s1_auto_in_0_b_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[184] && x_s1_auto_in_0_b_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[185] && x_s1_auto_in_0_b_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[186] && x_s1_auto_in_0_b_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[187] && x_s1_auto_in_0_b_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[188] && x_s1_auto_in_0_b_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[189] && x_s1_auto_in_0_b_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[190] && x_s1_auto_in_0_b_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[191] && x_s1_auto_in_0_b_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[192] && x_s1_auto_in_0_b_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[193] && x_s1_auto_in_0_b_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[194] && x_s1_auto_in_0_b_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[195] && x_s1_auto_in_0_b_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[196] && x_s1_auto_in_0_b_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[197] && x_s1_auto_in_0_b_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[198] && x_s1_auto_in_0_b_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[199] && x_s1_auto_in_0_b_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[200] && x_s1_auto_in_0_b_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[201] && x_s1_auto_in_0_b_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[202] && x_s1_auto_in_0_b_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[203] && x_s1_auto_in_0_b_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[204] && x_s1_auto_in_0_b_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[205] && x_s1_auto_in_0_b_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[206] && x_s1_auto_in_0_b_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[207] && x_s1_auto_in_0_b_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[208] && x_s1_auto_in_0_b_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[209] && x_s1_auto_in_0_b_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[210] && x_s1_auto_in_0_b_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[211] && x_s1_auto_in_0_b_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[212] && x_s1_auto_in_0_b_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[213] && x_s1_auto_in_0_b_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[214] && x_s1_auto_in_0_b_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[215] && x_s1_auto_in_0_b_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[216] && x_s1_auto_in_0_b_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[217] && x_s1_auto_in_0_b_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[218] && x_s1_auto_in_0_b_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[219] && x_s1_auto_in_0_b_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[220] && x_s1_auto_in_0_b_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[221] && x_s1_auto_in_0_b_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[222] && x_s1_auto_in_0_b_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[223] && x_s1_auto_in_0_b_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[224] && x_s1_auto_in_0_b_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[225] && x_s1_auto_in_0_b_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[226] && x_s1_auto_in_0_b_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[227] && x_s1_auto_in_0_b_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[228] && x_s1_auto_in_0_b_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[229] && x_s1_auto_in_0_b_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[230] && x_s1_auto_in_0_b_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[231] && x_s1_auto_in_0_b_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[232] && x_s1_auto_in_0_b_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[233] && x_s1_auto_in_0_b_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[234] && x_s1_auto_in_0_b_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[235] && x_s1_auto_in_0_b_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[236] && x_s1_auto_in_0_b_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[237] && x_s1_auto_in_0_b_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[238] && x_s1_auto_in_0_b_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[239] && x_s1_auto_in_0_b_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[240] && x_s1_auto_in_0_b_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[241] && x_s1_auto_in_0_b_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[242] && x_s1_auto_in_0_b_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[243] && x_s1_auto_in_0_b_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[244] && x_s1_auto_in_0_b_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[245] && x_s1_auto_in_0_b_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[246] && x_s1_auto_in_0_b_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[247] && x_s1_auto_in_0_b_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[248] && x_s1_auto_in_0_b_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[249] && x_s1_auto_in_0_b_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[250] && x_s1_auto_in_0_b_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[251] && x_s1_auto_in_0_b_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[252] && x_s1_auto_in_0_b_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[253] && x_s1_auto_in_0_b_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[254] && x_s1_auto_in_0_b_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_data[255] && x_s1_auto_in_0_b_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_b_bits_corrupt && x_s1_auto_in_0_b_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_b_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_c_ready && x_s1_auto_in_0_c_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_c_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_valid && x_s1_auto_in_0_d_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[0] && x_s1_auto_in_0_d_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[1] && x_s1_auto_in_0_d_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[2] && x_s1_auto_in_0_d_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_opcode[3] && x_s1_auto_in_0_d_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_param[0] && x_s1_auto_in_0_d_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_param[1] && x_s1_auto_in_0_d_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_size[0] && x_s1_auto_in_0_d_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_size[1] && x_s1_auto_in_0_d_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_size[2] && x_s1_auto_in_0_d_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[0] && x_s1_auto_in_0_d_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[1] && x_s1_auto_in_0_d_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[2] && x_s1_auto_in_0_d_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[3] && x_s1_auto_in_0_d_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[4] && x_s1_auto_in_0_d_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_source[5] && x_s1_auto_in_0_d_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[0] && x_s1_auto_in_0_d_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[1] && x_s1_auto_in_0_d_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[2] && x_s1_auto_in_0_d_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[3] && x_s1_auto_in_0_d_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[4] && x_s1_auto_in_0_d_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[5] && x_s1_auto_in_0_d_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[6] && x_s1_auto_in_0_d_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[7] && x_s1_auto_in_0_d_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[8] && x_s1_auto_in_0_d_bits_sink[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_sink[9] && x_s1_auto_in_0_d_bits_sink[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_sink[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_denied && x_s1_auto_in_0_d_bits_denied)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_denied 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_echo_isKeyword && x_s1_auto_in_0_d_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[0] && x_s1_auto_in_0_d_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[1] && x_s1_auto_in_0_d_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[2] && x_s1_auto_in_0_d_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[3] && x_s1_auto_in_0_d_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[4] && x_s1_auto_in_0_d_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[5] && x_s1_auto_in_0_d_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[6] && x_s1_auto_in_0_d_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[7] && x_s1_auto_in_0_d_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[8] && x_s1_auto_in_0_d_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[9] && x_s1_auto_in_0_d_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[10] && x_s1_auto_in_0_d_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[11] && x_s1_auto_in_0_d_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[12] && x_s1_auto_in_0_d_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[13] && x_s1_auto_in_0_d_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[14] && x_s1_auto_in_0_d_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[15] && x_s1_auto_in_0_d_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[16] && x_s1_auto_in_0_d_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[17] && x_s1_auto_in_0_d_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[18] && x_s1_auto_in_0_d_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[19] && x_s1_auto_in_0_d_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[20] && x_s1_auto_in_0_d_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[21] && x_s1_auto_in_0_d_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[22] && x_s1_auto_in_0_d_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[23] && x_s1_auto_in_0_d_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[24] && x_s1_auto_in_0_d_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[25] && x_s1_auto_in_0_d_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[26] && x_s1_auto_in_0_d_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[27] && x_s1_auto_in_0_d_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[28] && x_s1_auto_in_0_d_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[29] && x_s1_auto_in_0_d_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[30] && x_s1_auto_in_0_d_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[31] && x_s1_auto_in_0_d_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[32] && x_s1_auto_in_0_d_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[33] && x_s1_auto_in_0_d_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[34] && x_s1_auto_in_0_d_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[35] && x_s1_auto_in_0_d_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[36] && x_s1_auto_in_0_d_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[37] && x_s1_auto_in_0_d_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[38] && x_s1_auto_in_0_d_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[39] && x_s1_auto_in_0_d_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[40] && x_s1_auto_in_0_d_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[41] && x_s1_auto_in_0_d_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[42] && x_s1_auto_in_0_d_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[43] && x_s1_auto_in_0_d_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[44] && x_s1_auto_in_0_d_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[45] && x_s1_auto_in_0_d_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[46] && x_s1_auto_in_0_d_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[47] && x_s1_auto_in_0_d_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[48] && x_s1_auto_in_0_d_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[49] && x_s1_auto_in_0_d_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[50] && x_s1_auto_in_0_d_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[51] && x_s1_auto_in_0_d_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[52] && x_s1_auto_in_0_d_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[53] && x_s1_auto_in_0_d_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[54] && x_s1_auto_in_0_d_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[55] && x_s1_auto_in_0_d_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[56] && x_s1_auto_in_0_d_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[57] && x_s1_auto_in_0_d_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[58] && x_s1_auto_in_0_d_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[59] && x_s1_auto_in_0_d_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[60] && x_s1_auto_in_0_d_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[61] && x_s1_auto_in_0_d_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[62] && x_s1_auto_in_0_d_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[63] && x_s1_auto_in_0_d_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[64] && x_s1_auto_in_0_d_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[65] && x_s1_auto_in_0_d_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[66] && x_s1_auto_in_0_d_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[67] && x_s1_auto_in_0_d_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[68] && x_s1_auto_in_0_d_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[69] && x_s1_auto_in_0_d_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[70] && x_s1_auto_in_0_d_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[71] && x_s1_auto_in_0_d_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[72] && x_s1_auto_in_0_d_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[73] && x_s1_auto_in_0_d_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[74] && x_s1_auto_in_0_d_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[75] && x_s1_auto_in_0_d_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[76] && x_s1_auto_in_0_d_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[77] && x_s1_auto_in_0_d_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[78] && x_s1_auto_in_0_d_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[79] && x_s1_auto_in_0_d_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[80] && x_s1_auto_in_0_d_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[81] && x_s1_auto_in_0_d_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[82] && x_s1_auto_in_0_d_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[83] && x_s1_auto_in_0_d_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[84] && x_s1_auto_in_0_d_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[85] && x_s1_auto_in_0_d_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[86] && x_s1_auto_in_0_d_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[87] && x_s1_auto_in_0_d_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[88] && x_s1_auto_in_0_d_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[89] && x_s1_auto_in_0_d_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[90] && x_s1_auto_in_0_d_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[91] && x_s1_auto_in_0_d_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[92] && x_s1_auto_in_0_d_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[93] && x_s1_auto_in_0_d_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[94] && x_s1_auto_in_0_d_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[95] && x_s1_auto_in_0_d_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[96] && x_s1_auto_in_0_d_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[97] && x_s1_auto_in_0_d_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[98] && x_s1_auto_in_0_d_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[99] && x_s1_auto_in_0_d_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[100] && x_s1_auto_in_0_d_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[101] && x_s1_auto_in_0_d_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[102] && x_s1_auto_in_0_d_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[103] && x_s1_auto_in_0_d_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[104] && x_s1_auto_in_0_d_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[105] && x_s1_auto_in_0_d_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[106] && x_s1_auto_in_0_d_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[107] && x_s1_auto_in_0_d_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[108] && x_s1_auto_in_0_d_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[109] && x_s1_auto_in_0_d_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[110] && x_s1_auto_in_0_d_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[111] && x_s1_auto_in_0_d_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[112] && x_s1_auto_in_0_d_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[113] && x_s1_auto_in_0_d_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[114] && x_s1_auto_in_0_d_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[115] && x_s1_auto_in_0_d_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[116] && x_s1_auto_in_0_d_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[117] && x_s1_auto_in_0_d_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[118] && x_s1_auto_in_0_d_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[119] && x_s1_auto_in_0_d_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[120] && x_s1_auto_in_0_d_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[121] && x_s1_auto_in_0_d_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[122] && x_s1_auto_in_0_d_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[123] && x_s1_auto_in_0_d_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[124] && x_s1_auto_in_0_d_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[125] && x_s1_auto_in_0_d_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[126] && x_s1_auto_in_0_d_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[127] && x_s1_auto_in_0_d_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[128] && x_s1_auto_in_0_d_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[129] && x_s1_auto_in_0_d_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[130] && x_s1_auto_in_0_d_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[131] && x_s1_auto_in_0_d_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[132] && x_s1_auto_in_0_d_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[133] && x_s1_auto_in_0_d_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[134] && x_s1_auto_in_0_d_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[135] && x_s1_auto_in_0_d_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[136] && x_s1_auto_in_0_d_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[137] && x_s1_auto_in_0_d_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[138] && x_s1_auto_in_0_d_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[139] && x_s1_auto_in_0_d_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[140] && x_s1_auto_in_0_d_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[141] && x_s1_auto_in_0_d_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[142] && x_s1_auto_in_0_d_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[143] && x_s1_auto_in_0_d_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[144] && x_s1_auto_in_0_d_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[145] && x_s1_auto_in_0_d_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[146] && x_s1_auto_in_0_d_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[147] && x_s1_auto_in_0_d_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[148] && x_s1_auto_in_0_d_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[149] && x_s1_auto_in_0_d_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[150] && x_s1_auto_in_0_d_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[151] && x_s1_auto_in_0_d_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[152] && x_s1_auto_in_0_d_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[153] && x_s1_auto_in_0_d_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[154] && x_s1_auto_in_0_d_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[155] && x_s1_auto_in_0_d_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[156] && x_s1_auto_in_0_d_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[157] && x_s1_auto_in_0_d_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[158] && x_s1_auto_in_0_d_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[159] && x_s1_auto_in_0_d_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[160] && x_s1_auto_in_0_d_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[161] && x_s1_auto_in_0_d_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[162] && x_s1_auto_in_0_d_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[163] && x_s1_auto_in_0_d_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[164] && x_s1_auto_in_0_d_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[165] && x_s1_auto_in_0_d_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[166] && x_s1_auto_in_0_d_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[167] && x_s1_auto_in_0_d_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[168] && x_s1_auto_in_0_d_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[169] && x_s1_auto_in_0_d_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[170] && x_s1_auto_in_0_d_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[171] && x_s1_auto_in_0_d_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[172] && x_s1_auto_in_0_d_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[173] && x_s1_auto_in_0_d_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[174] && x_s1_auto_in_0_d_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[175] && x_s1_auto_in_0_d_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[176] && x_s1_auto_in_0_d_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[177] && x_s1_auto_in_0_d_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[178] && x_s1_auto_in_0_d_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[179] && x_s1_auto_in_0_d_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[180] && x_s1_auto_in_0_d_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[181] && x_s1_auto_in_0_d_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[182] && x_s1_auto_in_0_d_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[183] && x_s1_auto_in_0_d_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[184] && x_s1_auto_in_0_d_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[185] && x_s1_auto_in_0_d_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[186] && x_s1_auto_in_0_d_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[187] && x_s1_auto_in_0_d_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[188] && x_s1_auto_in_0_d_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[189] && x_s1_auto_in_0_d_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[190] && x_s1_auto_in_0_d_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[191] && x_s1_auto_in_0_d_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[192] && x_s1_auto_in_0_d_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[193] && x_s1_auto_in_0_d_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[194] && x_s1_auto_in_0_d_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[195] && x_s1_auto_in_0_d_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[196] && x_s1_auto_in_0_d_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[197] && x_s1_auto_in_0_d_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[198] && x_s1_auto_in_0_d_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[199] && x_s1_auto_in_0_d_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[200] && x_s1_auto_in_0_d_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[201] && x_s1_auto_in_0_d_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[202] && x_s1_auto_in_0_d_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[203] && x_s1_auto_in_0_d_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[204] && x_s1_auto_in_0_d_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[205] && x_s1_auto_in_0_d_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[206] && x_s1_auto_in_0_d_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[207] && x_s1_auto_in_0_d_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[208] && x_s1_auto_in_0_d_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[209] && x_s1_auto_in_0_d_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[210] && x_s1_auto_in_0_d_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[211] && x_s1_auto_in_0_d_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[212] && x_s1_auto_in_0_d_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[213] && x_s1_auto_in_0_d_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[214] && x_s1_auto_in_0_d_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[215] && x_s1_auto_in_0_d_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[216] && x_s1_auto_in_0_d_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[217] && x_s1_auto_in_0_d_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[218] && x_s1_auto_in_0_d_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[219] && x_s1_auto_in_0_d_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[220] && x_s1_auto_in_0_d_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[221] && x_s1_auto_in_0_d_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[222] && x_s1_auto_in_0_d_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[223] && x_s1_auto_in_0_d_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[224] && x_s1_auto_in_0_d_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[225] && x_s1_auto_in_0_d_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[226] && x_s1_auto_in_0_d_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[227] && x_s1_auto_in_0_d_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[228] && x_s1_auto_in_0_d_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[229] && x_s1_auto_in_0_d_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[230] && x_s1_auto_in_0_d_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[231] && x_s1_auto_in_0_d_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[232] && x_s1_auto_in_0_d_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[233] && x_s1_auto_in_0_d_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[234] && x_s1_auto_in_0_d_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[235] && x_s1_auto_in_0_d_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[236] && x_s1_auto_in_0_d_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[237] && x_s1_auto_in_0_d_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[238] && x_s1_auto_in_0_d_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[239] && x_s1_auto_in_0_d_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[240] && x_s1_auto_in_0_d_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[241] && x_s1_auto_in_0_d_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[242] && x_s1_auto_in_0_d_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[243] && x_s1_auto_in_0_d_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[244] && x_s1_auto_in_0_d_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[245] && x_s1_auto_in_0_d_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[246] && x_s1_auto_in_0_d_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[247] && x_s1_auto_in_0_d_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[248] && x_s1_auto_in_0_d_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[249] && x_s1_auto_in_0_d_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[250] && x_s1_auto_in_0_d_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[251] && x_s1_auto_in_0_d_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[252] && x_s1_auto_in_0_d_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[253] && x_s1_auto_in_0_d_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[254] && x_s1_auto_in_0_d_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_data[255] && x_s1_auto_in_0_d_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_d_bits_corrupt && x_s1_auto_in_0_d_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_d_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_in_0_e_ready && x_s1_auto_in_0_e_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_in_0_e_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_valid && x_s1_auto_out_3_a_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_opcode[0] && x_s1_auto_out_3_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_opcode[1] && x_s1_auto_out_3_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_opcode[2] && x_s1_auto_out_3_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_opcode[3] && x_s1_auto_out_3_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_param[0] && x_s1_auto_out_3_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_param[1] && x_s1_auto_out_3_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_param[2] && x_s1_auto_out_3_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_size[0] && x_s1_auto_out_3_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_size[1] && x_s1_auto_out_3_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_size[2] && x_s1_auto_out_3_a_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[0] && x_s1_auto_out_3_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[1] && x_s1_auto_out_3_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[2] && x_s1_auto_out_3_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[3] && x_s1_auto_out_3_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[4] && x_s1_auto_out_3_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[5] && x_s1_auto_out_3_a_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_source[6] && x_s1_auto_out_3_a_bits_source[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_source[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[0] && x_s1_auto_out_3_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[1] && x_s1_auto_out_3_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[2] && x_s1_auto_out_3_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[3] && x_s1_auto_out_3_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[4] && x_s1_auto_out_3_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[5] && x_s1_auto_out_3_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[6] && x_s1_auto_out_3_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[7] && x_s1_auto_out_3_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[8] && x_s1_auto_out_3_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[9] && x_s1_auto_out_3_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[10] && x_s1_auto_out_3_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[11] && x_s1_auto_out_3_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[12] && x_s1_auto_out_3_a_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[13] && x_s1_auto_out_3_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[14] && x_s1_auto_out_3_a_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[15] && x_s1_auto_out_3_a_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[16] && x_s1_auto_out_3_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[17] && x_s1_auto_out_3_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[18] && x_s1_auto_out_3_a_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[19] && x_s1_auto_out_3_a_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[20] && x_s1_auto_out_3_a_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[21] && x_s1_auto_out_3_a_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[22] && x_s1_auto_out_3_a_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[23] && x_s1_auto_out_3_a_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[24] && x_s1_auto_out_3_a_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[25] && x_s1_auto_out_3_a_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[26] && x_s1_auto_out_3_a_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[27] && x_s1_auto_out_3_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[28] && x_s1_auto_out_3_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[29] && x_s1_auto_out_3_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[30] && x_s1_auto_out_3_a_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[31] && x_s1_auto_out_3_a_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[32] && x_s1_auto_out_3_a_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[33] && x_s1_auto_out_3_a_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[34] && x_s1_auto_out_3_a_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[35] && x_s1_auto_out_3_a_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[36] && x_s1_auto_out_3_a_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[37] && x_s1_auto_out_3_a_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[38] && x_s1_auto_out_3_a_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[39] && x_s1_auto_out_3_a_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[40] && x_s1_auto_out_3_a_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[41] && x_s1_auto_out_3_a_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[42] && x_s1_auto_out_3_a_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[43] && x_s1_auto_out_3_a_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[44] && x_s1_auto_out_3_a_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[45] && x_s1_auto_out_3_a_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[46] && x_s1_auto_out_3_a_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_address[47] && x_s1_auto_out_3_a_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_reqSource[0] && x_s1_auto_out_3_a_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_reqSource[1] && x_s1_auto_out_3_a_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_reqSource[2] && x_s1_auto_out_3_a_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_reqSource[3] && x_s1_auto_out_3_a_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_reqSource[4] && x_s1_auto_out_3_a_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_alias[0] && x_s1_auto_out_3_a_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_alias[1] && x_s1_auto_out_3_a_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[0] && x_s1_auto_out_3_a_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[1] && x_s1_auto_out_3_a_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[2] && x_s1_auto_out_3_a_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[3] && x_s1_auto_out_3_a_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[4] && x_s1_auto_out_3_a_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[5] && x_s1_auto_out_3_a_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[6] && x_s1_auto_out_3_a_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[7] && x_s1_auto_out_3_a_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[8] && x_s1_auto_out_3_a_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[9] && x_s1_auto_out_3_a_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[10] && x_s1_auto_out_3_a_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[11] && x_s1_auto_out_3_a_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[12] && x_s1_auto_out_3_a_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[13] && x_s1_auto_out_3_a_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[14] && x_s1_auto_out_3_a_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[15] && x_s1_auto_out_3_a_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[16] && x_s1_auto_out_3_a_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[17] && x_s1_auto_out_3_a_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[18] && x_s1_auto_out_3_a_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[19] && x_s1_auto_out_3_a_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[20] && x_s1_auto_out_3_a_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[21] && x_s1_auto_out_3_a_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[22] && x_s1_auto_out_3_a_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[23] && x_s1_auto_out_3_a_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[24] && x_s1_auto_out_3_a_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[25] && x_s1_auto_out_3_a_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[26] && x_s1_auto_out_3_a_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[27] && x_s1_auto_out_3_a_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[28] && x_s1_auto_out_3_a_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[29] && x_s1_auto_out_3_a_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[30] && x_s1_auto_out_3_a_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[31] && x_s1_auto_out_3_a_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[32] && x_s1_auto_out_3_a_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[33] && x_s1_auto_out_3_a_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[34] && x_s1_auto_out_3_a_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[35] && x_s1_auto_out_3_a_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[36] && x_s1_auto_out_3_a_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[37] && x_s1_auto_out_3_a_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[38] && x_s1_auto_out_3_a_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[39] && x_s1_auto_out_3_a_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[40] && x_s1_auto_out_3_a_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[41] && x_s1_auto_out_3_a_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[42] && x_s1_auto_out_3_a_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_vaddr[43] && x_s1_auto_out_3_a_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_user_needHint && x_s1_auto_out_3_a_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_echo_isKeyword && x_s1_auto_out_3_a_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[0] && x_s1_auto_out_3_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[1] && x_s1_auto_out_3_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[2] && x_s1_auto_out_3_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[3] && x_s1_auto_out_3_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[4] && x_s1_auto_out_3_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[5] && x_s1_auto_out_3_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[6] && x_s1_auto_out_3_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[7] && x_s1_auto_out_3_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[8] && x_s1_auto_out_3_a_bits_mask[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[9] && x_s1_auto_out_3_a_bits_mask[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[10] && x_s1_auto_out_3_a_bits_mask[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[11] && x_s1_auto_out_3_a_bits_mask[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[12] && x_s1_auto_out_3_a_bits_mask[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[13] && x_s1_auto_out_3_a_bits_mask[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[14] && x_s1_auto_out_3_a_bits_mask[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[15] && x_s1_auto_out_3_a_bits_mask[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[16] && x_s1_auto_out_3_a_bits_mask[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[17] && x_s1_auto_out_3_a_bits_mask[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[18] && x_s1_auto_out_3_a_bits_mask[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[19] && x_s1_auto_out_3_a_bits_mask[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[20] && x_s1_auto_out_3_a_bits_mask[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[21] && x_s1_auto_out_3_a_bits_mask[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[22] && x_s1_auto_out_3_a_bits_mask[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[23] && x_s1_auto_out_3_a_bits_mask[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[24] && x_s1_auto_out_3_a_bits_mask[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[25] && x_s1_auto_out_3_a_bits_mask[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[26] && x_s1_auto_out_3_a_bits_mask[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[27] && x_s1_auto_out_3_a_bits_mask[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[28] && x_s1_auto_out_3_a_bits_mask[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[29] && x_s1_auto_out_3_a_bits_mask[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[30] && x_s1_auto_out_3_a_bits_mask[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_mask[31] && x_s1_auto_out_3_a_bits_mask[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_mask[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[0] && x_s1_auto_out_3_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[1] && x_s1_auto_out_3_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[2] && x_s1_auto_out_3_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[3] && x_s1_auto_out_3_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[4] && x_s1_auto_out_3_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[5] && x_s1_auto_out_3_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[6] && x_s1_auto_out_3_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[7] && x_s1_auto_out_3_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[8] && x_s1_auto_out_3_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[9] && x_s1_auto_out_3_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[10] && x_s1_auto_out_3_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[11] && x_s1_auto_out_3_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[12] && x_s1_auto_out_3_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[13] && x_s1_auto_out_3_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[14] && x_s1_auto_out_3_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[15] && x_s1_auto_out_3_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[16] && x_s1_auto_out_3_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[17] && x_s1_auto_out_3_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[18] && x_s1_auto_out_3_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[19] && x_s1_auto_out_3_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[20] && x_s1_auto_out_3_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[21] && x_s1_auto_out_3_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[22] && x_s1_auto_out_3_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[23] && x_s1_auto_out_3_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[24] && x_s1_auto_out_3_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[25] && x_s1_auto_out_3_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[26] && x_s1_auto_out_3_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[27] && x_s1_auto_out_3_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[28] && x_s1_auto_out_3_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[29] && x_s1_auto_out_3_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[30] && x_s1_auto_out_3_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[31] && x_s1_auto_out_3_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[32] && x_s1_auto_out_3_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[33] && x_s1_auto_out_3_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[34] && x_s1_auto_out_3_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[35] && x_s1_auto_out_3_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[36] && x_s1_auto_out_3_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[37] && x_s1_auto_out_3_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[38] && x_s1_auto_out_3_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[39] && x_s1_auto_out_3_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[40] && x_s1_auto_out_3_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[41] && x_s1_auto_out_3_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[42] && x_s1_auto_out_3_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[43] && x_s1_auto_out_3_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[44] && x_s1_auto_out_3_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[45] && x_s1_auto_out_3_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[46] && x_s1_auto_out_3_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[47] && x_s1_auto_out_3_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[48] && x_s1_auto_out_3_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[49] && x_s1_auto_out_3_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[50] && x_s1_auto_out_3_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[51] && x_s1_auto_out_3_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[52] && x_s1_auto_out_3_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[53] && x_s1_auto_out_3_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[54] && x_s1_auto_out_3_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[55] && x_s1_auto_out_3_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[56] && x_s1_auto_out_3_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[57] && x_s1_auto_out_3_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[58] && x_s1_auto_out_3_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[59] && x_s1_auto_out_3_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[60] && x_s1_auto_out_3_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[61] && x_s1_auto_out_3_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[62] && x_s1_auto_out_3_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[63] && x_s1_auto_out_3_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[64] && x_s1_auto_out_3_a_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[65] && x_s1_auto_out_3_a_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[66] && x_s1_auto_out_3_a_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[67] && x_s1_auto_out_3_a_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[68] && x_s1_auto_out_3_a_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[69] && x_s1_auto_out_3_a_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[70] && x_s1_auto_out_3_a_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[71] && x_s1_auto_out_3_a_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[72] && x_s1_auto_out_3_a_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[73] && x_s1_auto_out_3_a_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[74] && x_s1_auto_out_3_a_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[75] && x_s1_auto_out_3_a_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[76] && x_s1_auto_out_3_a_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[77] && x_s1_auto_out_3_a_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[78] && x_s1_auto_out_3_a_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[79] && x_s1_auto_out_3_a_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[80] && x_s1_auto_out_3_a_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[81] && x_s1_auto_out_3_a_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[82] && x_s1_auto_out_3_a_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[83] && x_s1_auto_out_3_a_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[84] && x_s1_auto_out_3_a_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[85] && x_s1_auto_out_3_a_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[86] && x_s1_auto_out_3_a_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[87] && x_s1_auto_out_3_a_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[88] && x_s1_auto_out_3_a_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[89] && x_s1_auto_out_3_a_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[90] && x_s1_auto_out_3_a_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[91] && x_s1_auto_out_3_a_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[92] && x_s1_auto_out_3_a_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[93] && x_s1_auto_out_3_a_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[94] && x_s1_auto_out_3_a_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[95] && x_s1_auto_out_3_a_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[96] && x_s1_auto_out_3_a_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[97] && x_s1_auto_out_3_a_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[98] && x_s1_auto_out_3_a_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[99] && x_s1_auto_out_3_a_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[100] && x_s1_auto_out_3_a_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[101] && x_s1_auto_out_3_a_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[102] && x_s1_auto_out_3_a_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[103] && x_s1_auto_out_3_a_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[104] && x_s1_auto_out_3_a_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[105] && x_s1_auto_out_3_a_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[106] && x_s1_auto_out_3_a_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[107] && x_s1_auto_out_3_a_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[108] && x_s1_auto_out_3_a_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[109] && x_s1_auto_out_3_a_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[110] && x_s1_auto_out_3_a_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[111] && x_s1_auto_out_3_a_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[112] && x_s1_auto_out_3_a_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[113] && x_s1_auto_out_3_a_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[114] && x_s1_auto_out_3_a_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[115] && x_s1_auto_out_3_a_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[116] && x_s1_auto_out_3_a_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[117] && x_s1_auto_out_3_a_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[118] && x_s1_auto_out_3_a_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[119] && x_s1_auto_out_3_a_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[120] && x_s1_auto_out_3_a_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[121] && x_s1_auto_out_3_a_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[122] && x_s1_auto_out_3_a_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[123] && x_s1_auto_out_3_a_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[124] && x_s1_auto_out_3_a_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[125] && x_s1_auto_out_3_a_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[126] && x_s1_auto_out_3_a_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[127] && x_s1_auto_out_3_a_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[128] && x_s1_auto_out_3_a_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[129] && x_s1_auto_out_3_a_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[130] && x_s1_auto_out_3_a_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[131] && x_s1_auto_out_3_a_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[132] && x_s1_auto_out_3_a_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[133] && x_s1_auto_out_3_a_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[134] && x_s1_auto_out_3_a_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[135] && x_s1_auto_out_3_a_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[136] && x_s1_auto_out_3_a_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[137] && x_s1_auto_out_3_a_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[138] && x_s1_auto_out_3_a_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[139] && x_s1_auto_out_3_a_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[140] && x_s1_auto_out_3_a_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[141] && x_s1_auto_out_3_a_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[142] && x_s1_auto_out_3_a_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[143] && x_s1_auto_out_3_a_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[144] && x_s1_auto_out_3_a_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[145] && x_s1_auto_out_3_a_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[146] && x_s1_auto_out_3_a_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[147] && x_s1_auto_out_3_a_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[148] && x_s1_auto_out_3_a_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[149] && x_s1_auto_out_3_a_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[150] && x_s1_auto_out_3_a_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[151] && x_s1_auto_out_3_a_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[152] && x_s1_auto_out_3_a_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[153] && x_s1_auto_out_3_a_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[154] && x_s1_auto_out_3_a_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[155] && x_s1_auto_out_3_a_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[156] && x_s1_auto_out_3_a_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[157] && x_s1_auto_out_3_a_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[158] && x_s1_auto_out_3_a_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[159] && x_s1_auto_out_3_a_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[160] && x_s1_auto_out_3_a_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[161] && x_s1_auto_out_3_a_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[162] && x_s1_auto_out_3_a_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[163] && x_s1_auto_out_3_a_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[164] && x_s1_auto_out_3_a_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[165] && x_s1_auto_out_3_a_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[166] && x_s1_auto_out_3_a_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[167] && x_s1_auto_out_3_a_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[168] && x_s1_auto_out_3_a_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[169] && x_s1_auto_out_3_a_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[170] && x_s1_auto_out_3_a_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[171] && x_s1_auto_out_3_a_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[172] && x_s1_auto_out_3_a_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[173] && x_s1_auto_out_3_a_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[174] && x_s1_auto_out_3_a_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[175] && x_s1_auto_out_3_a_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[176] && x_s1_auto_out_3_a_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[177] && x_s1_auto_out_3_a_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[178] && x_s1_auto_out_3_a_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[179] && x_s1_auto_out_3_a_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[180] && x_s1_auto_out_3_a_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[181] && x_s1_auto_out_3_a_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[182] && x_s1_auto_out_3_a_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[183] && x_s1_auto_out_3_a_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[184] && x_s1_auto_out_3_a_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[185] && x_s1_auto_out_3_a_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[186] && x_s1_auto_out_3_a_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[187] && x_s1_auto_out_3_a_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[188] && x_s1_auto_out_3_a_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[189] && x_s1_auto_out_3_a_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[190] && x_s1_auto_out_3_a_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[191] && x_s1_auto_out_3_a_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[192] && x_s1_auto_out_3_a_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[193] && x_s1_auto_out_3_a_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[194] && x_s1_auto_out_3_a_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[195] && x_s1_auto_out_3_a_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[196] && x_s1_auto_out_3_a_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[197] && x_s1_auto_out_3_a_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[198] && x_s1_auto_out_3_a_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[199] && x_s1_auto_out_3_a_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[200] && x_s1_auto_out_3_a_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[201] && x_s1_auto_out_3_a_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[202] && x_s1_auto_out_3_a_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[203] && x_s1_auto_out_3_a_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[204] && x_s1_auto_out_3_a_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[205] && x_s1_auto_out_3_a_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[206] && x_s1_auto_out_3_a_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[207] && x_s1_auto_out_3_a_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[208] && x_s1_auto_out_3_a_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[209] && x_s1_auto_out_3_a_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[210] && x_s1_auto_out_3_a_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[211] && x_s1_auto_out_3_a_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[212] && x_s1_auto_out_3_a_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[213] && x_s1_auto_out_3_a_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[214] && x_s1_auto_out_3_a_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[215] && x_s1_auto_out_3_a_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[216] && x_s1_auto_out_3_a_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[217] && x_s1_auto_out_3_a_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[218] && x_s1_auto_out_3_a_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[219] && x_s1_auto_out_3_a_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[220] && x_s1_auto_out_3_a_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[221] && x_s1_auto_out_3_a_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[222] && x_s1_auto_out_3_a_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[223] && x_s1_auto_out_3_a_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[224] && x_s1_auto_out_3_a_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[225] && x_s1_auto_out_3_a_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[226] && x_s1_auto_out_3_a_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[227] && x_s1_auto_out_3_a_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[228] && x_s1_auto_out_3_a_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[229] && x_s1_auto_out_3_a_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[230] && x_s1_auto_out_3_a_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[231] && x_s1_auto_out_3_a_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[232] && x_s1_auto_out_3_a_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[233] && x_s1_auto_out_3_a_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[234] && x_s1_auto_out_3_a_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[235] && x_s1_auto_out_3_a_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[236] && x_s1_auto_out_3_a_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[237] && x_s1_auto_out_3_a_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[238] && x_s1_auto_out_3_a_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[239] && x_s1_auto_out_3_a_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[240] && x_s1_auto_out_3_a_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[241] && x_s1_auto_out_3_a_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[242] && x_s1_auto_out_3_a_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[243] && x_s1_auto_out_3_a_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[244] && x_s1_auto_out_3_a_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[245] && x_s1_auto_out_3_a_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[246] && x_s1_auto_out_3_a_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[247] && x_s1_auto_out_3_a_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[248] && x_s1_auto_out_3_a_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[249] && x_s1_auto_out_3_a_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[250] && x_s1_auto_out_3_a_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[251] && x_s1_auto_out_3_a_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[252] && x_s1_auto_out_3_a_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[253] && x_s1_auto_out_3_a_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[254] && x_s1_auto_out_3_a_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_data[255] && x_s1_auto_out_3_a_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_a_bits_corrupt && x_s1_auto_out_3_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_b_ready && x_s1_auto_out_3_b_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_b_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_valid && x_s1_auto_out_3_c_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_opcode[0] && x_s1_auto_out_3_c_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_opcode[1] && x_s1_auto_out_3_c_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_opcode[2] && x_s1_auto_out_3_c_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_param[0] && x_s1_auto_out_3_c_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_param[1] && x_s1_auto_out_3_c_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_param[2] && x_s1_auto_out_3_c_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_size[0] && x_s1_auto_out_3_c_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_size[1] && x_s1_auto_out_3_c_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_size[2] && x_s1_auto_out_3_c_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[0] && x_s1_auto_out_3_c_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[1] && x_s1_auto_out_3_c_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[2] && x_s1_auto_out_3_c_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[3] && x_s1_auto_out_3_c_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[4] && x_s1_auto_out_3_c_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_source[5] && x_s1_auto_out_3_c_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[0] && x_s1_auto_out_3_c_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[1] && x_s1_auto_out_3_c_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[2] && x_s1_auto_out_3_c_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[3] && x_s1_auto_out_3_c_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[4] && x_s1_auto_out_3_c_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[5] && x_s1_auto_out_3_c_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[6] && x_s1_auto_out_3_c_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[7] && x_s1_auto_out_3_c_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[8] && x_s1_auto_out_3_c_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[9] && x_s1_auto_out_3_c_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[10] && x_s1_auto_out_3_c_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[11] && x_s1_auto_out_3_c_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[12] && x_s1_auto_out_3_c_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[13] && x_s1_auto_out_3_c_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[14] && x_s1_auto_out_3_c_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[15] && x_s1_auto_out_3_c_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[16] && x_s1_auto_out_3_c_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[17] && x_s1_auto_out_3_c_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[18] && x_s1_auto_out_3_c_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[19] && x_s1_auto_out_3_c_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[20] && x_s1_auto_out_3_c_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[21] && x_s1_auto_out_3_c_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[22] && x_s1_auto_out_3_c_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[23] && x_s1_auto_out_3_c_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[24] && x_s1_auto_out_3_c_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[25] && x_s1_auto_out_3_c_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[26] && x_s1_auto_out_3_c_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[27] && x_s1_auto_out_3_c_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[28] && x_s1_auto_out_3_c_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[29] && x_s1_auto_out_3_c_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[30] && x_s1_auto_out_3_c_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[31] && x_s1_auto_out_3_c_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[32] && x_s1_auto_out_3_c_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[33] && x_s1_auto_out_3_c_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[34] && x_s1_auto_out_3_c_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[35] && x_s1_auto_out_3_c_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[36] && x_s1_auto_out_3_c_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[37] && x_s1_auto_out_3_c_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[38] && x_s1_auto_out_3_c_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[39] && x_s1_auto_out_3_c_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[40] && x_s1_auto_out_3_c_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[41] && x_s1_auto_out_3_c_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[42] && x_s1_auto_out_3_c_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[43] && x_s1_auto_out_3_c_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[44] && x_s1_auto_out_3_c_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[45] && x_s1_auto_out_3_c_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[46] && x_s1_auto_out_3_c_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_address[47] && x_s1_auto_out_3_c_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_reqSource[0] && x_s1_auto_out_3_c_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_reqSource[1] && x_s1_auto_out_3_c_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_reqSource[2] && x_s1_auto_out_3_c_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_reqSource[3] && x_s1_auto_out_3_c_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_reqSource[4] && x_s1_auto_out_3_c_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_alias[0] && x_s1_auto_out_3_c_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_alias[1] && x_s1_auto_out_3_c_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[0] && x_s1_auto_out_3_c_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[1] && x_s1_auto_out_3_c_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[2] && x_s1_auto_out_3_c_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[3] && x_s1_auto_out_3_c_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[4] && x_s1_auto_out_3_c_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[5] && x_s1_auto_out_3_c_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[6] && x_s1_auto_out_3_c_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[7] && x_s1_auto_out_3_c_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[8] && x_s1_auto_out_3_c_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[9] && x_s1_auto_out_3_c_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[10] && x_s1_auto_out_3_c_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[11] && x_s1_auto_out_3_c_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[12] && x_s1_auto_out_3_c_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[13] && x_s1_auto_out_3_c_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[14] && x_s1_auto_out_3_c_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[15] && x_s1_auto_out_3_c_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[16] && x_s1_auto_out_3_c_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[17] && x_s1_auto_out_3_c_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[18] && x_s1_auto_out_3_c_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[19] && x_s1_auto_out_3_c_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[20] && x_s1_auto_out_3_c_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[21] && x_s1_auto_out_3_c_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[22] && x_s1_auto_out_3_c_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[23] && x_s1_auto_out_3_c_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[24] && x_s1_auto_out_3_c_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[25] && x_s1_auto_out_3_c_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[26] && x_s1_auto_out_3_c_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[27] && x_s1_auto_out_3_c_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[28] && x_s1_auto_out_3_c_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[29] && x_s1_auto_out_3_c_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[30] && x_s1_auto_out_3_c_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[31] && x_s1_auto_out_3_c_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[32] && x_s1_auto_out_3_c_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[33] && x_s1_auto_out_3_c_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[34] && x_s1_auto_out_3_c_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[35] && x_s1_auto_out_3_c_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[36] && x_s1_auto_out_3_c_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[37] && x_s1_auto_out_3_c_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[38] && x_s1_auto_out_3_c_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[39] && x_s1_auto_out_3_c_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[40] && x_s1_auto_out_3_c_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[41] && x_s1_auto_out_3_c_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[42] && x_s1_auto_out_3_c_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_vaddr[43] && x_s1_auto_out_3_c_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_user_needHint && x_s1_auto_out_3_c_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_echo_isKeyword && x_s1_auto_out_3_c_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[0] && x_s1_auto_out_3_c_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[1] && x_s1_auto_out_3_c_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[2] && x_s1_auto_out_3_c_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[3] && x_s1_auto_out_3_c_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[4] && x_s1_auto_out_3_c_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[5] && x_s1_auto_out_3_c_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[6] && x_s1_auto_out_3_c_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[7] && x_s1_auto_out_3_c_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[8] && x_s1_auto_out_3_c_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[9] && x_s1_auto_out_3_c_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[10] && x_s1_auto_out_3_c_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[11] && x_s1_auto_out_3_c_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[12] && x_s1_auto_out_3_c_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[13] && x_s1_auto_out_3_c_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[14] && x_s1_auto_out_3_c_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[15] && x_s1_auto_out_3_c_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[16] && x_s1_auto_out_3_c_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[17] && x_s1_auto_out_3_c_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[18] && x_s1_auto_out_3_c_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[19] && x_s1_auto_out_3_c_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[20] && x_s1_auto_out_3_c_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[21] && x_s1_auto_out_3_c_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[22] && x_s1_auto_out_3_c_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[23] && x_s1_auto_out_3_c_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[24] && x_s1_auto_out_3_c_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[25] && x_s1_auto_out_3_c_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[26] && x_s1_auto_out_3_c_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[27] && x_s1_auto_out_3_c_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[28] && x_s1_auto_out_3_c_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[29] && x_s1_auto_out_3_c_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[30] && x_s1_auto_out_3_c_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[31] && x_s1_auto_out_3_c_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[32] && x_s1_auto_out_3_c_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[33] && x_s1_auto_out_3_c_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[34] && x_s1_auto_out_3_c_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[35] && x_s1_auto_out_3_c_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[36] && x_s1_auto_out_3_c_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[37] && x_s1_auto_out_3_c_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[38] && x_s1_auto_out_3_c_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[39] && x_s1_auto_out_3_c_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[40] && x_s1_auto_out_3_c_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[41] && x_s1_auto_out_3_c_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[42] && x_s1_auto_out_3_c_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[43] && x_s1_auto_out_3_c_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[44] && x_s1_auto_out_3_c_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[45] && x_s1_auto_out_3_c_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[46] && x_s1_auto_out_3_c_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[47] && x_s1_auto_out_3_c_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[48] && x_s1_auto_out_3_c_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[49] && x_s1_auto_out_3_c_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[50] && x_s1_auto_out_3_c_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[51] && x_s1_auto_out_3_c_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[52] && x_s1_auto_out_3_c_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[53] && x_s1_auto_out_3_c_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[54] && x_s1_auto_out_3_c_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[55] && x_s1_auto_out_3_c_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[56] && x_s1_auto_out_3_c_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[57] && x_s1_auto_out_3_c_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[58] && x_s1_auto_out_3_c_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[59] && x_s1_auto_out_3_c_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[60] && x_s1_auto_out_3_c_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[61] && x_s1_auto_out_3_c_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[62] && x_s1_auto_out_3_c_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[63] && x_s1_auto_out_3_c_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[64] && x_s1_auto_out_3_c_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[65] && x_s1_auto_out_3_c_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[66] && x_s1_auto_out_3_c_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[67] && x_s1_auto_out_3_c_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[68] && x_s1_auto_out_3_c_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[69] && x_s1_auto_out_3_c_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[70] && x_s1_auto_out_3_c_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[71] && x_s1_auto_out_3_c_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[72] && x_s1_auto_out_3_c_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[73] && x_s1_auto_out_3_c_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[74] && x_s1_auto_out_3_c_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[75] && x_s1_auto_out_3_c_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[76] && x_s1_auto_out_3_c_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[77] && x_s1_auto_out_3_c_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[78] && x_s1_auto_out_3_c_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[79] && x_s1_auto_out_3_c_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[80] && x_s1_auto_out_3_c_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[81] && x_s1_auto_out_3_c_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[82] && x_s1_auto_out_3_c_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[83] && x_s1_auto_out_3_c_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[84] && x_s1_auto_out_3_c_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[85] && x_s1_auto_out_3_c_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[86] && x_s1_auto_out_3_c_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[87] && x_s1_auto_out_3_c_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[88] && x_s1_auto_out_3_c_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[89] && x_s1_auto_out_3_c_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[90] && x_s1_auto_out_3_c_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[91] && x_s1_auto_out_3_c_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[92] && x_s1_auto_out_3_c_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[93] && x_s1_auto_out_3_c_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[94] && x_s1_auto_out_3_c_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[95] && x_s1_auto_out_3_c_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[96] && x_s1_auto_out_3_c_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[97] && x_s1_auto_out_3_c_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[98] && x_s1_auto_out_3_c_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[99] && x_s1_auto_out_3_c_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[100] && x_s1_auto_out_3_c_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[101] && x_s1_auto_out_3_c_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[102] && x_s1_auto_out_3_c_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[103] && x_s1_auto_out_3_c_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[104] && x_s1_auto_out_3_c_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[105] && x_s1_auto_out_3_c_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[106] && x_s1_auto_out_3_c_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[107] && x_s1_auto_out_3_c_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[108] && x_s1_auto_out_3_c_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[109] && x_s1_auto_out_3_c_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[110] && x_s1_auto_out_3_c_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[111] && x_s1_auto_out_3_c_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[112] && x_s1_auto_out_3_c_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[113] && x_s1_auto_out_3_c_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[114] && x_s1_auto_out_3_c_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[115] && x_s1_auto_out_3_c_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[116] && x_s1_auto_out_3_c_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[117] && x_s1_auto_out_3_c_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[118] && x_s1_auto_out_3_c_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[119] && x_s1_auto_out_3_c_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[120] && x_s1_auto_out_3_c_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[121] && x_s1_auto_out_3_c_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[122] && x_s1_auto_out_3_c_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[123] && x_s1_auto_out_3_c_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[124] && x_s1_auto_out_3_c_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[125] && x_s1_auto_out_3_c_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[126] && x_s1_auto_out_3_c_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[127] && x_s1_auto_out_3_c_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[128] && x_s1_auto_out_3_c_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[129] && x_s1_auto_out_3_c_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[130] && x_s1_auto_out_3_c_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[131] && x_s1_auto_out_3_c_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[132] && x_s1_auto_out_3_c_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[133] && x_s1_auto_out_3_c_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[134] && x_s1_auto_out_3_c_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[135] && x_s1_auto_out_3_c_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[136] && x_s1_auto_out_3_c_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[137] && x_s1_auto_out_3_c_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[138] && x_s1_auto_out_3_c_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[139] && x_s1_auto_out_3_c_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[140] && x_s1_auto_out_3_c_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[141] && x_s1_auto_out_3_c_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[142] && x_s1_auto_out_3_c_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[143] && x_s1_auto_out_3_c_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[144] && x_s1_auto_out_3_c_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[145] && x_s1_auto_out_3_c_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[146] && x_s1_auto_out_3_c_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[147] && x_s1_auto_out_3_c_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[148] && x_s1_auto_out_3_c_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[149] && x_s1_auto_out_3_c_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[150] && x_s1_auto_out_3_c_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[151] && x_s1_auto_out_3_c_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[152] && x_s1_auto_out_3_c_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[153] && x_s1_auto_out_3_c_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[154] && x_s1_auto_out_3_c_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[155] && x_s1_auto_out_3_c_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[156] && x_s1_auto_out_3_c_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[157] && x_s1_auto_out_3_c_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[158] && x_s1_auto_out_3_c_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[159] && x_s1_auto_out_3_c_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[160] && x_s1_auto_out_3_c_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[161] && x_s1_auto_out_3_c_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[162] && x_s1_auto_out_3_c_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[163] && x_s1_auto_out_3_c_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[164] && x_s1_auto_out_3_c_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[165] && x_s1_auto_out_3_c_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[166] && x_s1_auto_out_3_c_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[167] && x_s1_auto_out_3_c_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[168] && x_s1_auto_out_3_c_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[169] && x_s1_auto_out_3_c_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[170] && x_s1_auto_out_3_c_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[171] && x_s1_auto_out_3_c_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[172] && x_s1_auto_out_3_c_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[173] && x_s1_auto_out_3_c_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[174] && x_s1_auto_out_3_c_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[175] && x_s1_auto_out_3_c_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[176] && x_s1_auto_out_3_c_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[177] && x_s1_auto_out_3_c_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[178] && x_s1_auto_out_3_c_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[179] && x_s1_auto_out_3_c_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[180] && x_s1_auto_out_3_c_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[181] && x_s1_auto_out_3_c_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[182] && x_s1_auto_out_3_c_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[183] && x_s1_auto_out_3_c_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[184] && x_s1_auto_out_3_c_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[185] && x_s1_auto_out_3_c_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[186] && x_s1_auto_out_3_c_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[187] && x_s1_auto_out_3_c_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[188] && x_s1_auto_out_3_c_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[189] && x_s1_auto_out_3_c_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[190] && x_s1_auto_out_3_c_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[191] && x_s1_auto_out_3_c_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[192] && x_s1_auto_out_3_c_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[193] && x_s1_auto_out_3_c_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[194] && x_s1_auto_out_3_c_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[195] && x_s1_auto_out_3_c_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[196] && x_s1_auto_out_3_c_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[197] && x_s1_auto_out_3_c_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[198] && x_s1_auto_out_3_c_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[199] && x_s1_auto_out_3_c_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[200] && x_s1_auto_out_3_c_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[201] && x_s1_auto_out_3_c_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[202] && x_s1_auto_out_3_c_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[203] && x_s1_auto_out_3_c_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[204] && x_s1_auto_out_3_c_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[205] && x_s1_auto_out_3_c_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[206] && x_s1_auto_out_3_c_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[207] && x_s1_auto_out_3_c_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[208] && x_s1_auto_out_3_c_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[209] && x_s1_auto_out_3_c_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[210] && x_s1_auto_out_3_c_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[211] && x_s1_auto_out_3_c_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[212] && x_s1_auto_out_3_c_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[213] && x_s1_auto_out_3_c_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[214] && x_s1_auto_out_3_c_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[215] && x_s1_auto_out_3_c_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[216] && x_s1_auto_out_3_c_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[217] && x_s1_auto_out_3_c_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[218] && x_s1_auto_out_3_c_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[219] && x_s1_auto_out_3_c_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[220] && x_s1_auto_out_3_c_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[221] && x_s1_auto_out_3_c_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[222] && x_s1_auto_out_3_c_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[223] && x_s1_auto_out_3_c_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[224] && x_s1_auto_out_3_c_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[225] && x_s1_auto_out_3_c_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[226] && x_s1_auto_out_3_c_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[227] && x_s1_auto_out_3_c_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[228] && x_s1_auto_out_3_c_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[229] && x_s1_auto_out_3_c_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[230] && x_s1_auto_out_3_c_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[231] && x_s1_auto_out_3_c_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[232] && x_s1_auto_out_3_c_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[233] && x_s1_auto_out_3_c_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[234] && x_s1_auto_out_3_c_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[235] && x_s1_auto_out_3_c_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[236] && x_s1_auto_out_3_c_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[237] && x_s1_auto_out_3_c_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[238] && x_s1_auto_out_3_c_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[239] && x_s1_auto_out_3_c_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[240] && x_s1_auto_out_3_c_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[241] && x_s1_auto_out_3_c_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[242] && x_s1_auto_out_3_c_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[243] && x_s1_auto_out_3_c_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[244] && x_s1_auto_out_3_c_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[245] && x_s1_auto_out_3_c_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[246] && x_s1_auto_out_3_c_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[247] && x_s1_auto_out_3_c_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[248] && x_s1_auto_out_3_c_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[249] && x_s1_auto_out_3_c_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[250] && x_s1_auto_out_3_c_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[251] && x_s1_auto_out_3_c_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[252] && x_s1_auto_out_3_c_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[253] && x_s1_auto_out_3_c_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[254] && x_s1_auto_out_3_c_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_data[255] && x_s1_auto_out_3_c_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_c_bits_corrupt && x_s1_auto_out_3_c_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_c_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_d_ready && x_s1_auto_out_3_d_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_valid && x_s1_auto_out_3_e_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[0] && x_s1_auto_out_3_e_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[1] && x_s1_auto_out_3_e_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[2] && x_s1_auto_out_3_e_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[3] && x_s1_auto_out_3_e_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[4] && x_s1_auto_out_3_e_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[5] && x_s1_auto_out_3_e_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[6] && x_s1_auto_out_3_e_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_3_e_bits_sink[7] && x_s1_auto_out_3_e_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_3_e_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_valid && x_s1_auto_out_2_a_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[0] && x_s1_auto_out_2_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[1] && x_s1_auto_out_2_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[2] && x_s1_auto_out_2_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_opcode[3] && x_s1_auto_out_2_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[0] && x_s1_auto_out_2_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[1] && x_s1_auto_out_2_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_param[2] && x_s1_auto_out_2_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_size[0] && x_s1_auto_out_2_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_size[1] && x_s1_auto_out_2_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_size[2] && x_s1_auto_out_2_a_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[0] && x_s1_auto_out_2_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[1] && x_s1_auto_out_2_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[2] && x_s1_auto_out_2_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[3] && x_s1_auto_out_2_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[4] && x_s1_auto_out_2_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[5] && x_s1_auto_out_2_a_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_source[6] && x_s1_auto_out_2_a_bits_source[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_source[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[0] && x_s1_auto_out_2_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[1] && x_s1_auto_out_2_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[2] && x_s1_auto_out_2_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[3] && x_s1_auto_out_2_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[4] && x_s1_auto_out_2_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[5] && x_s1_auto_out_2_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[6] && x_s1_auto_out_2_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[7] && x_s1_auto_out_2_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[8] && x_s1_auto_out_2_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[9] && x_s1_auto_out_2_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[10] && x_s1_auto_out_2_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[11] && x_s1_auto_out_2_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[12] && x_s1_auto_out_2_a_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[13] && x_s1_auto_out_2_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[14] && x_s1_auto_out_2_a_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[15] && x_s1_auto_out_2_a_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[16] && x_s1_auto_out_2_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[17] && x_s1_auto_out_2_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[18] && x_s1_auto_out_2_a_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[19] && x_s1_auto_out_2_a_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[20] && x_s1_auto_out_2_a_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[21] && x_s1_auto_out_2_a_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[22] && x_s1_auto_out_2_a_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[23] && x_s1_auto_out_2_a_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[24] && x_s1_auto_out_2_a_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[25] && x_s1_auto_out_2_a_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[26] && x_s1_auto_out_2_a_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[27] && x_s1_auto_out_2_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[28] && x_s1_auto_out_2_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[29] && x_s1_auto_out_2_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[30] && x_s1_auto_out_2_a_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[31] && x_s1_auto_out_2_a_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[32] && x_s1_auto_out_2_a_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[33] && x_s1_auto_out_2_a_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[34] && x_s1_auto_out_2_a_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[35] && x_s1_auto_out_2_a_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[36] && x_s1_auto_out_2_a_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[37] && x_s1_auto_out_2_a_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[38] && x_s1_auto_out_2_a_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[39] && x_s1_auto_out_2_a_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[40] && x_s1_auto_out_2_a_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[41] && x_s1_auto_out_2_a_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[42] && x_s1_auto_out_2_a_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[43] && x_s1_auto_out_2_a_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[44] && x_s1_auto_out_2_a_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[45] && x_s1_auto_out_2_a_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[46] && x_s1_auto_out_2_a_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_address[47] && x_s1_auto_out_2_a_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_reqSource[0] && x_s1_auto_out_2_a_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_reqSource[1] && x_s1_auto_out_2_a_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_reqSource[2] && x_s1_auto_out_2_a_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_reqSource[3] && x_s1_auto_out_2_a_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_reqSource[4] && x_s1_auto_out_2_a_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_alias[0] && x_s1_auto_out_2_a_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_alias[1] && x_s1_auto_out_2_a_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[0] && x_s1_auto_out_2_a_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[1] && x_s1_auto_out_2_a_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[2] && x_s1_auto_out_2_a_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[3] && x_s1_auto_out_2_a_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[4] && x_s1_auto_out_2_a_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[5] && x_s1_auto_out_2_a_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[6] && x_s1_auto_out_2_a_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[7] && x_s1_auto_out_2_a_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[8] && x_s1_auto_out_2_a_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[9] && x_s1_auto_out_2_a_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[10] && x_s1_auto_out_2_a_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[11] && x_s1_auto_out_2_a_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[12] && x_s1_auto_out_2_a_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[13] && x_s1_auto_out_2_a_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[14] && x_s1_auto_out_2_a_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[15] && x_s1_auto_out_2_a_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[16] && x_s1_auto_out_2_a_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[17] && x_s1_auto_out_2_a_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[18] && x_s1_auto_out_2_a_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[19] && x_s1_auto_out_2_a_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[20] && x_s1_auto_out_2_a_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[21] && x_s1_auto_out_2_a_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[22] && x_s1_auto_out_2_a_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[23] && x_s1_auto_out_2_a_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[24] && x_s1_auto_out_2_a_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[25] && x_s1_auto_out_2_a_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[26] && x_s1_auto_out_2_a_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[27] && x_s1_auto_out_2_a_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[28] && x_s1_auto_out_2_a_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[29] && x_s1_auto_out_2_a_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[30] && x_s1_auto_out_2_a_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[31] && x_s1_auto_out_2_a_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[32] && x_s1_auto_out_2_a_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[33] && x_s1_auto_out_2_a_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[34] && x_s1_auto_out_2_a_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[35] && x_s1_auto_out_2_a_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[36] && x_s1_auto_out_2_a_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[37] && x_s1_auto_out_2_a_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[38] && x_s1_auto_out_2_a_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[39] && x_s1_auto_out_2_a_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[40] && x_s1_auto_out_2_a_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[41] && x_s1_auto_out_2_a_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[42] && x_s1_auto_out_2_a_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_vaddr[43] && x_s1_auto_out_2_a_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_user_needHint && x_s1_auto_out_2_a_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_echo_isKeyword && x_s1_auto_out_2_a_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[0] && x_s1_auto_out_2_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[1] && x_s1_auto_out_2_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[2] && x_s1_auto_out_2_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[3] && x_s1_auto_out_2_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[4] && x_s1_auto_out_2_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[5] && x_s1_auto_out_2_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[6] && x_s1_auto_out_2_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[7] && x_s1_auto_out_2_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[8] && x_s1_auto_out_2_a_bits_mask[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[9] && x_s1_auto_out_2_a_bits_mask[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[10] && x_s1_auto_out_2_a_bits_mask[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[11] && x_s1_auto_out_2_a_bits_mask[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[12] && x_s1_auto_out_2_a_bits_mask[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[13] && x_s1_auto_out_2_a_bits_mask[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[14] && x_s1_auto_out_2_a_bits_mask[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[15] && x_s1_auto_out_2_a_bits_mask[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[16] && x_s1_auto_out_2_a_bits_mask[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[17] && x_s1_auto_out_2_a_bits_mask[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[18] && x_s1_auto_out_2_a_bits_mask[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[19] && x_s1_auto_out_2_a_bits_mask[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[20] && x_s1_auto_out_2_a_bits_mask[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[21] && x_s1_auto_out_2_a_bits_mask[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[22] && x_s1_auto_out_2_a_bits_mask[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[23] && x_s1_auto_out_2_a_bits_mask[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[24] && x_s1_auto_out_2_a_bits_mask[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[25] && x_s1_auto_out_2_a_bits_mask[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[26] && x_s1_auto_out_2_a_bits_mask[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[27] && x_s1_auto_out_2_a_bits_mask[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[28] && x_s1_auto_out_2_a_bits_mask[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[29] && x_s1_auto_out_2_a_bits_mask[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[30] && x_s1_auto_out_2_a_bits_mask[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_mask[31] && x_s1_auto_out_2_a_bits_mask[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_mask[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[0] && x_s1_auto_out_2_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[1] && x_s1_auto_out_2_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[2] && x_s1_auto_out_2_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[3] && x_s1_auto_out_2_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[4] && x_s1_auto_out_2_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[5] && x_s1_auto_out_2_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[6] && x_s1_auto_out_2_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[7] && x_s1_auto_out_2_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[8] && x_s1_auto_out_2_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[9] && x_s1_auto_out_2_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[10] && x_s1_auto_out_2_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[11] && x_s1_auto_out_2_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[12] && x_s1_auto_out_2_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[13] && x_s1_auto_out_2_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[14] && x_s1_auto_out_2_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[15] && x_s1_auto_out_2_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[16] && x_s1_auto_out_2_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[17] && x_s1_auto_out_2_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[18] && x_s1_auto_out_2_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[19] && x_s1_auto_out_2_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[20] && x_s1_auto_out_2_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[21] && x_s1_auto_out_2_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[22] && x_s1_auto_out_2_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[23] && x_s1_auto_out_2_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[24] && x_s1_auto_out_2_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[25] && x_s1_auto_out_2_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[26] && x_s1_auto_out_2_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[27] && x_s1_auto_out_2_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[28] && x_s1_auto_out_2_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[29] && x_s1_auto_out_2_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[30] && x_s1_auto_out_2_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[31] && x_s1_auto_out_2_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[32] && x_s1_auto_out_2_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[33] && x_s1_auto_out_2_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[34] && x_s1_auto_out_2_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[35] && x_s1_auto_out_2_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[36] && x_s1_auto_out_2_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[37] && x_s1_auto_out_2_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[38] && x_s1_auto_out_2_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[39] && x_s1_auto_out_2_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[40] && x_s1_auto_out_2_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[41] && x_s1_auto_out_2_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[42] && x_s1_auto_out_2_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[43] && x_s1_auto_out_2_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[44] && x_s1_auto_out_2_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[45] && x_s1_auto_out_2_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[46] && x_s1_auto_out_2_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[47] && x_s1_auto_out_2_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[48] && x_s1_auto_out_2_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[49] && x_s1_auto_out_2_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[50] && x_s1_auto_out_2_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[51] && x_s1_auto_out_2_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[52] && x_s1_auto_out_2_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[53] && x_s1_auto_out_2_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[54] && x_s1_auto_out_2_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[55] && x_s1_auto_out_2_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[56] && x_s1_auto_out_2_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[57] && x_s1_auto_out_2_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[58] && x_s1_auto_out_2_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[59] && x_s1_auto_out_2_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[60] && x_s1_auto_out_2_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[61] && x_s1_auto_out_2_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[62] && x_s1_auto_out_2_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[63] && x_s1_auto_out_2_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[64] && x_s1_auto_out_2_a_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[65] && x_s1_auto_out_2_a_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[66] && x_s1_auto_out_2_a_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[67] && x_s1_auto_out_2_a_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[68] && x_s1_auto_out_2_a_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[69] && x_s1_auto_out_2_a_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[70] && x_s1_auto_out_2_a_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[71] && x_s1_auto_out_2_a_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[72] && x_s1_auto_out_2_a_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[73] && x_s1_auto_out_2_a_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[74] && x_s1_auto_out_2_a_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[75] && x_s1_auto_out_2_a_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[76] && x_s1_auto_out_2_a_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[77] && x_s1_auto_out_2_a_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[78] && x_s1_auto_out_2_a_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[79] && x_s1_auto_out_2_a_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[80] && x_s1_auto_out_2_a_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[81] && x_s1_auto_out_2_a_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[82] && x_s1_auto_out_2_a_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[83] && x_s1_auto_out_2_a_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[84] && x_s1_auto_out_2_a_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[85] && x_s1_auto_out_2_a_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[86] && x_s1_auto_out_2_a_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[87] && x_s1_auto_out_2_a_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[88] && x_s1_auto_out_2_a_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[89] && x_s1_auto_out_2_a_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[90] && x_s1_auto_out_2_a_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[91] && x_s1_auto_out_2_a_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[92] && x_s1_auto_out_2_a_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[93] && x_s1_auto_out_2_a_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[94] && x_s1_auto_out_2_a_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[95] && x_s1_auto_out_2_a_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[96] && x_s1_auto_out_2_a_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[97] && x_s1_auto_out_2_a_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[98] && x_s1_auto_out_2_a_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[99] && x_s1_auto_out_2_a_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[100] && x_s1_auto_out_2_a_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[101] && x_s1_auto_out_2_a_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[102] && x_s1_auto_out_2_a_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[103] && x_s1_auto_out_2_a_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[104] && x_s1_auto_out_2_a_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[105] && x_s1_auto_out_2_a_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[106] && x_s1_auto_out_2_a_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[107] && x_s1_auto_out_2_a_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[108] && x_s1_auto_out_2_a_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[109] && x_s1_auto_out_2_a_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[110] && x_s1_auto_out_2_a_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[111] && x_s1_auto_out_2_a_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[112] && x_s1_auto_out_2_a_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[113] && x_s1_auto_out_2_a_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[114] && x_s1_auto_out_2_a_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[115] && x_s1_auto_out_2_a_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[116] && x_s1_auto_out_2_a_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[117] && x_s1_auto_out_2_a_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[118] && x_s1_auto_out_2_a_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[119] && x_s1_auto_out_2_a_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[120] && x_s1_auto_out_2_a_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[121] && x_s1_auto_out_2_a_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[122] && x_s1_auto_out_2_a_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[123] && x_s1_auto_out_2_a_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[124] && x_s1_auto_out_2_a_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[125] && x_s1_auto_out_2_a_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[126] && x_s1_auto_out_2_a_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[127] && x_s1_auto_out_2_a_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[128] && x_s1_auto_out_2_a_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[129] && x_s1_auto_out_2_a_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[130] && x_s1_auto_out_2_a_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[131] && x_s1_auto_out_2_a_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[132] && x_s1_auto_out_2_a_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[133] && x_s1_auto_out_2_a_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[134] && x_s1_auto_out_2_a_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[135] && x_s1_auto_out_2_a_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[136] && x_s1_auto_out_2_a_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[137] && x_s1_auto_out_2_a_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[138] && x_s1_auto_out_2_a_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[139] && x_s1_auto_out_2_a_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[140] && x_s1_auto_out_2_a_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[141] && x_s1_auto_out_2_a_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[142] && x_s1_auto_out_2_a_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[143] && x_s1_auto_out_2_a_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[144] && x_s1_auto_out_2_a_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[145] && x_s1_auto_out_2_a_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[146] && x_s1_auto_out_2_a_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[147] && x_s1_auto_out_2_a_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[148] && x_s1_auto_out_2_a_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[149] && x_s1_auto_out_2_a_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[150] && x_s1_auto_out_2_a_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[151] && x_s1_auto_out_2_a_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[152] && x_s1_auto_out_2_a_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[153] && x_s1_auto_out_2_a_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[154] && x_s1_auto_out_2_a_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[155] && x_s1_auto_out_2_a_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[156] && x_s1_auto_out_2_a_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[157] && x_s1_auto_out_2_a_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[158] && x_s1_auto_out_2_a_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[159] && x_s1_auto_out_2_a_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[160] && x_s1_auto_out_2_a_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[161] && x_s1_auto_out_2_a_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[162] && x_s1_auto_out_2_a_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[163] && x_s1_auto_out_2_a_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[164] && x_s1_auto_out_2_a_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[165] && x_s1_auto_out_2_a_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[166] && x_s1_auto_out_2_a_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[167] && x_s1_auto_out_2_a_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[168] && x_s1_auto_out_2_a_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[169] && x_s1_auto_out_2_a_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[170] && x_s1_auto_out_2_a_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[171] && x_s1_auto_out_2_a_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[172] && x_s1_auto_out_2_a_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[173] && x_s1_auto_out_2_a_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[174] && x_s1_auto_out_2_a_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[175] && x_s1_auto_out_2_a_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[176] && x_s1_auto_out_2_a_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[177] && x_s1_auto_out_2_a_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[178] && x_s1_auto_out_2_a_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[179] && x_s1_auto_out_2_a_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[180] && x_s1_auto_out_2_a_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[181] && x_s1_auto_out_2_a_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[182] && x_s1_auto_out_2_a_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[183] && x_s1_auto_out_2_a_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[184] && x_s1_auto_out_2_a_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[185] && x_s1_auto_out_2_a_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[186] && x_s1_auto_out_2_a_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[187] && x_s1_auto_out_2_a_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[188] && x_s1_auto_out_2_a_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[189] && x_s1_auto_out_2_a_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[190] && x_s1_auto_out_2_a_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[191] && x_s1_auto_out_2_a_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[192] && x_s1_auto_out_2_a_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[193] && x_s1_auto_out_2_a_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[194] && x_s1_auto_out_2_a_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[195] && x_s1_auto_out_2_a_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[196] && x_s1_auto_out_2_a_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[197] && x_s1_auto_out_2_a_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[198] && x_s1_auto_out_2_a_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[199] && x_s1_auto_out_2_a_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[200] && x_s1_auto_out_2_a_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[201] && x_s1_auto_out_2_a_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[202] && x_s1_auto_out_2_a_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[203] && x_s1_auto_out_2_a_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[204] && x_s1_auto_out_2_a_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[205] && x_s1_auto_out_2_a_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[206] && x_s1_auto_out_2_a_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[207] && x_s1_auto_out_2_a_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[208] && x_s1_auto_out_2_a_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[209] && x_s1_auto_out_2_a_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[210] && x_s1_auto_out_2_a_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[211] && x_s1_auto_out_2_a_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[212] && x_s1_auto_out_2_a_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[213] && x_s1_auto_out_2_a_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[214] && x_s1_auto_out_2_a_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[215] && x_s1_auto_out_2_a_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[216] && x_s1_auto_out_2_a_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[217] && x_s1_auto_out_2_a_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[218] && x_s1_auto_out_2_a_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[219] && x_s1_auto_out_2_a_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[220] && x_s1_auto_out_2_a_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[221] && x_s1_auto_out_2_a_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[222] && x_s1_auto_out_2_a_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[223] && x_s1_auto_out_2_a_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[224] && x_s1_auto_out_2_a_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[225] && x_s1_auto_out_2_a_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[226] && x_s1_auto_out_2_a_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[227] && x_s1_auto_out_2_a_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[228] && x_s1_auto_out_2_a_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[229] && x_s1_auto_out_2_a_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[230] && x_s1_auto_out_2_a_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[231] && x_s1_auto_out_2_a_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[232] && x_s1_auto_out_2_a_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[233] && x_s1_auto_out_2_a_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[234] && x_s1_auto_out_2_a_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[235] && x_s1_auto_out_2_a_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[236] && x_s1_auto_out_2_a_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[237] && x_s1_auto_out_2_a_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[238] && x_s1_auto_out_2_a_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[239] && x_s1_auto_out_2_a_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[240] && x_s1_auto_out_2_a_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[241] && x_s1_auto_out_2_a_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[242] && x_s1_auto_out_2_a_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[243] && x_s1_auto_out_2_a_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[244] && x_s1_auto_out_2_a_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[245] && x_s1_auto_out_2_a_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[246] && x_s1_auto_out_2_a_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[247] && x_s1_auto_out_2_a_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[248] && x_s1_auto_out_2_a_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[249] && x_s1_auto_out_2_a_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[250] && x_s1_auto_out_2_a_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[251] && x_s1_auto_out_2_a_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[252] && x_s1_auto_out_2_a_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[253] && x_s1_auto_out_2_a_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[254] && x_s1_auto_out_2_a_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_data[255] && x_s1_auto_out_2_a_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_a_bits_corrupt && x_s1_auto_out_2_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_b_ready && x_s1_auto_out_2_b_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_b_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_valid && x_s1_auto_out_2_c_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_opcode[0] && x_s1_auto_out_2_c_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_opcode[1] && x_s1_auto_out_2_c_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_opcode[2] && x_s1_auto_out_2_c_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_param[0] && x_s1_auto_out_2_c_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_param[1] && x_s1_auto_out_2_c_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_param[2] && x_s1_auto_out_2_c_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_size[0] && x_s1_auto_out_2_c_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_size[1] && x_s1_auto_out_2_c_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_size[2] && x_s1_auto_out_2_c_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[0] && x_s1_auto_out_2_c_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[1] && x_s1_auto_out_2_c_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[2] && x_s1_auto_out_2_c_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[3] && x_s1_auto_out_2_c_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[4] && x_s1_auto_out_2_c_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_source[5] && x_s1_auto_out_2_c_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[0] && x_s1_auto_out_2_c_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[1] && x_s1_auto_out_2_c_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[2] && x_s1_auto_out_2_c_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[3] && x_s1_auto_out_2_c_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[4] && x_s1_auto_out_2_c_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[5] && x_s1_auto_out_2_c_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[6] && x_s1_auto_out_2_c_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[7] && x_s1_auto_out_2_c_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[8] && x_s1_auto_out_2_c_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[9] && x_s1_auto_out_2_c_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[10] && x_s1_auto_out_2_c_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[11] && x_s1_auto_out_2_c_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[12] && x_s1_auto_out_2_c_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[13] && x_s1_auto_out_2_c_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[14] && x_s1_auto_out_2_c_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[15] && x_s1_auto_out_2_c_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[16] && x_s1_auto_out_2_c_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[17] && x_s1_auto_out_2_c_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[18] && x_s1_auto_out_2_c_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[19] && x_s1_auto_out_2_c_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[20] && x_s1_auto_out_2_c_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[21] && x_s1_auto_out_2_c_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[22] && x_s1_auto_out_2_c_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[23] && x_s1_auto_out_2_c_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[24] && x_s1_auto_out_2_c_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[25] && x_s1_auto_out_2_c_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[26] && x_s1_auto_out_2_c_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[27] && x_s1_auto_out_2_c_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[28] && x_s1_auto_out_2_c_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[29] && x_s1_auto_out_2_c_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[30] && x_s1_auto_out_2_c_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[31] && x_s1_auto_out_2_c_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[32] && x_s1_auto_out_2_c_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[33] && x_s1_auto_out_2_c_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[34] && x_s1_auto_out_2_c_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[35] && x_s1_auto_out_2_c_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[36] && x_s1_auto_out_2_c_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[37] && x_s1_auto_out_2_c_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[38] && x_s1_auto_out_2_c_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[39] && x_s1_auto_out_2_c_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[40] && x_s1_auto_out_2_c_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[41] && x_s1_auto_out_2_c_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[42] && x_s1_auto_out_2_c_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[43] && x_s1_auto_out_2_c_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[44] && x_s1_auto_out_2_c_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[45] && x_s1_auto_out_2_c_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[46] && x_s1_auto_out_2_c_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_address[47] && x_s1_auto_out_2_c_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_reqSource[0] && x_s1_auto_out_2_c_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_reqSource[1] && x_s1_auto_out_2_c_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_reqSource[2] && x_s1_auto_out_2_c_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_reqSource[3] && x_s1_auto_out_2_c_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_reqSource[4] && x_s1_auto_out_2_c_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_alias[0] && x_s1_auto_out_2_c_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_alias[1] && x_s1_auto_out_2_c_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[0] && x_s1_auto_out_2_c_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[1] && x_s1_auto_out_2_c_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[2] && x_s1_auto_out_2_c_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[3] && x_s1_auto_out_2_c_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[4] && x_s1_auto_out_2_c_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[5] && x_s1_auto_out_2_c_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[6] && x_s1_auto_out_2_c_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[7] && x_s1_auto_out_2_c_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[8] && x_s1_auto_out_2_c_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[9] && x_s1_auto_out_2_c_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[10] && x_s1_auto_out_2_c_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[11] && x_s1_auto_out_2_c_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[12] && x_s1_auto_out_2_c_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[13] && x_s1_auto_out_2_c_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[14] && x_s1_auto_out_2_c_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[15] && x_s1_auto_out_2_c_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[16] && x_s1_auto_out_2_c_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[17] && x_s1_auto_out_2_c_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[18] && x_s1_auto_out_2_c_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[19] && x_s1_auto_out_2_c_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[20] && x_s1_auto_out_2_c_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[21] && x_s1_auto_out_2_c_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[22] && x_s1_auto_out_2_c_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[23] && x_s1_auto_out_2_c_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[24] && x_s1_auto_out_2_c_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[25] && x_s1_auto_out_2_c_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[26] && x_s1_auto_out_2_c_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[27] && x_s1_auto_out_2_c_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[28] && x_s1_auto_out_2_c_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[29] && x_s1_auto_out_2_c_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[30] && x_s1_auto_out_2_c_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[31] && x_s1_auto_out_2_c_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[32] && x_s1_auto_out_2_c_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[33] && x_s1_auto_out_2_c_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[34] && x_s1_auto_out_2_c_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[35] && x_s1_auto_out_2_c_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[36] && x_s1_auto_out_2_c_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[37] && x_s1_auto_out_2_c_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[38] && x_s1_auto_out_2_c_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[39] && x_s1_auto_out_2_c_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[40] && x_s1_auto_out_2_c_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[41] && x_s1_auto_out_2_c_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[42] && x_s1_auto_out_2_c_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_vaddr[43] && x_s1_auto_out_2_c_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_user_needHint && x_s1_auto_out_2_c_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_echo_isKeyword && x_s1_auto_out_2_c_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[0] && x_s1_auto_out_2_c_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[1] && x_s1_auto_out_2_c_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[2] && x_s1_auto_out_2_c_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[3] && x_s1_auto_out_2_c_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[4] && x_s1_auto_out_2_c_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[5] && x_s1_auto_out_2_c_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[6] && x_s1_auto_out_2_c_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[7] && x_s1_auto_out_2_c_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[8] && x_s1_auto_out_2_c_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[9] && x_s1_auto_out_2_c_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[10] && x_s1_auto_out_2_c_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[11] && x_s1_auto_out_2_c_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[12] && x_s1_auto_out_2_c_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[13] && x_s1_auto_out_2_c_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[14] && x_s1_auto_out_2_c_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[15] && x_s1_auto_out_2_c_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[16] && x_s1_auto_out_2_c_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[17] && x_s1_auto_out_2_c_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[18] && x_s1_auto_out_2_c_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[19] && x_s1_auto_out_2_c_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[20] && x_s1_auto_out_2_c_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[21] && x_s1_auto_out_2_c_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[22] && x_s1_auto_out_2_c_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[23] && x_s1_auto_out_2_c_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[24] && x_s1_auto_out_2_c_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[25] && x_s1_auto_out_2_c_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[26] && x_s1_auto_out_2_c_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[27] && x_s1_auto_out_2_c_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[28] && x_s1_auto_out_2_c_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[29] && x_s1_auto_out_2_c_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[30] && x_s1_auto_out_2_c_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[31] && x_s1_auto_out_2_c_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[32] && x_s1_auto_out_2_c_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[33] && x_s1_auto_out_2_c_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[34] && x_s1_auto_out_2_c_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[35] && x_s1_auto_out_2_c_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[36] && x_s1_auto_out_2_c_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[37] && x_s1_auto_out_2_c_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[38] && x_s1_auto_out_2_c_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[39] && x_s1_auto_out_2_c_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[40] && x_s1_auto_out_2_c_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[41] && x_s1_auto_out_2_c_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[42] && x_s1_auto_out_2_c_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[43] && x_s1_auto_out_2_c_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[44] && x_s1_auto_out_2_c_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[45] && x_s1_auto_out_2_c_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[46] && x_s1_auto_out_2_c_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[47] && x_s1_auto_out_2_c_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[48] && x_s1_auto_out_2_c_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[49] && x_s1_auto_out_2_c_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[50] && x_s1_auto_out_2_c_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[51] && x_s1_auto_out_2_c_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[52] && x_s1_auto_out_2_c_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[53] && x_s1_auto_out_2_c_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[54] && x_s1_auto_out_2_c_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[55] && x_s1_auto_out_2_c_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[56] && x_s1_auto_out_2_c_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[57] && x_s1_auto_out_2_c_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[58] && x_s1_auto_out_2_c_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[59] && x_s1_auto_out_2_c_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[60] && x_s1_auto_out_2_c_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[61] && x_s1_auto_out_2_c_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[62] && x_s1_auto_out_2_c_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[63] && x_s1_auto_out_2_c_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[64] && x_s1_auto_out_2_c_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[65] && x_s1_auto_out_2_c_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[66] && x_s1_auto_out_2_c_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[67] && x_s1_auto_out_2_c_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[68] && x_s1_auto_out_2_c_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[69] && x_s1_auto_out_2_c_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[70] && x_s1_auto_out_2_c_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[71] && x_s1_auto_out_2_c_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[72] && x_s1_auto_out_2_c_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[73] && x_s1_auto_out_2_c_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[74] && x_s1_auto_out_2_c_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[75] && x_s1_auto_out_2_c_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[76] && x_s1_auto_out_2_c_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[77] && x_s1_auto_out_2_c_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[78] && x_s1_auto_out_2_c_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[79] && x_s1_auto_out_2_c_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[80] && x_s1_auto_out_2_c_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[81] && x_s1_auto_out_2_c_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[82] && x_s1_auto_out_2_c_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[83] && x_s1_auto_out_2_c_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[84] && x_s1_auto_out_2_c_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[85] && x_s1_auto_out_2_c_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[86] && x_s1_auto_out_2_c_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[87] && x_s1_auto_out_2_c_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[88] && x_s1_auto_out_2_c_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[89] && x_s1_auto_out_2_c_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[90] && x_s1_auto_out_2_c_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[91] && x_s1_auto_out_2_c_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[92] && x_s1_auto_out_2_c_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[93] && x_s1_auto_out_2_c_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[94] && x_s1_auto_out_2_c_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[95] && x_s1_auto_out_2_c_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[96] && x_s1_auto_out_2_c_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[97] && x_s1_auto_out_2_c_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[98] && x_s1_auto_out_2_c_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[99] && x_s1_auto_out_2_c_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[100] && x_s1_auto_out_2_c_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[101] && x_s1_auto_out_2_c_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[102] && x_s1_auto_out_2_c_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[103] && x_s1_auto_out_2_c_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[104] && x_s1_auto_out_2_c_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[105] && x_s1_auto_out_2_c_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[106] && x_s1_auto_out_2_c_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[107] && x_s1_auto_out_2_c_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[108] && x_s1_auto_out_2_c_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[109] && x_s1_auto_out_2_c_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[110] && x_s1_auto_out_2_c_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[111] && x_s1_auto_out_2_c_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[112] && x_s1_auto_out_2_c_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[113] && x_s1_auto_out_2_c_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[114] && x_s1_auto_out_2_c_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[115] && x_s1_auto_out_2_c_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[116] && x_s1_auto_out_2_c_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[117] && x_s1_auto_out_2_c_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[118] && x_s1_auto_out_2_c_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[119] && x_s1_auto_out_2_c_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[120] && x_s1_auto_out_2_c_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[121] && x_s1_auto_out_2_c_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[122] && x_s1_auto_out_2_c_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[123] && x_s1_auto_out_2_c_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[124] && x_s1_auto_out_2_c_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[125] && x_s1_auto_out_2_c_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[126] && x_s1_auto_out_2_c_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[127] && x_s1_auto_out_2_c_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[128] && x_s1_auto_out_2_c_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[129] && x_s1_auto_out_2_c_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[130] && x_s1_auto_out_2_c_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[131] && x_s1_auto_out_2_c_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[132] && x_s1_auto_out_2_c_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[133] && x_s1_auto_out_2_c_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[134] && x_s1_auto_out_2_c_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[135] && x_s1_auto_out_2_c_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[136] && x_s1_auto_out_2_c_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[137] && x_s1_auto_out_2_c_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[138] && x_s1_auto_out_2_c_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[139] && x_s1_auto_out_2_c_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[140] && x_s1_auto_out_2_c_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[141] && x_s1_auto_out_2_c_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[142] && x_s1_auto_out_2_c_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[143] && x_s1_auto_out_2_c_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[144] && x_s1_auto_out_2_c_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[145] && x_s1_auto_out_2_c_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[146] && x_s1_auto_out_2_c_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[147] && x_s1_auto_out_2_c_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[148] && x_s1_auto_out_2_c_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[149] && x_s1_auto_out_2_c_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[150] && x_s1_auto_out_2_c_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[151] && x_s1_auto_out_2_c_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[152] && x_s1_auto_out_2_c_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[153] && x_s1_auto_out_2_c_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[154] && x_s1_auto_out_2_c_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[155] && x_s1_auto_out_2_c_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[156] && x_s1_auto_out_2_c_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[157] && x_s1_auto_out_2_c_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[158] && x_s1_auto_out_2_c_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[159] && x_s1_auto_out_2_c_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[160] && x_s1_auto_out_2_c_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[161] && x_s1_auto_out_2_c_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[162] && x_s1_auto_out_2_c_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[163] && x_s1_auto_out_2_c_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[164] && x_s1_auto_out_2_c_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[165] && x_s1_auto_out_2_c_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[166] && x_s1_auto_out_2_c_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[167] && x_s1_auto_out_2_c_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[168] && x_s1_auto_out_2_c_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[169] && x_s1_auto_out_2_c_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[170] && x_s1_auto_out_2_c_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[171] && x_s1_auto_out_2_c_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[172] && x_s1_auto_out_2_c_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[173] && x_s1_auto_out_2_c_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[174] && x_s1_auto_out_2_c_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[175] && x_s1_auto_out_2_c_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[176] && x_s1_auto_out_2_c_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[177] && x_s1_auto_out_2_c_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[178] && x_s1_auto_out_2_c_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[179] && x_s1_auto_out_2_c_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[180] && x_s1_auto_out_2_c_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[181] && x_s1_auto_out_2_c_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[182] && x_s1_auto_out_2_c_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[183] && x_s1_auto_out_2_c_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[184] && x_s1_auto_out_2_c_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[185] && x_s1_auto_out_2_c_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[186] && x_s1_auto_out_2_c_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[187] && x_s1_auto_out_2_c_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[188] && x_s1_auto_out_2_c_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[189] && x_s1_auto_out_2_c_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[190] && x_s1_auto_out_2_c_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[191] && x_s1_auto_out_2_c_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[192] && x_s1_auto_out_2_c_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[193] && x_s1_auto_out_2_c_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[194] && x_s1_auto_out_2_c_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[195] && x_s1_auto_out_2_c_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[196] && x_s1_auto_out_2_c_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[197] && x_s1_auto_out_2_c_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[198] && x_s1_auto_out_2_c_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[199] && x_s1_auto_out_2_c_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[200] && x_s1_auto_out_2_c_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[201] && x_s1_auto_out_2_c_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[202] && x_s1_auto_out_2_c_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[203] && x_s1_auto_out_2_c_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[204] && x_s1_auto_out_2_c_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[205] && x_s1_auto_out_2_c_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[206] && x_s1_auto_out_2_c_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[207] && x_s1_auto_out_2_c_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[208] && x_s1_auto_out_2_c_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[209] && x_s1_auto_out_2_c_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[210] && x_s1_auto_out_2_c_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[211] && x_s1_auto_out_2_c_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[212] && x_s1_auto_out_2_c_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[213] && x_s1_auto_out_2_c_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[214] && x_s1_auto_out_2_c_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[215] && x_s1_auto_out_2_c_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[216] && x_s1_auto_out_2_c_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[217] && x_s1_auto_out_2_c_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[218] && x_s1_auto_out_2_c_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[219] && x_s1_auto_out_2_c_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[220] && x_s1_auto_out_2_c_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[221] && x_s1_auto_out_2_c_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[222] && x_s1_auto_out_2_c_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[223] && x_s1_auto_out_2_c_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[224] && x_s1_auto_out_2_c_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[225] && x_s1_auto_out_2_c_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[226] && x_s1_auto_out_2_c_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[227] && x_s1_auto_out_2_c_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[228] && x_s1_auto_out_2_c_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[229] && x_s1_auto_out_2_c_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[230] && x_s1_auto_out_2_c_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[231] && x_s1_auto_out_2_c_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[232] && x_s1_auto_out_2_c_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[233] && x_s1_auto_out_2_c_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[234] && x_s1_auto_out_2_c_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[235] && x_s1_auto_out_2_c_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[236] && x_s1_auto_out_2_c_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[237] && x_s1_auto_out_2_c_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[238] && x_s1_auto_out_2_c_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[239] && x_s1_auto_out_2_c_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[240] && x_s1_auto_out_2_c_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[241] && x_s1_auto_out_2_c_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[242] && x_s1_auto_out_2_c_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[243] && x_s1_auto_out_2_c_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[244] && x_s1_auto_out_2_c_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[245] && x_s1_auto_out_2_c_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[246] && x_s1_auto_out_2_c_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[247] && x_s1_auto_out_2_c_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[248] && x_s1_auto_out_2_c_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[249] && x_s1_auto_out_2_c_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[250] && x_s1_auto_out_2_c_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[251] && x_s1_auto_out_2_c_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[252] && x_s1_auto_out_2_c_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[253] && x_s1_auto_out_2_c_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[254] && x_s1_auto_out_2_c_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_data[255] && x_s1_auto_out_2_c_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_c_bits_corrupt && x_s1_auto_out_2_c_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_c_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_d_ready && x_s1_auto_out_2_d_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_valid && x_s1_auto_out_2_e_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[0] && x_s1_auto_out_2_e_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[1] && x_s1_auto_out_2_e_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[2] && x_s1_auto_out_2_e_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[3] && x_s1_auto_out_2_e_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[4] && x_s1_auto_out_2_e_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[5] && x_s1_auto_out_2_e_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[6] && x_s1_auto_out_2_e_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_2_e_bits_sink[7] && x_s1_auto_out_2_e_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_2_e_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_valid && x_s1_auto_out_1_a_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[0] && x_s1_auto_out_1_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[1] && x_s1_auto_out_1_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[2] && x_s1_auto_out_1_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_opcode[3] && x_s1_auto_out_1_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[0] && x_s1_auto_out_1_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[1] && x_s1_auto_out_1_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_param[2] && x_s1_auto_out_1_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_size[0] && x_s1_auto_out_1_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_size[1] && x_s1_auto_out_1_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_size[2] && x_s1_auto_out_1_a_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[0] && x_s1_auto_out_1_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[1] && x_s1_auto_out_1_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[2] && x_s1_auto_out_1_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[3] && x_s1_auto_out_1_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[4] && x_s1_auto_out_1_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[5] && x_s1_auto_out_1_a_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_source[6] && x_s1_auto_out_1_a_bits_source[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_source[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[0] && x_s1_auto_out_1_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[1] && x_s1_auto_out_1_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[2] && x_s1_auto_out_1_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[3] && x_s1_auto_out_1_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[4] && x_s1_auto_out_1_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[5] && x_s1_auto_out_1_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[6] && x_s1_auto_out_1_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[7] && x_s1_auto_out_1_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[8] && x_s1_auto_out_1_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[9] && x_s1_auto_out_1_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[10] && x_s1_auto_out_1_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[11] && x_s1_auto_out_1_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[12] && x_s1_auto_out_1_a_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[13] && x_s1_auto_out_1_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[14] && x_s1_auto_out_1_a_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[15] && x_s1_auto_out_1_a_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[16] && x_s1_auto_out_1_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[17] && x_s1_auto_out_1_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[18] && x_s1_auto_out_1_a_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[19] && x_s1_auto_out_1_a_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[20] && x_s1_auto_out_1_a_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[21] && x_s1_auto_out_1_a_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[22] && x_s1_auto_out_1_a_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[23] && x_s1_auto_out_1_a_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[24] && x_s1_auto_out_1_a_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[25] && x_s1_auto_out_1_a_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[26] && x_s1_auto_out_1_a_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[27] && x_s1_auto_out_1_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[28] && x_s1_auto_out_1_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[29] && x_s1_auto_out_1_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[30] && x_s1_auto_out_1_a_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[31] && x_s1_auto_out_1_a_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[32] && x_s1_auto_out_1_a_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[33] && x_s1_auto_out_1_a_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[34] && x_s1_auto_out_1_a_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[35] && x_s1_auto_out_1_a_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[36] && x_s1_auto_out_1_a_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[37] && x_s1_auto_out_1_a_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[38] && x_s1_auto_out_1_a_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[39] && x_s1_auto_out_1_a_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[40] && x_s1_auto_out_1_a_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[41] && x_s1_auto_out_1_a_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[42] && x_s1_auto_out_1_a_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[43] && x_s1_auto_out_1_a_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[44] && x_s1_auto_out_1_a_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[45] && x_s1_auto_out_1_a_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[46] && x_s1_auto_out_1_a_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_address[47] && x_s1_auto_out_1_a_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_reqSource[0] && x_s1_auto_out_1_a_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_reqSource[1] && x_s1_auto_out_1_a_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_reqSource[2] && x_s1_auto_out_1_a_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_reqSource[3] && x_s1_auto_out_1_a_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_reqSource[4] && x_s1_auto_out_1_a_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_alias[0] && x_s1_auto_out_1_a_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_alias[1] && x_s1_auto_out_1_a_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[0] && x_s1_auto_out_1_a_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[1] && x_s1_auto_out_1_a_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[2] && x_s1_auto_out_1_a_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[3] && x_s1_auto_out_1_a_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[4] && x_s1_auto_out_1_a_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[5] && x_s1_auto_out_1_a_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[6] && x_s1_auto_out_1_a_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[7] && x_s1_auto_out_1_a_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[8] && x_s1_auto_out_1_a_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[9] && x_s1_auto_out_1_a_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[10] && x_s1_auto_out_1_a_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[11] && x_s1_auto_out_1_a_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[12] && x_s1_auto_out_1_a_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[13] && x_s1_auto_out_1_a_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[14] && x_s1_auto_out_1_a_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[15] && x_s1_auto_out_1_a_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[16] && x_s1_auto_out_1_a_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[17] && x_s1_auto_out_1_a_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[18] && x_s1_auto_out_1_a_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[19] && x_s1_auto_out_1_a_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[20] && x_s1_auto_out_1_a_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[21] && x_s1_auto_out_1_a_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[22] && x_s1_auto_out_1_a_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[23] && x_s1_auto_out_1_a_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[24] && x_s1_auto_out_1_a_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[25] && x_s1_auto_out_1_a_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[26] && x_s1_auto_out_1_a_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[27] && x_s1_auto_out_1_a_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[28] && x_s1_auto_out_1_a_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[29] && x_s1_auto_out_1_a_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[30] && x_s1_auto_out_1_a_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[31] && x_s1_auto_out_1_a_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[32] && x_s1_auto_out_1_a_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[33] && x_s1_auto_out_1_a_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[34] && x_s1_auto_out_1_a_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[35] && x_s1_auto_out_1_a_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[36] && x_s1_auto_out_1_a_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[37] && x_s1_auto_out_1_a_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[38] && x_s1_auto_out_1_a_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[39] && x_s1_auto_out_1_a_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[40] && x_s1_auto_out_1_a_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[41] && x_s1_auto_out_1_a_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[42] && x_s1_auto_out_1_a_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_vaddr[43] && x_s1_auto_out_1_a_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_user_needHint && x_s1_auto_out_1_a_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_echo_isKeyword && x_s1_auto_out_1_a_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[0] && x_s1_auto_out_1_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[1] && x_s1_auto_out_1_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[2] && x_s1_auto_out_1_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[3] && x_s1_auto_out_1_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[4] && x_s1_auto_out_1_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[5] && x_s1_auto_out_1_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[6] && x_s1_auto_out_1_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[7] && x_s1_auto_out_1_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[8] && x_s1_auto_out_1_a_bits_mask[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[9] && x_s1_auto_out_1_a_bits_mask[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[10] && x_s1_auto_out_1_a_bits_mask[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[11] && x_s1_auto_out_1_a_bits_mask[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[12] && x_s1_auto_out_1_a_bits_mask[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[13] && x_s1_auto_out_1_a_bits_mask[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[14] && x_s1_auto_out_1_a_bits_mask[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[15] && x_s1_auto_out_1_a_bits_mask[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[16] && x_s1_auto_out_1_a_bits_mask[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[17] && x_s1_auto_out_1_a_bits_mask[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[18] && x_s1_auto_out_1_a_bits_mask[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[19] && x_s1_auto_out_1_a_bits_mask[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[20] && x_s1_auto_out_1_a_bits_mask[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[21] && x_s1_auto_out_1_a_bits_mask[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[22] && x_s1_auto_out_1_a_bits_mask[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[23] && x_s1_auto_out_1_a_bits_mask[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[24] && x_s1_auto_out_1_a_bits_mask[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[25] && x_s1_auto_out_1_a_bits_mask[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[26] && x_s1_auto_out_1_a_bits_mask[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[27] && x_s1_auto_out_1_a_bits_mask[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[28] && x_s1_auto_out_1_a_bits_mask[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[29] && x_s1_auto_out_1_a_bits_mask[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[30] && x_s1_auto_out_1_a_bits_mask[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_mask[31] && x_s1_auto_out_1_a_bits_mask[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_mask[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[0] && x_s1_auto_out_1_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[1] && x_s1_auto_out_1_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[2] && x_s1_auto_out_1_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[3] && x_s1_auto_out_1_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[4] && x_s1_auto_out_1_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[5] && x_s1_auto_out_1_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[6] && x_s1_auto_out_1_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[7] && x_s1_auto_out_1_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[8] && x_s1_auto_out_1_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[9] && x_s1_auto_out_1_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[10] && x_s1_auto_out_1_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[11] && x_s1_auto_out_1_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[12] && x_s1_auto_out_1_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[13] && x_s1_auto_out_1_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[14] && x_s1_auto_out_1_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[15] && x_s1_auto_out_1_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[16] && x_s1_auto_out_1_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[17] && x_s1_auto_out_1_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[18] && x_s1_auto_out_1_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[19] && x_s1_auto_out_1_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[20] && x_s1_auto_out_1_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[21] && x_s1_auto_out_1_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[22] && x_s1_auto_out_1_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[23] && x_s1_auto_out_1_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[24] && x_s1_auto_out_1_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[25] && x_s1_auto_out_1_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[26] && x_s1_auto_out_1_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[27] && x_s1_auto_out_1_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[28] && x_s1_auto_out_1_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[29] && x_s1_auto_out_1_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[30] && x_s1_auto_out_1_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[31] && x_s1_auto_out_1_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[32] && x_s1_auto_out_1_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[33] && x_s1_auto_out_1_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[34] && x_s1_auto_out_1_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[35] && x_s1_auto_out_1_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[36] && x_s1_auto_out_1_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[37] && x_s1_auto_out_1_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[38] && x_s1_auto_out_1_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[39] && x_s1_auto_out_1_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[40] && x_s1_auto_out_1_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[41] && x_s1_auto_out_1_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[42] && x_s1_auto_out_1_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[43] && x_s1_auto_out_1_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[44] && x_s1_auto_out_1_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[45] && x_s1_auto_out_1_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[46] && x_s1_auto_out_1_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[47] && x_s1_auto_out_1_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[48] && x_s1_auto_out_1_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[49] && x_s1_auto_out_1_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[50] && x_s1_auto_out_1_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[51] && x_s1_auto_out_1_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[52] && x_s1_auto_out_1_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[53] && x_s1_auto_out_1_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[54] && x_s1_auto_out_1_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[55] && x_s1_auto_out_1_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[56] && x_s1_auto_out_1_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[57] && x_s1_auto_out_1_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[58] && x_s1_auto_out_1_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[59] && x_s1_auto_out_1_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[60] && x_s1_auto_out_1_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[61] && x_s1_auto_out_1_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[62] && x_s1_auto_out_1_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[63] && x_s1_auto_out_1_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[64] && x_s1_auto_out_1_a_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[65] && x_s1_auto_out_1_a_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[66] && x_s1_auto_out_1_a_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[67] && x_s1_auto_out_1_a_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[68] && x_s1_auto_out_1_a_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[69] && x_s1_auto_out_1_a_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[70] && x_s1_auto_out_1_a_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[71] && x_s1_auto_out_1_a_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[72] && x_s1_auto_out_1_a_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[73] && x_s1_auto_out_1_a_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[74] && x_s1_auto_out_1_a_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[75] && x_s1_auto_out_1_a_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[76] && x_s1_auto_out_1_a_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[77] && x_s1_auto_out_1_a_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[78] && x_s1_auto_out_1_a_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[79] && x_s1_auto_out_1_a_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[80] && x_s1_auto_out_1_a_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[81] && x_s1_auto_out_1_a_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[82] && x_s1_auto_out_1_a_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[83] && x_s1_auto_out_1_a_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[84] && x_s1_auto_out_1_a_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[85] && x_s1_auto_out_1_a_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[86] && x_s1_auto_out_1_a_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[87] && x_s1_auto_out_1_a_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[88] && x_s1_auto_out_1_a_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[89] && x_s1_auto_out_1_a_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[90] && x_s1_auto_out_1_a_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[91] && x_s1_auto_out_1_a_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[92] && x_s1_auto_out_1_a_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[93] && x_s1_auto_out_1_a_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[94] && x_s1_auto_out_1_a_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[95] && x_s1_auto_out_1_a_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[96] && x_s1_auto_out_1_a_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[97] && x_s1_auto_out_1_a_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[98] && x_s1_auto_out_1_a_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[99] && x_s1_auto_out_1_a_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[100] && x_s1_auto_out_1_a_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[101] && x_s1_auto_out_1_a_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[102] && x_s1_auto_out_1_a_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[103] && x_s1_auto_out_1_a_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[104] && x_s1_auto_out_1_a_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[105] && x_s1_auto_out_1_a_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[106] && x_s1_auto_out_1_a_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[107] && x_s1_auto_out_1_a_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[108] && x_s1_auto_out_1_a_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[109] && x_s1_auto_out_1_a_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[110] && x_s1_auto_out_1_a_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[111] && x_s1_auto_out_1_a_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[112] && x_s1_auto_out_1_a_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[113] && x_s1_auto_out_1_a_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[114] && x_s1_auto_out_1_a_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[115] && x_s1_auto_out_1_a_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[116] && x_s1_auto_out_1_a_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[117] && x_s1_auto_out_1_a_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[118] && x_s1_auto_out_1_a_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[119] && x_s1_auto_out_1_a_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[120] && x_s1_auto_out_1_a_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[121] && x_s1_auto_out_1_a_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[122] && x_s1_auto_out_1_a_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[123] && x_s1_auto_out_1_a_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[124] && x_s1_auto_out_1_a_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[125] && x_s1_auto_out_1_a_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[126] && x_s1_auto_out_1_a_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[127] && x_s1_auto_out_1_a_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[128] && x_s1_auto_out_1_a_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[129] && x_s1_auto_out_1_a_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[130] && x_s1_auto_out_1_a_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[131] && x_s1_auto_out_1_a_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[132] && x_s1_auto_out_1_a_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[133] && x_s1_auto_out_1_a_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[134] && x_s1_auto_out_1_a_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[135] && x_s1_auto_out_1_a_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[136] && x_s1_auto_out_1_a_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[137] && x_s1_auto_out_1_a_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[138] && x_s1_auto_out_1_a_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[139] && x_s1_auto_out_1_a_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[140] && x_s1_auto_out_1_a_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[141] && x_s1_auto_out_1_a_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[142] && x_s1_auto_out_1_a_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[143] && x_s1_auto_out_1_a_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[144] && x_s1_auto_out_1_a_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[145] && x_s1_auto_out_1_a_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[146] && x_s1_auto_out_1_a_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[147] && x_s1_auto_out_1_a_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[148] && x_s1_auto_out_1_a_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[149] && x_s1_auto_out_1_a_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[150] && x_s1_auto_out_1_a_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[151] && x_s1_auto_out_1_a_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[152] && x_s1_auto_out_1_a_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[153] && x_s1_auto_out_1_a_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[154] && x_s1_auto_out_1_a_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[155] && x_s1_auto_out_1_a_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[156] && x_s1_auto_out_1_a_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[157] && x_s1_auto_out_1_a_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[158] && x_s1_auto_out_1_a_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[159] && x_s1_auto_out_1_a_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[160] && x_s1_auto_out_1_a_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[161] && x_s1_auto_out_1_a_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[162] && x_s1_auto_out_1_a_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[163] && x_s1_auto_out_1_a_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[164] && x_s1_auto_out_1_a_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[165] && x_s1_auto_out_1_a_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[166] && x_s1_auto_out_1_a_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[167] && x_s1_auto_out_1_a_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[168] && x_s1_auto_out_1_a_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[169] && x_s1_auto_out_1_a_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[170] && x_s1_auto_out_1_a_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[171] && x_s1_auto_out_1_a_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[172] && x_s1_auto_out_1_a_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[173] && x_s1_auto_out_1_a_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[174] && x_s1_auto_out_1_a_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[175] && x_s1_auto_out_1_a_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[176] && x_s1_auto_out_1_a_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[177] && x_s1_auto_out_1_a_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[178] && x_s1_auto_out_1_a_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[179] && x_s1_auto_out_1_a_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[180] && x_s1_auto_out_1_a_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[181] && x_s1_auto_out_1_a_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[182] && x_s1_auto_out_1_a_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[183] && x_s1_auto_out_1_a_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[184] && x_s1_auto_out_1_a_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[185] && x_s1_auto_out_1_a_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[186] && x_s1_auto_out_1_a_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[187] && x_s1_auto_out_1_a_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[188] && x_s1_auto_out_1_a_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[189] && x_s1_auto_out_1_a_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[190] && x_s1_auto_out_1_a_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[191] && x_s1_auto_out_1_a_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[192] && x_s1_auto_out_1_a_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[193] && x_s1_auto_out_1_a_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[194] && x_s1_auto_out_1_a_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[195] && x_s1_auto_out_1_a_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[196] && x_s1_auto_out_1_a_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[197] && x_s1_auto_out_1_a_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[198] && x_s1_auto_out_1_a_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[199] && x_s1_auto_out_1_a_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[200] && x_s1_auto_out_1_a_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[201] && x_s1_auto_out_1_a_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[202] && x_s1_auto_out_1_a_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[203] && x_s1_auto_out_1_a_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[204] && x_s1_auto_out_1_a_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[205] && x_s1_auto_out_1_a_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[206] && x_s1_auto_out_1_a_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[207] && x_s1_auto_out_1_a_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[208] && x_s1_auto_out_1_a_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[209] && x_s1_auto_out_1_a_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[210] && x_s1_auto_out_1_a_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[211] && x_s1_auto_out_1_a_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[212] && x_s1_auto_out_1_a_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[213] && x_s1_auto_out_1_a_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[214] && x_s1_auto_out_1_a_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[215] && x_s1_auto_out_1_a_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[216] && x_s1_auto_out_1_a_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[217] && x_s1_auto_out_1_a_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[218] && x_s1_auto_out_1_a_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[219] && x_s1_auto_out_1_a_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[220] && x_s1_auto_out_1_a_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[221] && x_s1_auto_out_1_a_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[222] && x_s1_auto_out_1_a_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[223] && x_s1_auto_out_1_a_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[224] && x_s1_auto_out_1_a_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[225] && x_s1_auto_out_1_a_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[226] && x_s1_auto_out_1_a_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[227] && x_s1_auto_out_1_a_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[228] && x_s1_auto_out_1_a_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[229] && x_s1_auto_out_1_a_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[230] && x_s1_auto_out_1_a_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[231] && x_s1_auto_out_1_a_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[232] && x_s1_auto_out_1_a_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[233] && x_s1_auto_out_1_a_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[234] && x_s1_auto_out_1_a_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[235] && x_s1_auto_out_1_a_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[236] && x_s1_auto_out_1_a_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[237] && x_s1_auto_out_1_a_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[238] && x_s1_auto_out_1_a_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[239] && x_s1_auto_out_1_a_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[240] && x_s1_auto_out_1_a_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[241] && x_s1_auto_out_1_a_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[242] && x_s1_auto_out_1_a_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[243] && x_s1_auto_out_1_a_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[244] && x_s1_auto_out_1_a_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[245] && x_s1_auto_out_1_a_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[246] && x_s1_auto_out_1_a_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[247] && x_s1_auto_out_1_a_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[248] && x_s1_auto_out_1_a_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[249] && x_s1_auto_out_1_a_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[250] && x_s1_auto_out_1_a_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[251] && x_s1_auto_out_1_a_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[252] && x_s1_auto_out_1_a_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[253] && x_s1_auto_out_1_a_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[254] && x_s1_auto_out_1_a_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_data[255] && x_s1_auto_out_1_a_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_a_bits_corrupt && x_s1_auto_out_1_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_b_ready && x_s1_auto_out_1_b_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_b_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_valid && x_s1_auto_out_1_c_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_opcode[0] && x_s1_auto_out_1_c_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_opcode[1] && x_s1_auto_out_1_c_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_opcode[2] && x_s1_auto_out_1_c_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_param[0] && x_s1_auto_out_1_c_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_param[1] && x_s1_auto_out_1_c_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_param[2] && x_s1_auto_out_1_c_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_size[0] && x_s1_auto_out_1_c_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_size[1] && x_s1_auto_out_1_c_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_size[2] && x_s1_auto_out_1_c_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[0] && x_s1_auto_out_1_c_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[1] && x_s1_auto_out_1_c_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[2] && x_s1_auto_out_1_c_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[3] && x_s1_auto_out_1_c_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[4] && x_s1_auto_out_1_c_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_source[5] && x_s1_auto_out_1_c_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[0] && x_s1_auto_out_1_c_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[1] && x_s1_auto_out_1_c_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[2] && x_s1_auto_out_1_c_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[3] && x_s1_auto_out_1_c_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[4] && x_s1_auto_out_1_c_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[5] && x_s1_auto_out_1_c_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[6] && x_s1_auto_out_1_c_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[7] && x_s1_auto_out_1_c_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[8] && x_s1_auto_out_1_c_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[9] && x_s1_auto_out_1_c_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[10] && x_s1_auto_out_1_c_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[11] && x_s1_auto_out_1_c_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[12] && x_s1_auto_out_1_c_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[13] && x_s1_auto_out_1_c_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[14] && x_s1_auto_out_1_c_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[15] && x_s1_auto_out_1_c_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[16] && x_s1_auto_out_1_c_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[17] && x_s1_auto_out_1_c_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[18] && x_s1_auto_out_1_c_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[19] && x_s1_auto_out_1_c_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[20] && x_s1_auto_out_1_c_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[21] && x_s1_auto_out_1_c_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[22] && x_s1_auto_out_1_c_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[23] && x_s1_auto_out_1_c_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[24] && x_s1_auto_out_1_c_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[25] && x_s1_auto_out_1_c_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[26] && x_s1_auto_out_1_c_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[27] && x_s1_auto_out_1_c_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[28] && x_s1_auto_out_1_c_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[29] && x_s1_auto_out_1_c_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[30] && x_s1_auto_out_1_c_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[31] && x_s1_auto_out_1_c_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[32] && x_s1_auto_out_1_c_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[33] && x_s1_auto_out_1_c_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[34] && x_s1_auto_out_1_c_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[35] && x_s1_auto_out_1_c_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[36] && x_s1_auto_out_1_c_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[37] && x_s1_auto_out_1_c_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[38] && x_s1_auto_out_1_c_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[39] && x_s1_auto_out_1_c_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[40] && x_s1_auto_out_1_c_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[41] && x_s1_auto_out_1_c_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[42] && x_s1_auto_out_1_c_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[43] && x_s1_auto_out_1_c_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[44] && x_s1_auto_out_1_c_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[45] && x_s1_auto_out_1_c_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[46] && x_s1_auto_out_1_c_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_address[47] && x_s1_auto_out_1_c_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_reqSource[0] && x_s1_auto_out_1_c_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_reqSource[1] && x_s1_auto_out_1_c_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_reqSource[2] && x_s1_auto_out_1_c_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_reqSource[3] && x_s1_auto_out_1_c_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_reqSource[4] && x_s1_auto_out_1_c_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_alias[0] && x_s1_auto_out_1_c_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_alias[1] && x_s1_auto_out_1_c_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[0] && x_s1_auto_out_1_c_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[1] && x_s1_auto_out_1_c_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[2] && x_s1_auto_out_1_c_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[3] && x_s1_auto_out_1_c_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[4] && x_s1_auto_out_1_c_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[5] && x_s1_auto_out_1_c_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[6] && x_s1_auto_out_1_c_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[7] && x_s1_auto_out_1_c_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[8] && x_s1_auto_out_1_c_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[9] && x_s1_auto_out_1_c_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[10] && x_s1_auto_out_1_c_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[11] && x_s1_auto_out_1_c_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[12] && x_s1_auto_out_1_c_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[13] && x_s1_auto_out_1_c_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[14] && x_s1_auto_out_1_c_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[15] && x_s1_auto_out_1_c_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[16] && x_s1_auto_out_1_c_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[17] && x_s1_auto_out_1_c_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[18] && x_s1_auto_out_1_c_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[19] && x_s1_auto_out_1_c_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[20] && x_s1_auto_out_1_c_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[21] && x_s1_auto_out_1_c_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[22] && x_s1_auto_out_1_c_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[23] && x_s1_auto_out_1_c_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[24] && x_s1_auto_out_1_c_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[25] && x_s1_auto_out_1_c_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[26] && x_s1_auto_out_1_c_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[27] && x_s1_auto_out_1_c_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[28] && x_s1_auto_out_1_c_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[29] && x_s1_auto_out_1_c_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[30] && x_s1_auto_out_1_c_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[31] && x_s1_auto_out_1_c_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[32] && x_s1_auto_out_1_c_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[33] && x_s1_auto_out_1_c_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[34] && x_s1_auto_out_1_c_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[35] && x_s1_auto_out_1_c_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[36] && x_s1_auto_out_1_c_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[37] && x_s1_auto_out_1_c_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[38] && x_s1_auto_out_1_c_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[39] && x_s1_auto_out_1_c_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[40] && x_s1_auto_out_1_c_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[41] && x_s1_auto_out_1_c_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[42] && x_s1_auto_out_1_c_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_vaddr[43] && x_s1_auto_out_1_c_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_user_needHint && x_s1_auto_out_1_c_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_echo_isKeyword && x_s1_auto_out_1_c_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[0] && x_s1_auto_out_1_c_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[1] && x_s1_auto_out_1_c_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[2] && x_s1_auto_out_1_c_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[3] && x_s1_auto_out_1_c_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[4] && x_s1_auto_out_1_c_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[5] && x_s1_auto_out_1_c_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[6] && x_s1_auto_out_1_c_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[7] && x_s1_auto_out_1_c_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[8] && x_s1_auto_out_1_c_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[9] && x_s1_auto_out_1_c_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[10] && x_s1_auto_out_1_c_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[11] && x_s1_auto_out_1_c_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[12] && x_s1_auto_out_1_c_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[13] && x_s1_auto_out_1_c_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[14] && x_s1_auto_out_1_c_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[15] && x_s1_auto_out_1_c_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[16] && x_s1_auto_out_1_c_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[17] && x_s1_auto_out_1_c_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[18] && x_s1_auto_out_1_c_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[19] && x_s1_auto_out_1_c_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[20] && x_s1_auto_out_1_c_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[21] && x_s1_auto_out_1_c_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[22] && x_s1_auto_out_1_c_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[23] && x_s1_auto_out_1_c_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[24] && x_s1_auto_out_1_c_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[25] && x_s1_auto_out_1_c_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[26] && x_s1_auto_out_1_c_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[27] && x_s1_auto_out_1_c_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[28] && x_s1_auto_out_1_c_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[29] && x_s1_auto_out_1_c_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[30] && x_s1_auto_out_1_c_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[31] && x_s1_auto_out_1_c_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[32] && x_s1_auto_out_1_c_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[33] && x_s1_auto_out_1_c_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[34] && x_s1_auto_out_1_c_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[35] && x_s1_auto_out_1_c_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[36] && x_s1_auto_out_1_c_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[37] && x_s1_auto_out_1_c_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[38] && x_s1_auto_out_1_c_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[39] && x_s1_auto_out_1_c_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[40] && x_s1_auto_out_1_c_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[41] && x_s1_auto_out_1_c_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[42] && x_s1_auto_out_1_c_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[43] && x_s1_auto_out_1_c_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[44] && x_s1_auto_out_1_c_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[45] && x_s1_auto_out_1_c_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[46] && x_s1_auto_out_1_c_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[47] && x_s1_auto_out_1_c_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[48] && x_s1_auto_out_1_c_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[49] && x_s1_auto_out_1_c_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[50] && x_s1_auto_out_1_c_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[51] && x_s1_auto_out_1_c_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[52] && x_s1_auto_out_1_c_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[53] && x_s1_auto_out_1_c_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[54] && x_s1_auto_out_1_c_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[55] && x_s1_auto_out_1_c_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[56] && x_s1_auto_out_1_c_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[57] && x_s1_auto_out_1_c_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[58] && x_s1_auto_out_1_c_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[59] && x_s1_auto_out_1_c_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[60] && x_s1_auto_out_1_c_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[61] && x_s1_auto_out_1_c_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[62] && x_s1_auto_out_1_c_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[63] && x_s1_auto_out_1_c_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[64] && x_s1_auto_out_1_c_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[65] && x_s1_auto_out_1_c_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[66] && x_s1_auto_out_1_c_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[67] && x_s1_auto_out_1_c_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[68] && x_s1_auto_out_1_c_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[69] && x_s1_auto_out_1_c_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[70] && x_s1_auto_out_1_c_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[71] && x_s1_auto_out_1_c_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[72] && x_s1_auto_out_1_c_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[73] && x_s1_auto_out_1_c_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[74] && x_s1_auto_out_1_c_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[75] && x_s1_auto_out_1_c_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[76] && x_s1_auto_out_1_c_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[77] && x_s1_auto_out_1_c_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[78] && x_s1_auto_out_1_c_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[79] && x_s1_auto_out_1_c_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[80] && x_s1_auto_out_1_c_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[81] && x_s1_auto_out_1_c_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[82] && x_s1_auto_out_1_c_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[83] && x_s1_auto_out_1_c_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[84] && x_s1_auto_out_1_c_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[85] && x_s1_auto_out_1_c_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[86] && x_s1_auto_out_1_c_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[87] && x_s1_auto_out_1_c_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[88] && x_s1_auto_out_1_c_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[89] && x_s1_auto_out_1_c_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[90] && x_s1_auto_out_1_c_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[91] && x_s1_auto_out_1_c_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[92] && x_s1_auto_out_1_c_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[93] && x_s1_auto_out_1_c_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[94] && x_s1_auto_out_1_c_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[95] && x_s1_auto_out_1_c_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[96] && x_s1_auto_out_1_c_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[97] && x_s1_auto_out_1_c_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[98] && x_s1_auto_out_1_c_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[99] && x_s1_auto_out_1_c_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[100] && x_s1_auto_out_1_c_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[101] && x_s1_auto_out_1_c_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[102] && x_s1_auto_out_1_c_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[103] && x_s1_auto_out_1_c_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[104] && x_s1_auto_out_1_c_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[105] && x_s1_auto_out_1_c_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[106] && x_s1_auto_out_1_c_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[107] && x_s1_auto_out_1_c_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[108] && x_s1_auto_out_1_c_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[109] && x_s1_auto_out_1_c_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[110] && x_s1_auto_out_1_c_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[111] && x_s1_auto_out_1_c_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[112] && x_s1_auto_out_1_c_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[113] && x_s1_auto_out_1_c_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[114] && x_s1_auto_out_1_c_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[115] && x_s1_auto_out_1_c_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[116] && x_s1_auto_out_1_c_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[117] && x_s1_auto_out_1_c_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[118] && x_s1_auto_out_1_c_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[119] && x_s1_auto_out_1_c_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[120] && x_s1_auto_out_1_c_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[121] && x_s1_auto_out_1_c_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[122] && x_s1_auto_out_1_c_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[123] && x_s1_auto_out_1_c_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[124] && x_s1_auto_out_1_c_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[125] && x_s1_auto_out_1_c_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[126] && x_s1_auto_out_1_c_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[127] && x_s1_auto_out_1_c_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[128] && x_s1_auto_out_1_c_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[129] && x_s1_auto_out_1_c_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[130] && x_s1_auto_out_1_c_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[131] && x_s1_auto_out_1_c_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[132] && x_s1_auto_out_1_c_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[133] && x_s1_auto_out_1_c_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[134] && x_s1_auto_out_1_c_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[135] && x_s1_auto_out_1_c_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[136] && x_s1_auto_out_1_c_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[137] && x_s1_auto_out_1_c_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[138] && x_s1_auto_out_1_c_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[139] && x_s1_auto_out_1_c_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[140] && x_s1_auto_out_1_c_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[141] && x_s1_auto_out_1_c_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[142] && x_s1_auto_out_1_c_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[143] && x_s1_auto_out_1_c_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[144] && x_s1_auto_out_1_c_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[145] && x_s1_auto_out_1_c_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[146] && x_s1_auto_out_1_c_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[147] && x_s1_auto_out_1_c_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[148] && x_s1_auto_out_1_c_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[149] && x_s1_auto_out_1_c_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[150] && x_s1_auto_out_1_c_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[151] && x_s1_auto_out_1_c_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[152] && x_s1_auto_out_1_c_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[153] && x_s1_auto_out_1_c_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[154] && x_s1_auto_out_1_c_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[155] && x_s1_auto_out_1_c_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[156] && x_s1_auto_out_1_c_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[157] && x_s1_auto_out_1_c_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[158] && x_s1_auto_out_1_c_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[159] && x_s1_auto_out_1_c_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[160] && x_s1_auto_out_1_c_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[161] && x_s1_auto_out_1_c_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[162] && x_s1_auto_out_1_c_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[163] && x_s1_auto_out_1_c_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[164] && x_s1_auto_out_1_c_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[165] && x_s1_auto_out_1_c_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[166] && x_s1_auto_out_1_c_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[167] && x_s1_auto_out_1_c_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[168] && x_s1_auto_out_1_c_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[169] && x_s1_auto_out_1_c_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[170] && x_s1_auto_out_1_c_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[171] && x_s1_auto_out_1_c_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[172] && x_s1_auto_out_1_c_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[173] && x_s1_auto_out_1_c_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[174] && x_s1_auto_out_1_c_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[175] && x_s1_auto_out_1_c_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[176] && x_s1_auto_out_1_c_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[177] && x_s1_auto_out_1_c_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[178] && x_s1_auto_out_1_c_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[179] && x_s1_auto_out_1_c_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[180] && x_s1_auto_out_1_c_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[181] && x_s1_auto_out_1_c_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[182] && x_s1_auto_out_1_c_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[183] && x_s1_auto_out_1_c_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[184] && x_s1_auto_out_1_c_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[185] && x_s1_auto_out_1_c_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[186] && x_s1_auto_out_1_c_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[187] && x_s1_auto_out_1_c_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[188] && x_s1_auto_out_1_c_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[189] && x_s1_auto_out_1_c_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[190] && x_s1_auto_out_1_c_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[191] && x_s1_auto_out_1_c_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[192] && x_s1_auto_out_1_c_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[193] && x_s1_auto_out_1_c_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[194] && x_s1_auto_out_1_c_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[195] && x_s1_auto_out_1_c_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[196] && x_s1_auto_out_1_c_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[197] && x_s1_auto_out_1_c_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[198] && x_s1_auto_out_1_c_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[199] && x_s1_auto_out_1_c_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[200] && x_s1_auto_out_1_c_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[201] && x_s1_auto_out_1_c_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[202] && x_s1_auto_out_1_c_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[203] && x_s1_auto_out_1_c_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[204] && x_s1_auto_out_1_c_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[205] && x_s1_auto_out_1_c_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[206] && x_s1_auto_out_1_c_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[207] && x_s1_auto_out_1_c_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[208] && x_s1_auto_out_1_c_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[209] && x_s1_auto_out_1_c_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[210] && x_s1_auto_out_1_c_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[211] && x_s1_auto_out_1_c_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[212] && x_s1_auto_out_1_c_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[213] && x_s1_auto_out_1_c_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[214] && x_s1_auto_out_1_c_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[215] && x_s1_auto_out_1_c_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[216] && x_s1_auto_out_1_c_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[217] && x_s1_auto_out_1_c_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[218] && x_s1_auto_out_1_c_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[219] && x_s1_auto_out_1_c_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[220] && x_s1_auto_out_1_c_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[221] && x_s1_auto_out_1_c_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[222] && x_s1_auto_out_1_c_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[223] && x_s1_auto_out_1_c_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[224] && x_s1_auto_out_1_c_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[225] && x_s1_auto_out_1_c_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[226] && x_s1_auto_out_1_c_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[227] && x_s1_auto_out_1_c_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[228] && x_s1_auto_out_1_c_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[229] && x_s1_auto_out_1_c_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[230] && x_s1_auto_out_1_c_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[231] && x_s1_auto_out_1_c_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[232] && x_s1_auto_out_1_c_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[233] && x_s1_auto_out_1_c_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[234] && x_s1_auto_out_1_c_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[235] && x_s1_auto_out_1_c_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[236] && x_s1_auto_out_1_c_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[237] && x_s1_auto_out_1_c_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[238] && x_s1_auto_out_1_c_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[239] && x_s1_auto_out_1_c_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[240] && x_s1_auto_out_1_c_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[241] && x_s1_auto_out_1_c_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[242] && x_s1_auto_out_1_c_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[243] && x_s1_auto_out_1_c_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[244] && x_s1_auto_out_1_c_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[245] && x_s1_auto_out_1_c_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[246] && x_s1_auto_out_1_c_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[247] && x_s1_auto_out_1_c_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[248] && x_s1_auto_out_1_c_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[249] && x_s1_auto_out_1_c_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[250] && x_s1_auto_out_1_c_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[251] && x_s1_auto_out_1_c_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[252] && x_s1_auto_out_1_c_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[253] && x_s1_auto_out_1_c_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[254] && x_s1_auto_out_1_c_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_data[255] && x_s1_auto_out_1_c_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_c_bits_corrupt && x_s1_auto_out_1_c_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_c_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_d_ready && x_s1_auto_out_1_d_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_valid && x_s1_auto_out_1_e_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[0] && x_s1_auto_out_1_e_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[1] && x_s1_auto_out_1_e_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[2] && x_s1_auto_out_1_e_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[3] && x_s1_auto_out_1_e_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[4] && x_s1_auto_out_1_e_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[5] && x_s1_auto_out_1_e_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[6] && x_s1_auto_out_1_e_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_1_e_bits_sink[7] && x_s1_auto_out_1_e_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_1_e_bits_sink[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_valid && x_s1_auto_out_0_a_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[0] && x_s1_auto_out_0_a_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[1] && x_s1_auto_out_0_a_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[2] && x_s1_auto_out_0_a_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_opcode[3] && x_s1_auto_out_0_a_bits_opcode[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_opcode[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[0] && x_s1_auto_out_0_a_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[1] && x_s1_auto_out_0_a_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_param[2] && x_s1_auto_out_0_a_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_size[0] && x_s1_auto_out_0_a_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_size[1] && x_s1_auto_out_0_a_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_size[2] && x_s1_auto_out_0_a_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[0] && x_s1_auto_out_0_a_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[1] && x_s1_auto_out_0_a_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[2] && x_s1_auto_out_0_a_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[3] && x_s1_auto_out_0_a_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[4] && x_s1_auto_out_0_a_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[5] && x_s1_auto_out_0_a_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_source[6] && x_s1_auto_out_0_a_bits_source[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_source[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[0] && x_s1_auto_out_0_a_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[1] && x_s1_auto_out_0_a_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[2] && x_s1_auto_out_0_a_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[3] && x_s1_auto_out_0_a_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[4] && x_s1_auto_out_0_a_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[5] && x_s1_auto_out_0_a_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[6] && x_s1_auto_out_0_a_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[7] && x_s1_auto_out_0_a_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[8] && x_s1_auto_out_0_a_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[9] && x_s1_auto_out_0_a_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[10] && x_s1_auto_out_0_a_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[11] && x_s1_auto_out_0_a_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[12] && x_s1_auto_out_0_a_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[13] && x_s1_auto_out_0_a_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[14] && x_s1_auto_out_0_a_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[15] && x_s1_auto_out_0_a_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[16] && x_s1_auto_out_0_a_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[17] && x_s1_auto_out_0_a_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[18] && x_s1_auto_out_0_a_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[19] && x_s1_auto_out_0_a_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[20] && x_s1_auto_out_0_a_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[21] && x_s1_auto_out_0_a_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[22] && x_s1_auto_out_0_a_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[23] && x_s1_auto_out_0_a_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[24] && x_s1_auto_out_0_a_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[25] && x_s1_auto_out_0_a_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[26] && x_s1_auto_out_0_a_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[27] && x_s1_auto_out_0_a_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[28] && x_s1_auto_out_0_a_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[29] && x_s1_auto_out_0_a_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[30] && x_s1_auto_out_0_a_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[31] && x_s1_auto_out_0_a_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[32] && x_s1_auto_out_0_a_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[33] && x_s1_auto_out_0_a_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[34] && x_s1_auto_out_0_a_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[35] && x_s1_auto_out_0_a_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[36] && x_s1_auto_out_0_a_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[37] && x_s1_auto_out_0_a_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[38] && x_s1_auto_out_0_a_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[39] && x_s1_auto_out_0_a_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[40] && x_s1_auto_out_0_a_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[41] && x_s1_auto_out_0_a_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[42] && x_s1_auto_out_0_a_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[43] && x_s1_auto_out_0_a_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[44] && x_s1_auto_out_0_a_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[45] && x_s1_auto_out_0_a_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[46] && x_s1_auto_out_0_a_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_address[47] && x_s1_auto_out_0_a_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_reqSource[0] && x_s1_auto_out_0_a_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_reqSource[1] && x_s1_auto_out_0_a_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_reqSource[2] && x_s1_auto_out_0_a_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_reqSource[3] && x_s1_auto_out_0_a_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_reqSource[4] && x_s1_auto_out_0_a_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_alias[0] && x_s1_auto_out_0_a_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_alias[1] && x_s1_auto_out_0_a_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[0] && x_s1_auto_out_0_a_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[1] && x_s1_auto_out_0_a_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[2] && x_s1_auto_out_0_a_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[3] && x_s1_auto_out_0_a_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[4] && x_s1_auto_out_0_a_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[5] && x_s1_auto_out_0_a_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[6] && x_s1_auto_out_0_a_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[7] && x_s1_auto_out_0_a_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[8] && x_s1_auto_out_0_a_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[9] && x_s1_auto_out_0_a_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[10] && x_s1_auto_out_0_a_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[11] && x_s1_auto_out_0_a_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[12] && x_s1_auto_out_0_a_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[13] && x_s1_auto_out_0_a_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[14] && x_s1_auto_out_0_a_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[15] && x_s1_auto_out_0_a_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[16] && x_s1_auto_out_0_a_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[17] && x_s1_auto_out_0_a_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[18] && x_s1_auto_out_0_a_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[19] && x_s1_auto_out_0_a_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[20] && x_s1_auto_out_0_a_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[21] && x_s1_auto_out_0_a_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[22] && x_s1_auto_out_0_a_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[23] && x_s1_auto_out_0_a_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[24] && x_s1_auto_out_0_a_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[25] && x_s1_auto_out_0_a_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[26] && x_s1_auto_out_0_a_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[27] && x_s1_auto_out_0_a_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[28] && x_s1_auto_out_0_a_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[29] && x_s1_auto_out_0_a_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[30] && x_s1_auto_out_0_a_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[31] && x_s1_auto_out_0_a_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[32] && x_s1_auto_out_0_a_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[33] && x_s1_auto_out_0_a_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[34] && x_s1_auto_out_0_a_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[35] && x_s1_auto_out_0_a_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[36] && x_s1_auto_out_0_a_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[37] && x_s1_auto_out_0_a_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[38] && x_s1_auto_out_0_a_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[39] && x_s1_auto_out_0_a_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[40] && x_s1_auto_out_0_a_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[41] && x_s1_auto_out_0_a_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[42] && x_s1_auto_out_0_a_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_vaddr[43] && x_s1_auto_out_0_a_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_user_needHint && x_s1_auto_out_0_a_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_echo_isKeyword && x_s1_auto_out_0_a_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[0] && x_s1_auto_out_0_a_bits_mask[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[1] && x_s1_auto_out_0_a_bits_mask[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[2] && x_s1_auto_out_0_a_bits_mask[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[3] && x_s1_auto_out_0_a_bits_mask[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[4] && x_s1_auto_out_0_a_bits_mask[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[5] && x_s1_auto_out_0_a_bits_mask[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[6] && x_s1_auto_out_0_a_bits_mask[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[7] && x_s1_auto_out_0_a_bits_mask[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[8] && x_s1_auto_out_0_a_bits_mask[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[9] && x_s1_auto_out_0_a_bits_mask[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[10] && x_s1_auto_out_0_a_bits_mask[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[11] && x_s1_auto_out_0_a_bits_mask[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[12] && x_s1_auto_out_0_a_bits_mask[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[13] && x_s1_auto_out_0_a_bits_mask[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[14] && x_s1_auto_out_0_a_bits_mask[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[15] && x_s1_auto_out_0_a_bits_mask[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[16] && x_s1_auto_out_0_a_bits_mask[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[17] && x_s1_auto_out_0_a_bits_mask[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[18] && x_s1_auto_out_0_a_bits_mask[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[19] && x_s1_auto_out_0_a_bits_mask[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[20] && x_s1_auto_out_0_a_bits_mask[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[21] && x_s1_auto_out_0_a_bits_mask[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[22] && x_s1_auto_out_0_a_bits_mask[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[23] && x_s1_auto_out_0_a_bits_mask[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[24] && x_s1_auto_out_0_a_bits_mask[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[25] && x_s1_auto_out_0_a_bits_mask[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[26] && x_s1_auto_out_0_a_bits_mask[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[27] && x_s1_auto_out_0_a_bits_mask[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[28] && x_s1_auto_out_0_a_bits_mask[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[29] && x_s1_auto_out_0_a_bits_mask[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[30] && x_s1_auto_out_0_a_bits_mask[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_mask[31] && x_s1_auto_out_0_a_bits_mask[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_mask[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[0] && x_s1_auto_out_0_a_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[1] && x_s1_auto_out_0_a_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[2] && x_s1_auto_out_0_a_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[3] && x_s1_auto_out_0_a_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[4] && x_s1_auto_out_0_a_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[5] && x_s1_auto_out_0_a_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[6] && x_s1_auto_out_0_a_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[7] && x_s1_auto_out_0_a_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[8] && x_s1_auto_out_0_a_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[9] && x_s1_auto_out_0_a_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[10] && x_s1_auto_out_0_a_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[11] && x_s1_auto_out_0_a_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[12] && x_s1_auto_out_0_a_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[13] && x_s1_auto_out_0_a_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[14] && x_s1_auto_out_0_a_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[15] && x_s1_auto_out_0_a_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[16] && x_s1_auto_out_0_a_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[17] && x_s1_auto_out_0_a_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[18] && x_s1_auto_out_0_a_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[19] && x_s1_auto_out_0_a_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[20] && x_s1_auto_out_0_a_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[21] && x_s1_auto_out_0_a_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[22] && x_s1_auto_out_0_a_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[23] && x_s1_auto_out_0_a_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[24] && x_s1_auto_out_0_a_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[25] && x_s1_auto_out_0_a_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[26] && x_s1_auto_out_0_a_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[27] && x_s1_auto_out_0_a_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[28] && x_s1_auto_out_0_a_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[29] && x_s1_auto_out_0_a_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[30] && x_s1_auto_out_0_a_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[31] && x_s1_auto_out_0_a_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[32] && x_s1_auto_out_0_a_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[33] && x_s1_auto_out_0_a_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[34] && x_s1_auto_out_0_a_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[35] && x_s1_auto_out_0_a_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[36] && x_s1_auto_out_0_a_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[37] && x_s1_auto_out_0_a_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[38] && x_s1_auto_out_0_a_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[39] && x_s1_auto_out_0_a_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[40] && x_s1_auto_out_0_a_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[41] && x_s1_auto_out_0_a_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[42] && x_s1_auto_out_0_a_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[43] && x_s1_auto_out_0_a_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[44] && x_s1_auto_out_0_a_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[45] && x_s1_auto_out_0_a_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[46] && x_s1_auto_out_0_a_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[47] && x_s1_auto_out_0_a_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[48] && x_s1_auto_out_0_a_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[49] && x_s1_auto_out_0_a_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[50] && x_s1_auto_out_0_a_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[51] && x_s1_auto_out_0_a_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[52] && x_s1_auto_out_0_a_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[53] && x_s1_auto_out_0_a_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[54] && x_s1_auto_out_0_a_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[55] && x_s1_auto_out_0_a_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[56] && x_s1_auto_out_0_a_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[57] && x_s1_auto_out_0_a_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[58] && x_s1_auto_out_0_a_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[59] && x_s1_auto_out_0_a_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[60] && x_s1_auto_out_0_a_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[61] && x_s1_auto_out_0_a_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[62] && x_s1_auto_out_0_a_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[63] && x_s1_auto_out_0_a_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[64] && x_s1_auto_out_0_a_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[65] && x_s1_auto_out_0_a_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[66] && x_s1_auto_out_0_a_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[67] && x_s1_auto_out_0_a_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[68] && x_s1_auto_out_0_a_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[69] && x_s1_auto_out_0_a_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[70] && x_s1_auto_out_0_a_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[71] && x_s1_auto_out_0_a_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[72] && x_s1_auto_out_0_a_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[73] && x_s1_auto_out_0_a_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[74] && x_s1_auto_out_0_a_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[75] && x_s1_auto_out_0_a_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[76] && x_s1_auto_out_0_a_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[77] && x_s1_auto_out_0_a_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[78] && x_s1_auto_out_0_a_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[79] && x_s1_auto_out_0_a_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[80] && x_s1_auto_out_0_a_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[81] && x_s1_auto_out_0_a_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[82] && x_s1_auto_out_0_a_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[83] && x_s1_auto_out_0_a_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[84] && x_s1_auto_out_0_a_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[85] && x_s1_auto_out_0_a_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[86] && x_s1_auto_out_0_a_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[87] && x_s1_auto_out_0_a_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[88] && x_s1_auto_out_0_a_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[89] && x_s1_auto_out_0_a_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[90] && x_s1_auto_out_0_a_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[91] && x_s1_auto_out_0_a_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[92] && x_s1_auto_out_0_a_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[93] && x_s1_auto_out_0_a_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[94] && x_s1_auto_out_0_a_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[95] && x_s1_auto_out_0_a_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[96] && x_s1_auto_out_0_a_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[97] && x_s1_auto_out_0_a_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[98] && x_s1_auto_out_0_a_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[99] && x_s1_auto_out_0_a_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[100] && x_s1_auto_out_0_a_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[101] && x_s1_auto_out_0_a_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[102] && x_s1_auto_out_0_a_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[103] && x_s1_auto_out_0_a_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[104] && x_s1_auto_out_0_a_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[105] && x_s1_auto_out_0_a_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[106] && x_s1_auto_out_0_a_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[107] && x_s1_auto_out_0_a_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[108] && x_s1_auto_out_0_a_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[109] && x_s1_auto_out_0_a_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[110] && x_s1_auto_out_0_a_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[111] && x_s1_auto_out_0_a_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[112] && x_s1_auto_out_0_a_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[113] && x_s1_auto_out_0_a_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[114] && x_s1_auto_out_0_a_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[115] && x_s1_auto_out_0_a_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[116] && x_s1_auto_out_0_a_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[117] && x_s1_auto_out_0_a_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[118] && x_s1_auto_out_0_a_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[119] && x_s1_auto_out_0_a_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[120] && x_s1_auto_out_0_a_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[121] && x_s1_auto_out_0_a_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[122] && x_s1_auto_out_0_a_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[123] && x_s1_auto_out_0_a_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[124] && x_s1_auto_out_0_a_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[125] && x_s1_auto_out_0_a_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[126] && x_s1_auto_out_0_a_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[127] && x_s1_auto_out_0_a_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[128] && x_s1_auto_out_0_a_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[129] && x_s1_auto_out_0_a_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[130] && x_s1_auto_out_0_a_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[131] && x_s1_auto_out_0_a_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[132] && x_s1_auto_out_0_a_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[133] && x_s1_auto_out_0_a_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[134] && x_s1_auto_out_0_a_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[135] && x_s1_auto_out_0_a_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[136] && x_s1_auto_out_0_a_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[137] && x_s1_auto_out_0_a_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[138] && x_s1_auto_out_0_a_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[139] && x_s1_auto_out_0_a_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[140] && x_s1_auto_out_0_a_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[141] && x_s1_auto_out_0_a_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[142] && x_s1_auto_out_0_a_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[143] && x_s1_auto_out_0_a_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[144] && x_s1_auto_out_0_a_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[145] && x_s1_auto_out_0_a_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[146] && x_s1_auto_out_0_a_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[147] && x_s1_auto_out_0_a_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[148] && x_s1_auto_out_0_a_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[149] && x_s1_auto_out_0_a_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[150] && x_s1_auto_out_0_a_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[151] && x_s1_auto_out_0_a_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[152] && x_s1_auto_out_0_a_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[153] && x_s1_auto_out_0_a_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[154] && x_s1_auto_out_0_a_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[155] && x_s1_auto_out_0_a_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[156] && x_s1_auto_out_0_a_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[157] && x_s1_auto_out_0_a_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[158] && x_s1_auto_out_0_a_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[159] && x_s1_auto_out_0_a_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[160] && x_s1_auto_out_0_a_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[161] && x_s1_auto_out_0_a_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[162] && x_s1_auto_out_0_a_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[163] && x_s1_auto_out_0_a_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[164] && x_s1_auto_out_0_a_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[165] && x_s1_auto_out_0_a_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[166] && x_s1_auto_out_0_a_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[167] && x_s1_auto_out_0_a_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[168] && x_s1_auto_out_0_a_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[169] && x_s1_auto_out_0_a_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[170] && x_s1_auto_out_0_a_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[171] && x_s1_auto_out_0_a_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[172] && x_s1_auto_out_0_a_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[173] && x_s1_auto_out_0_a_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[174] && x_s1_auto_out_0_a_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[175] && x_s1_auto_out_0_a_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[176] && x_s1_auto_out_0_a_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[177] && x_s1_auto_out_0_a_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[178] && x_s1_auto_out_0_a_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[179] && x_s1_auto_out_0_a_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[180] && x_s1_auto_out_0_a_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[181] && x_s1_auto_out_0_a_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[182] && x_s1_auto_out_0_a_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[183] && x_s1_auto_out_0_a_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[184] && x_s1_auto_out_0_a_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[185] && x_s1_auto_out_0_a_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[186] && x_s1_auto_out_0_a_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[187] && x_s1_auto_out_0_a_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[188] && x_s1_auto_out_0_a_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[189] && x_s1_auto_out_0_a_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[190] && x_s1_auto_out_0_a_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[191] && x_s1_auto_out_0_a_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[192] && x_s1_auto_out_0_a_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[193] && x_s1_auto_out_0_a_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[194] && x_s1_auto_out_0_a_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[195] && x_s1_auto_out_0_a_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[196] && x_s1_auto_out_0_a_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[197] && x_s1_auto_out_0_a_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[198] && x_s1_auto_out_0_a_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[199] && x_s1_auto_out_0_a_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[200] && x_s1_auto_out_0_a_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[201] && x_s1_auto_out_0_a_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[202] && x_s1_auto_out_0_a_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[203] && x_s1_auto_out_0_a_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[204] && x_s1_auto_out_0_a_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[205] && x_s1_auto_out_0_a_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[206] && x_s1_auto_out_0_a_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[207] && x_s1_auto_out_0_a_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[208] && x_s1_auto_out_0_a_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[209] && x_s1_auto_out_0_a_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[210] && x_s1_auto_out_0_a_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[211] && x_s1_auto_out_0_a_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[212] && x_s1_auto_out_0_a_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[213] && x_s1_auto_out_0_a_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[214] && x_s1_auto_out_0_a_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[215] && x_s1_auto_out_0_a_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[216] && x_s1_auto_out_0_a_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[217] && x_s1_auto_out_0_a_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[218] && x_s1_auto_out_0_a_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[219] && x_s1_auto_out_0_a_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[220] && x_s1_auto_out_0_a_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[221] && x_s1_auto_out_0_a_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[222] && x_s1_auto_out_0_a_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[223] && x_s1_auto_out_0_a_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[224] && x_s1_auto_out_0_a_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[225] && x_s1_auto_out_0_a_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[226] && x_s1_auto_out_0_a_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[227] && x_s1_auto_out_0_a_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[228] && x_s1_auto_out_0_a_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[229] && x_s1_auto_out_0_a_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[230] && x_s1_auto_out_0_a_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[231] && x_s1_auto_out_0_a_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[232] && x_s1_auto_out_0_a_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[233] && x_s1_auto_out_0_a_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[234] && x_s1_auto_out_0_a_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[235] && x_s1_auto_out_0_a_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[236] && x_s1_auto_out_0_a_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[237] && x_s1_auto_out_0_a_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[238] && x_s1_auto_out_0_a_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[239] && x_s1_auto_out_0_a_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[240] && x_s1_auto_out_0_a_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[241] && x_s1_auto_out_0_a_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[242] && x_s1_auto_out_0_a_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[243] && x_s1_auto_out_0_a_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[244] && x_s1_auto_out_0_a_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[245] && x_s1_auto_out_0_a_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[246] && x_s1_auto_out_0_a_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[247] && x_s1_auto_out_0_a_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[248] && x_s1_auto_out_0_a_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[249] && x_s1_auto_out_0_a_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[250] && x_s1_auto_out_0_a_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[251] && x_s1_auto_out_0_a_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[252] && x_s1_auto_out_0_a_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[253] && x_s1_auto_out_0_a_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[254] && x_s1_auto_out_0_a_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_data[255] && x_s1_auto_out_0_a_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_a_bits_corrupt && x_s1_auto_out_0_a_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_a_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_b_ready && x_s1_auto_out_0_b_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_b_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_valid && x_s1_auto_out_0_c_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_opcode[0] && x_s1_auto_out_0_c_bits_opcode[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_opcode[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_opcode[1] && x_s1_auto_out_0_c_bits_opcode[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_opcode[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_opcode[2] && x_s1_auto_out_0_c_bits_opcode[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_opcode[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_param[0] && x_s1_auto_out_0_c_bits_param[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_param[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_param[1] && x_s1_auto_out_0_c_bits_param[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_param[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_param[2] && x_s1_auto_out_0_c_bits_param[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_param[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_size[0] && x_s1_auto_out_0_c_bits_size[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_size[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_size[1] && x_s1_auto_out_0_c_bits_size[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_size[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_size[2] && x_s1_auto_out_0_c_bits_size[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_size[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[0] && x_s1_auto_out_0_c_bits_source[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[1] && x_s1_auto_out_0_c_bits_source[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[2] && x_s1_auto_out_0_c_bits_source[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[3] && x_s1_auto_out_0_c_bits_source[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[4] && x_s1_auto_out_0_c_bits_source[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_source[5] && x_s1_auto_out_0_c_bits_source[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_source[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[0] && x_s1_auto_out_0_c_bits_address[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[1] && x_s1_auto_out_0_c_bits_address[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[2] && x_s1_auto_out_0_c_bits_address[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[3] && x_s1_auto_out_0_c_bits_address[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[4] && x_s1_auto_out_0_c_bits_address[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[5] && x_s1_auto_out_0_c_bits_address[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[6] && x_s1_auto_out_0_c_bits_address[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[7] && x_s1_auto_out_0_c_bits_address[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[8] && x_s1_auto_out_0_c_bits_address[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[9] && x_s1_auto_out_0_c_bits_address[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[10] && x_s1_auto_out_0_c_bits_address[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[11] && x_s1_auto_out_0_c_bits_address[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[12] && x_s1_auto_out_0_c_bits_address[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[13] && x_s1_auto_out_0_c_bits_address[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[14] && x_s1_auto_out_0_c_bits_address[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[15] && x_s1_auto_out_0_c_bits_address[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[16] && x_s1_auto_out_0_c_bits_address[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[17] && x_s1_auto_out_0_c_bits_address[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[18] && x_s1_auto_out_0_c_bits_address[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[19] && x_s1_auto_out_0_c_bits_address[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[20] && x_s1_auto_out_0_c_bits_address[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[21] && x_s1_auto_out_0_c_bits_address[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[22] && x_s1_auto_out_0_c_bits_address[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[23] && x_s1_auto_out_0_c_bits_address[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[24] && x_s1_auto_out_0_c_bits_address[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[25] && x_s1_auto_out_0_c_bits_address[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[26] && x_s1_auto_out_0_c_bits_address[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[27] && x_s1_auto_out_0_c_bits_address[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[28] && x_s1_auto_out_0_c_bits_address[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[29] && x_s1_auto_out_0_c_bits_address[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[30] && x_s1_auto_out_0_c_bits_address[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[31] && x_s1_auto_out_0_c_bits_address[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[32] && x_s1_auto_out_0_c_bits_address[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[33] && x_s1_auto_out_0_c_bits_address[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[34] && x_s1_auto_out_0_c_bits_address[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[35] && x_s1_auto_out_0_c_bits_address[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[36] && x_s1_auto_out_0_c_bits_address[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[37] && x_s1_auto_out_0_c_bits_address[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[38] && x_s1_auto_out_0_c_bits_address[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[39] && x_s1_auto_out_0_c_bits_address[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[40] && x_s1_auto_out_0_c_bits_address[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[41] && x_s1_auto_out_0_c_bits_address[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[42] && x_s1_auto_out_0_c_bits_address[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[43] && x_s1_auto_out_0_c_bits_address[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[44] && x_s1_auto_out_0_c_bits_address[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[45] && x_s1_auto_out_0_c_bits_address[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[46] && x_s1_auto_out_0_c_bits_address[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_address[47] && x_s1_auto_out_0_c_bits_address[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_address[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_reqSource[0] && x_s1_auto_out_0_c_bits_user_reqSource[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_reqSource[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_reqSource[1] && x_s1_auto_out_0_c_bits_user_reqSource[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_reqSource[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_reqSource[2] && x_s1_auto_out_0_c_bits_user_reqSource[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_reqSource[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_reqSource[3] && x_s1_auto_out_0_c_bits_user_reqSource[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_reqSource[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_reqSource[4] && x_s1_auto_out_0_c_bits_user_reqSource[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_reqSource[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_alias[0] && x_s1_auto_out_0_c_bits_user_alias[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_alias[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_alias[1] && x_s1_auto_out_0_c_bits_user_alias[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_alias[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[0] && x_s1_auto_out_0_c_bits_user_vaddr[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[1] && x_s1_auto_out_0_c_bits_user_vaddr[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[2] && x_s1_auto_out_0_c_bits_user_vaddr[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[3] && x_s1_auto_out_0_c_bits_user_vaddr[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[4] && x_s1_auto_out_0_c_bits_user_vaddr[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[5] && x_s1_auto_out_0_c_bits_user_vaddr[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[6] && x_s1_auto_out_0_c_bits_user_vaddr[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[7] && x_s1_auto_out_0_c_bits_user_vaddr[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[8] && x_s1_auto_out_0_c_bits_user_vaddr[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[9] && x_s1_auto_out_0_c_bits_user_vaddr[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[10] && x_s1_auto_out_0_c_bits_user_vaddr[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[11] && x_s1_auto_out_0_c_bits_user_vaddr[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[12] && x_s1_auto_out_0_c_bits_user_vaddr[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[13] && x_s1_auto_out_0_c_bits_user_vaddr[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[14] && x_s1_auto_out_0_c_bits_user_vaddr[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[15] && x_s1_auto_out_0_c_bits_user_vaddr[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[16] && x_s1_auto_out_0_c_bits_user_vaddr[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[17] && x_s1_auto_out_0_c_bits_user_vaddr[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[18] && x_s1_auto_out_0_c_bits_user_vaddr[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[19] && x_s1_auto_out_0_c_bits_user_vaddr[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[20] && x_s1_auto_out_0_c_bits_user_vaddr[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[21] && x_s1_auto_out_0_c_bits_user_vaddr[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[22] && x_s1_auto_out_0_c_bits_user_vaddr[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[23] && x_s1_auto_out_0_c_bits_user_vaddr[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[24] && x_s1_auto_out_0_c_bits_user_vaddr[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[25] && x_s1_auto_out_0_c_bits_user_vaddr[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[26] && x_s1_auto_out_0_c_bits_user_vaddr[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[27] && x_s1_auto_out_0_c_bits_user_vaddr[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[28] && x_s1_auto_out_0_c_bits_user_vaddr[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[29] && x_s1_auto_out_0_c_bits_user_vaddr[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[30] && x_s1_auto_out_0_c_bits_user_vaddr[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[31] && x_s1_auto_out_0_c_bits_user_vaddr[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[32] && x_s1_auto_out_0_c_bits_user_vaddr[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[33] && x_s1_auto_out_0_c_bits_user_vaddr[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[34] && x_s1_auto_out_0_c_bits_user_vaddr[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[35] && x_s1_auto_out_0_c_bits_user_vaddr[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[36] && x_s1_auto_out_0_c_bits_user_vaddr[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[37] && x_s1_auto_out_0_c_bits_user_vaddr[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[38] && x_s1_auto_out_0_c_bits_user_vaddr[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[39] && x_s1_auto_out_0_c_bits_user_vaddr[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[40] && x_s1_auto_out_0_c_bits_user_vaddr[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[41] && x_s1_auto_out_0_c_bits_user_vaddr[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[42] && x_s1_auto_out_0_c_bits_user_vaddr[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_vaddr[43] && x_s1_auto_out_0_c_bits_user_vaddr[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_vaddr[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_user_needHint && x_s1_auto_out_0_c_bits_user_needHint)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_user_needHint 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_echo_isKeyword && x_s1_auto_out_0_c_bits_echo_isKeyword)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_echo_isKeyword 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[0] && x_s1_auto_out_0_c_bits_data[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[1] && x_s1_auto_out_0_c_bits_data[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[2] && x_s1_auto_out_0_c_bits_data[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[3] && x_s1_auto_out_0_c_bits_data[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[4] && x_s1_auto_out_0_c_bits_data[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[5] && x_s1_auto_out_0_c_bits_data[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[6] && x_s1_auto_out_0_c_bits_data[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[7] && x_s1_auto_out_0_c_bits_data[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[7] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[8] && x_s1_auto_out_0_c_bits_data[8])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[8] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[9] && x_s1_auto_out_0_c_bits_data[9])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[9] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[10] && x_s1_auto_out_0_c_bits_data[10])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[10] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[11] && x_s1_auto_out_0_c_bits_data[11])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[11] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[12] && x_s1_auto_out_0_c_bits_data[12])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[12] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[13] && x_s1_auto_out_0_c_bits_data[13])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[13] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[14] && x_s1_auto_out_0_c_bits_data[14])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[14] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[15] && x_s1_auto_out_0_c_bits_data[15])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[15] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[16] && x_s1_auto_out_0_c_bits_data[16])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[16] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[17] && x_s1_auto_out_0_c_bits_data[17])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[17] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[18] && x_s1_auto_out_0_c_bits_data[18])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[18] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[19] && x_s1_auto_out_0_c_bits_data[19])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[19] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[20] && x_s1_auto_out_0_c_bits_data[20])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[20] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[21] && x_s1_auto_out_0_c_bits_data[21])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[21] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[22] && x_s1_auto_out_0_c_bits_data[22])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[22] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[23] && x_s1_auto_out_0_c_bits_data[23])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[23] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[24] && x_s1_auto_out_0_c_bits_data[24])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[24] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[25] && x_s1_auto_out_0_c_bits_data[25])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[25] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[26] && x_s1_auto_out_0_c_bits_data[26])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[26] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[27] && x_s1_auto_out_0_c_bits_data[27])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[27] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[28] && x_s1_auto_out_0_c_bits_data[28])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[28] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[29] && x_s1_auto_out_0_c_bits_data[29])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[29] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[30] && x_s1_auto_out_0_c_bits_data[30])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[30] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[31] && x_s1_auto_out_0_c_bits_data[31])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[31] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[32] && x_s1_auto_out_0_c_bits_data[32])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[32] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[33] && x_s1_auto_out_0_c_bits_data[33])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[33] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[34] && x_s1_auto_out_0_c_bits_data[34])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[34] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[35] && x_s1_auto_out_0_c_bits_data[35])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[35] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[36] && x_s1_auto_out_0_c_bits_data[36])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[36] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[37] && x_s1_auto_out_0_c_bits_data[37])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[37] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[38] && x_s1_auto_out_0_c_bits_data[38])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[38] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[39] && x_s1_auto_out_0_c_bits_data[39])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[39] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[40] && x_s1_auto_out_0_c_bits_data[40])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[40] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[41] && x_s1_auto_out_0_c_bits_data[41])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[41] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[42] && x_s1_auto_out_0_c_bits_data[42])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[42] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[43] && x_s1_auto_out_0_c_bits_data[43])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[43] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[44] && x_s1_auto_out_0_c_bits_data[44])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[44] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[45] && x_s1_auto_out_0_c_bits_data[45])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[45] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[46] && x_s1_auto_out_0_c_bits_data[46])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[46] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[47] && x_s1_auto_out_0_c_bits_data[47])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[47] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[48] && x_s1_auto_out_0_c_bits_data[48])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[48] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[49] && x_s1_auto_out_0_c_bits_data[49])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[49] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[50] && x_s1_auto_out_0_c_bits_data[50])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[50] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[51] && x_s1_auto_out_0_c_bits_data[51])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[51] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[52] && x_s1_auto_out_0_c_bits_data[52])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[52] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[53] && x_s1_auto_out_0_c_bits_data[53])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[53] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[54] && x_s1_auto_out_0_c_bits_data[54])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[54] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[55] && x_s1_auto_out_0_c_bits_data[55])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[55] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[56] && x_s1_auto_out_0_c_bits_data[56])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[56] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[57] && x_s1_auto_out_0_c_bits_data[57])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[57] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[58] && x_s1_auto_out_0_c_bits_data[58])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[58] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[59] && x_s1_auto_out_0_c_bits_data[59])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[59] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[60] && x_s1_auto_out_0_c_bits_data[60])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[60] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[61] && x_s1_auto_out_0_c_bits_data[61])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[61] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[62] && x_s1_auto_out_0_c_bits_data[62])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[62] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[63] && x_s1_auto_out_0_c_bits_data[63])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[63] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[64] && x_s1_auto_out_0_c_bits_data[64])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[64] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[65] && x_s1_auto_out_0_c_bits_data[65])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[65] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[66] && x_s1_auto_out_0_c_bits_data[66])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[66] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[67] && x_s1_auto_out_0_c_bits_data[67])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[67] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[68] && x_s1_auto_out_0_c_bits_data[68])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[68] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[69] && x_s1_auto_out_0_c_bits_data[69])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[69] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[70] && x_s1_auto_out_0_c_bits_data[70])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[70] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[71] && x_s1_auto_out_0_c_bits_data[71])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[71] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[72] && x_s1_auto_out_0_c_bits_data[72])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[72] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[73] && x_s1_auto_out_0_c_bits_data[73])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[73] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[74] && x_s1_auto_out_0_c_bits_data[74])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[74] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[75] && x_s1_auto_out_0_c_bits_data[75])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[75] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[76] && x_s1_auto_out_0_c_bits_data[76])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[76] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[77] && x_s1_auto_out_0_c_bits_data[77])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[77] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[78] && x_s1_auto_out_0_c_bits_data[78])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[78] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[79] && x_s1_auto_out_0_c_bits_data[79])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[79] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[80] && x_s1_auto_out_0_c_bits_data[80])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[80] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[81] && x_s1_auto_out_0_c_bits_data[81])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[81] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[82] && x_s1_auto_out_0_c_bits_data[82])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[82] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[83] && x_s1_auto_out_0_c_bits_data[83])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[83] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[84] && x_s1_auto_out_0_c_bits_data[84])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[84] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[85] && x_s1_auto_out_0_c_bits_data[85])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[85] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[86] && x_s1_auto_out_0_c_bits_data[86])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[86] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[87] && x_s1_auto_out_0_c_bits_data[87])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[87] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[88] && x_s1_auto_out_0_c_bits_data[88])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[88] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[89] && x_s1_auto_out_0_c_bits_data[89])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[89] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[90] && x_s1_auto_out_0_c_bits_data[90])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[90] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[91] && x_s1_auto_out_0_c_bits_data[91])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[91] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[92] && x_s1_auto_out_0_c_bits_data[92])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[92] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[93] && x_s1_auto_out_0_c_bits_data[93])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[93] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[94] && x_s1_auto_out_0_c_bits_data[94])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[94] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[95] && x_s1_auto_out_0_c_bits_data[95])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[95] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[96] && x_s1_auto_out_0_c_bits_data[96])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[96] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[97] && x_s1_auto_out_0_c_bits_data[97])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[97] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[98] && x_s1_auto_out_0_c_bits_data[98])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[98] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[99] && x_s1_auto_out_0_c_bits_data[99])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[99] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[100] && x_s1_auto_out_0_c_bits_data[100])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[100] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[101] && x_s1_auto_out_0_c_bits_data[101])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[101] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[102] && x_s1_auto_out_0_c_bits_data[102])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[102] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[103] && x_s1_auto_out_0_c_bits_data[103])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[103] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[104] && x_s1_auto_out_0_c_bits_data[104])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[104] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[105] && x_s1_auto_out_0_c_bits_data[105])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[105] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[106] && x_s1_auto_out_0_c_bits_data[106])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[106] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[107] && x_s1_auto_out_0_c_bits_data[107])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[107] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[108] && x_s1_auto_out_0_c_bits_data[108])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[108] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[109] && x_s1_auto_out_0_c_bits_data[109])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[109] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[110] && x_s1_auto_out_0_c_bits_data[110])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[110] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[111] && x_s1_auto_out_0_c_bits_data[111])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[111] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[112] && x_s1_auto_out_0_c_bits_data[112])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[112] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[113] && x_s1_auto_out_0_c_bits_data[113])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[113] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[114] && x_s1_auto_out_0_c_bits_data[114])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[114] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[115] && x_s1_auto_out_0_c_bits_data[115])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[115] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[116] && x_s1_auto_out_0_c_bits_data[116])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[116] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[117] && x_s1_auto_out_0_c_bits_data[117])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[117] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[118] && x_s1_auto_out_0_c_bits_data[118])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[118] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[119] && x_s1_auto_out_0_c_bits_data[119])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[119] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[120] && x_s1_auto_out_0_c_bits_data[120])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[120] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[121] && x_s1_auto_out_0_c_bits_data[121])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[121] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[122] && x_s1_auto_out_0_c_bits_data[122])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[122] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[123] && x_s1_auto_out_0_c_bits_data[123])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[123] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[124] && x_s1_auto_out_0_c_bits_data[124])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[124] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[125] && x_s1_auto_out_0_c_bits_data[125])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[125] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[126] && x_s1_auto_out_0_c_bits_data[126])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[126] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[127] && x_s1_auto_out_0_c_bits_data[127])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[127] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[128] && x_s1_auto_out_0_c_bits_data[128])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[128] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[129] && x_s1_auto_out_0_c_bits_data[129])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[129] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[130] && x_s1_auto_out_0_c_bits_data[130])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[130] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[131] && x_s1_auto_out_0_c_bits_data[131])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[131] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[132] && x_s1_auto_out_0_c_bits_data[132])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[132] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[133] && x_s1_auto_out_0_c_bits_data[133])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[133] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[134] && x_s1_auto_out_0_c_bits_data[134])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[134] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[135] && x_s1_auto_out_0_c_bits_data[135])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[135] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[136] && x_s1_auto_out_0_c_bits_data[136])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[136] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[137] && x_s1_auto_out_0_c_bits_data[137])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[137] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[138] && x_s1_auto_out_0_c_bits_data[138])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[138] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[139] && x_s1_auto_out_0_c_bits_data[139])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[139] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[140] && x_s1_auto_out_0_c_bits_data[140])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[140] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[141] && x_s1_auto_out_0_c_bits_data[141])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[141] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[142] && x_s1_auto_out_0_c_bits_data[142])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[142] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[143] && x_s1_auto_out_0_c_bits_data[143])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[143] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[144] && x_s1_auto_out_0_c_bits_data[144])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[144] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[145] && x_s1_auto_out_0_c_bits_data[145])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[145] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[146] && x_s1_auto_out_0_c_bits_data[146])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[146] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[147] && x_s1_auto_out_0_c_bits_data[147])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[147] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[148] && x_s1_auto_out_0_c_bits_data[148])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[148] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[149] && x_s1_auto_out_0_c_bits_data[149])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[149] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[150] && x_s1_auto_out_0_c_bits_data[150])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[150] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[151] && x_s1_auto_out_0_c_bits_data[151])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[151] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[152] && x_s1_auto_out_0_c_bits_data[152])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[152] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[153] && x_s1_auto_out_0_c_bits_data[153])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[153] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[154] && x_s1_auto_out_0_c_bits_data[154])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[154] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[155] && x_s1_auto_out_0_c_bits_data[155])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[155] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[156] && x_s1_auto_out_0_c_bits_data[156])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[156] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[157] && x_s1_auto_out_0_c_bits_data[157])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[157] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[158] && x_s1_auto_out_0_c_bits_data[158])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[158] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[159] && x_s1_auto_out_0_c_bits_data[159])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[159] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[160] && x_s1_auto_out_0_c_bits_data[160])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[160] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[161] && x_s1_auto_out_0_c_bits_data[161])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[161] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[162] && x_s1_auto_out_0_c_bits_data[162])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[162] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[163] && x_s1_auto_out_0_c_bits_data[163])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[163] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[164] && x_s1_auto_out_0_c_bits_data[164])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[164] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[165] && x_s1_auto_out_0_c_bits_data[165])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[165] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[166] && x_s1_auto_out_0_c_bits_data[166])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[166] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[167] && x_s1_auto_out_0_c_bits_data[167])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[167] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[168] && x_s1_auto_out_0_c_bits_data[168])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[168] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[169] && x_s1_auto_out_0_c_bits_data[169])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[169] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[170] && x_s1_auto_out_0_c_bits_data[170])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[170] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[171] && x_s1_auto_out_0_c_bits_data[171])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[171] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[172] && x_s1_auto_out_0_c_bits_data[172])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[172] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[173] && x_s1_auto_out_0_c_bits_data[173])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[173] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[174] && x_s1_auto_out_0_c_bits_data[174])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[174] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[175] && x_s1_auto_out_0_c_bits_data[175])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[175] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[176] && x_s1_auto_out_0_c_bits_data[176])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[176] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[177] && x_s1_auto_out_0_c_bits_data[177])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[177] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[178] && x_s1_auto_out_0_c_bits_data[178])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[178] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[179] && x_s1_auto_out_0_c_bits_data[179])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[179] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[180] && x_s1_auto_out_0_c_bits_data[180])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[180] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[181] && x_s1_auto_out_0_c_bits_data[181])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[181] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[182] && x_s1_auto_out_0_c_bits_data[182])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[182] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[183] && x_s1_auto_out_0_c_bits_data[183])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[183] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[184] && x_s1_auto_out_0_c_bits_data[184])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[184] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[185] && x_s1_auto_out_0_c_bits_data[185])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[185] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[186] && x_s1_auto_out_0_c_bits_data[186])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[186] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[187] && x_s1_auto_out_0_c_bits_data[187])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[187] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[188] && x_s1_auto_out_0_c_bits_data[188])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[188] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[189] && x_s1_auto_out_0_c_bits_data[189])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[189] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[190] && x_s1_auto_out_0_c_bits_data[190])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[190] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[191] && x_s1_auto_out_0_c_bits_data[191])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[191] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[192] && x_s1_auto_out_0_c_bits_data[192])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[192] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[193] && x_s1_auto_out_0_c_bits_data[193])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[193] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[194] && x_s1_auto_out_0_c_bits_data[194])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[194] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[195] && x_s1_auto_out_0_c_bits_data[195])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[195] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[196] && x_s1_auto_out_0_c_bits_data[196])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[196] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[197] && x_s1_auto_out_0_c_bits_data[197])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[197] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[198] && x_s1_auto_out_0_c_bits_data[198])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[198] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[199] && x_s1_auto_out_0_c_bits_data[199])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[199] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[200] && x_s1_auto_out_0_c_bits_data[200])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[200] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[201] && x_s1_auto_out_0_c_bits_data[201])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[201] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[202] && x_s1_auto_out_0_c_bits_data[202])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[202] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[203] && x_s1_auto_out_0_c_bits_data[203])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[203] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[204] && x_s1_auto_out_0_c_bits_data[204])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[204] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[205] && x_s1_auto_out_0_c_bits_data[205])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[205] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[206] && x_s1_auto_out_0_c_bits_data[206])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[206] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[207] && x_s1_auto_out_0_c_bits_data[207])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[207] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[208] && x_s1_auto_out_0_c_bits_data[208])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[208] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[209] && x_s1_auto_out_0_c_bits_data[209])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[209] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[210] && x_s1_auto_out_0_c_bits_data[210])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[210] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[211] && x_s1_auto_out_0_c_bits_data[211])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[211] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[212] && x_s1_auto_out_0_c_bits_data[212])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[212] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[213] && x_s1_auto_out_0_c_bits_data[213])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[213] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[214] && x_s1_auto_out_0_c_bits_data[214])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[214] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[215] && x_s1_auto_out_0_c_bits_data[215])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[215] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[216] && x_s1_auto_out_0_c_bits_data[216])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[216] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[217] && x_s1_auto_out_0_c_bits_data[217])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[217] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[218] && x_s1_auto_out_0_c_bits_data[218])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[218] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[219] && x_s1_auto_out_0_c_bits_data[219])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[219] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[220] && x_s1_auto_out_0_c_bits_data[220])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[220] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[221] && x_s1_auto_out_0_c_bits_data[221])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[221] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[222] && x_s1_auto_out_0_c_bits_data[222])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[222] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[223] && x_s1_auto_out_0_c_bits_data[223])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[223] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[224] && x_s1_auto_out_0_c_bits_data[224])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[224] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[225] && x_s1_auto_out_0_c_bits_data[225])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[225] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[226] && x_s1_auto_out_0_c_bits_data[226])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[226] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[227] && x_s1_auto_out_0_c_bits_data[227])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[227] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[228] && x_s1_auto_out_0_c_bits_data[228])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[228] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[229] && x_s1_auto_out_0_c_bits_data[229])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[229] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[230] && x_s1_auto_out_0_c_bits_data[230])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[230] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[231] && x_s1_auto_out_0_c_bits_data[231])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[231] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[232] && x_s1_auto_out_0_c_bits_data[232])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[232] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[233] && x_s1_auto_out_0_c_bits_data[233])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[233] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[234] && x_s1_auto_out_0_c_bits_data[234])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[234] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[235] && x_s1_auto_out_0_c_bits_data[235])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[235] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[236] && x_s1_auto_out_0_c_bits_data[236])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[236] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[237] && x_s1_auto_out_0_c_bits_data[237])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[237] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[238] && x_s1_auto_out_0_c_bits_data[238])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[238] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[239] && x_s1_auto_out_0_c_bits_data[239])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[239] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[240] && x_s1_auto_out_0_c_bits_data[240])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[240] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[241] && x_s1_auto_out_0_c_bits_data[241])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[241] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[242] && x_s1_auto_out_0_c_bits_data[242])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[242] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[243] && x_s1_auto_out_0_c_bits_data[243])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[243] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[244] && x_s1_auto_out_0_c_bits_data[244])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[244] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[245] && x_s1_auto_out_0_c_bits_data[245])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[245] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[246] && x_s1_auto_out_0_c_bits_data[246])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[246] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[247] && x_s1_auto_out_0_c_bits_data[247])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[247] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[248] && x_s1_auto_out_0_c_bits_data[248])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[248] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[249] && x_s1_auto_out_0_c_bits_data[249])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[249] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[250] && x_s1_auto_out_0_c_bits_data[250])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[250] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[251] && x_s1_auto_out_0_c_bits_data[251])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[251] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[252] && x_s1_auto_out_0_c_bits_data[252])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[252] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[253] && x_s1_auto_out_0_c_bits_data[253])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[253] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[254] && x_s1_auto_out_0_c_bits_data[254])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[254] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_data[255] && x_s1_auto_out_0_c_bits_data[255])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_data[255] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_c_bits_corrupt && x_s1_auto_out_0_c_bits_corrupt)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_c_bits_corrupt 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_d_ready && x_s1_auto_out_0_d_ready)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_d_ready 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_valid && x_s1_auto_out_0_e_valid)) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_valid 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[0] && x_s1_auto_out_0_e_bits_sink[0])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[0] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[1] && x_s1_auto_out_0_e_bits_sink[1])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[1] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[2] && x_s1_auto_out_0_e_bits_sink[2])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[2] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[3] && x_s1_auto_out_0_e_bits_sink[3])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[3] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[4] && x_s1_auto_out_0_e_bits_sink[4])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[4] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[5] && x_s1_auto_out_0_e_bits_sink[5])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[5] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[6] && x_s1_auto_out_0_e_bits_sink[6])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[6] 未见过 0 和 1"); end
    if (!(x_s0_auto_out_0_e_bits_sink[7] && x_s1_auto_out_0_e_bits_sink[7])) begin cov_fail++; $display("[COV] TLXbar_5.auto_out_0_e_bits_sink[7] 未见过 0 和 1"); end
    $display("[ARM] TLXbar_5 armed_at=%0d", x_armed_at);
    if (x_armed_at < 0) begin cov_fail++; $display("[ARM] TLXbar_5 从未 arm"); end
    $display("[COV] TLXbar_5.a_lock = %0d", x_cov_a_lock);
    if (x_cov_a_lock < 200) begin cov_fail++; $display("[COV] TLXbar_5.a_lock < 200"); end
    $display("[COV] TLXbar_5.d_lock = %0d", x_cov_d_lock);
    if (x_cov_d_lock < 200) begin cov_fail++; $display("[COV] TLXbar_5.d_lock < 200"); end
    $display("[COV] TLXbar_5.a0_fire = %0d", x_cov_a0_fire);
    if (x_cov_a0_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.a0_fire < 200"); end
    $display("[COV] TLXbar_5.a3_from_ptw = %0d", x_cov_a3_from_ptw);
    if (x_cov_a3_from_ptw < 200) begin cov_fail++; $display("[COV] TLXbar_5.a3_from_ptw < 200"); end
    $display("[COV] TLXbar_5.a_contend = %0d", x_cov_a_contend);
    if (x_cov_a_contend < 200) begin cov_fail++; $display("[COV] TLXbar_5.a_contend < 200"); end
    $display("[COV] TLXbar_5.b_fire = %0d", x_cov_b_fire);
    if (x_cov_b_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.b_fire < 200"); end
    $display("[COV] TLXbar_5.c_fire = %0d", x_cov_c_fire);
    if (x_cov_c_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.c_fire < 200"); end
    $display("[COV] TLXbar_5.d0_fire = %0d", x_cov_d0_fire);
    if (x_cov_d0_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.d0_fire < 200"); end
    $display("[COV] TLXbar_5.d1_fire = %0d", x_cov_d1_fire);
    if (x_cov_d1_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.d1_fire < 200"); end
    $display("[COV] TLXbar_5.d2_fire = %0d", x_cov_d2_fire);
    if (x_cov_d2_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.d2_fire < 200"); end
    $display("[COV] TLXbar_5.e_fire = %0d", x_cov_e_fire);
    if (x_cov_e_fire < 200) begin cov_fail++; $display("[COV] TLXbar_5.e_fire < 200"); end
    $display("[COV] TLXbar_5.rr_flip = %0d", x_cov_rr_flip);
    if (x_cov_rr_flip < 200) begin cov_fail++; $display("[COV] TLXbar_5.rr_flip < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
