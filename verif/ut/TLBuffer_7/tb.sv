// 自动生成：scripts/gen_tlbuffer7.py —— 勿手改
// TLBuffer_7 双例化逐拍比对: golden TLBuffer_7 vs 可读 TLBuffer_7_xs。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [2:0] auto_in_a_bits_param;
  logic [2:0] auto_in_a_bits_size;
  logic [5:0] auto_in_a_bits_source;
  logic [47:0] auto_in_a_bits_address;
  logic [1:0] auto_in_a_bits_user_alias;
  logic [43:0] auto_in_a_bits_user_vaddr;
  logic [4:0] auto_in_a_bits_user_reqSource;
  logic auto_in_a_bits_user_needHint;
  logic auto_in_a_bits_echo_isKeyword;
  logic [31:0] auto_in_a_bits_mask;
  logic auto_in_b_ready;
  logic auto_in_c_valid;
  logic [2:0] auto_in_c_bits_opcode;
  logic [2:0] auto_in_c_bits_param;
  logic [2:0] auto_in_c_bits_size;
  logic [5:0] auto_in_c_bits_source;
  logic [47:0] auto_in_c_bits_address;
  logic [255:0] auto_in_c_bits_data;
  logic auto_in_c_bits_corrupt;
  logic auto_in_d_ready;
  logic auto_in_e_valid;
  logic [9:0] auto_in_e_bits_sink;
  logic auto_out_a_ready;
  logic auto_out_b_valid;
  logic [2:0] auto_out_b_bits_opcode;
  logic [1:0] auto_out_b_bits_param;
  logic [2:0] auto_out_b_bits_size;
  logic [5:0] auto_out_b_bits_source;
  logic [47:0] auto_out_b_bits_address;
  logic [31:0] auto_out_b_bits_mask;
  logic [255:0] auto_out_b_bits_data;
  logic auto_out_b_bits_corrupt;
  logic auto_out_c_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [1:0] auto_out_d_bits_param;
  logic [2:0] auto_out_d_bits_size;
  logic [5:0] auto_out_d_bits_source;
  logic [9:0] auto_out_d_bits_sink;
  logic auto_out_d_bits_denied;
  logic auto_out_d_bits_echo_isKeyword;
  logic [255:0] auto_out_d_bits_data;
  logic auto_out_d_bits_corrupt;
  logic auto_out_e_ready;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_b_valid;
  wire i_auto_in_b_valid;
  wire [2:0] g_auto_in_b_bits_opcode;
  wire [2:0] i_auto_in_b_bits_opcode;
  wire [1:0] g_auto_in_b_bits_param;
  wire [1:0] i_auto_in_b_bits_param;
  wire [47:0] g_auto_in_b_bits_address;
  wire [47:0] i_auto_in_b_bits_address;
  wire [255:0] g_auto_in_b_bits_data;
  wire [255:0] i_auto_in_b_bits_data;
  wire g_auto_in_c_ready;
  wire i_auto_in_c_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [1:0] g_auto_in_d_bits_param;
  wire [1:0] i_auto_in_d_bits_param;
  wire [2:0] g_auto_in_d_bits_size;
  wire [2:0] i_auto_in_d_bits_size;
  wire [5:0] g_auto_in_d_bits_source;
  wire [5:0] i_auto_in_d_bits_source;
  wire [9:0] g_auto_in_d_bits_sink;
  wire [9:0] i_auto_in_d_bits_sink;
  wire g_auto_in_d_bits_denied;
  wire i_auto_in_d_bits_denied;
  wire g_auto_in_d_bits_echo_isKeyword;
  wire i_auto_in_d_bits_echo_isKeyword;
  wire [255:0] g_auto_in_d_bits_data;
  wire [255:0] i_auto_in_d_bits_data;
  wire g_auto_in_d_bits_corrupt;
  wire i_auto_in_d_bits_corrupt;
  wire g_auto_in_e_ready;
  wire i_auto_in_e_ready;
  wire g_auto_out_a_valid;
  wire i_auto_out_a_valid;
  wire [3:0] g_auto_out_a_bits_opcode;
  wire [3:0] i_auto_out_a_bits_opcode;
  wire [2:0] g_auto_out_a_bits_param;
  wire [2:0] i_auto_out_a_bits_param;
  wire [2:0] g_auto_out_a_bits_size;
  wire [2:0] i_auto_out_a_bits_size;
  wire [5:0] g_auto_out_a_bits_source;
  wire [5:0] i_auto_out_a_bits_source;
  wire [47:0] g_auto_out_a_bits_address;
  wire [47:0] i_auto_out_a_bits_address;
  wire [1:0] g_auto_out_a_bits_user_alias;
  wire [1:0] i_auto_out_a_bits_user_alias;
  wire [43:0] g_auto_out_a_bits_user_vaddr;
  wire [43:0] i_auto_out_a_bits_user_vaddr;
  wire [4:0] g_auto_out_a_bits_user_reqSource;
  wire [4:0] i_auto_out_a_bits_user_reqSource;
  wire g_auto_out_a_bits_user_needHint;
  wire i_auto_out_a_bits_user_needHint;
  wire g_auto_out_a_bits_echo_isKeyword;
  wire i_auto_out_a_bits_echo_isKeyword;
  wire [31:0] g_auto_out_a_bits_mask;
  wire [31:0] i_auto_out_a_bits_mask;
  wire [255:0] g_auto_out_a_bits_data;
  wire [255:0] i_auto_out_a_bits_data;
  wire g_auto_out_a_bits_corrupt;
  wire i_auto_out_a_bits_corrupt;
  wire g_auto_out_b_ready;
  wire i_auto_out_b_ready;
  wire g_auto_out_c_valid;
  wire i_auto_out_c_valid;
  wire [2:0] g_auto_out_c_bits_opcode;
  wire [2:0] i_auto_out_c_bits_opcode;
  wire [2:0] g_auto_out_c_bits_param;
  wire [2:0] i_auto_out_c_bits_param;
  wire [2:0] g_auto_out_c_bits_size;
  wire [2:0] i_auto_out_c_bits_size;
  wire [5:0] g_auto_out_c_bits_source;
  wire [5:0] i_auto_out_c_bits_source;
  wire [47:0] g_auto_out_c_bits_address;
  wire [47:0] i_auto_out_c_bits_address;
  wire [1:0] g_auto_out_c_bits_user_alias;
  wire [1:0] i_auto_out_c_bits_user_alias;
  wire [43:0] g_auto_out_c_bits_user_vaddr;
  wire [43:0] i_auto_out_c_bits_user_vaddr;
  wire [4:0] g_auto_out_c_bits_user_reqSource;
  wire [4:0] i_auto_out_c_bits_user_reqSource;
  wire g_auto_out_c_bits_user_needHint;
  wire i_auto_out_c_bits_user_needHint;
  wire g_auto_out_c_bits_echo_isKeyword;
  wire i_auto_out_c_bits_echo_isKeyword;
  wire [255:0] g_auto_out_c_bits_data;
  wire [255:0] i_auto_out_c_bits_data;
  wire g_auto_out_c_bits_corrupt;
  wire i_auto_out_c_bits_corrupt;
  wire g_auto_out_d_ready;
  wire i_auto_out_d_ready;
  wire g_auto_out_e_valid;
  wire i_auto_out_e_valid;
  wire [9:0] g_auto_out_e_bits_sink;
  wire [9:0] i_auto_out_e_bits_sink;

  TLBuffer_7 u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_alias(auto_in_a_bits_user_alias),
    .auto_in_a_bits_user_vaddr(auto_in_a_bits_user_vaddr),
    .auto_in_a_bits_user_reqSource(auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint(auto_in_a_bits_user_needHint),
    .auto_in_a_bits_echo_isKeyword(auto_in_a_bits_echo_isKeyword),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_b_ready(auto_in_b_ready),
    .auto_in_b_valid(g_auto_in_b_valid),
    .auto_in_b_bits_opcode(g_auto_in_b_bits_opcode),
    .auto_in_b_bits_param(g_auto_in_b_bits_param),
    .auto_in_b_bits_address(g_auto_in_b_bits_address),
    .auto_in_b_bits_data(g_auto_in_b_bits_data),
    .auto_in_c_ready(g_auto_in_c_ready),
    .auto_in_c_valid(auto_in_c_valid),
    .auto_in_c_bits_opcode(auto_in_c_bits_opcode),
    .auto_in_c_bits_param(auto_in_c_bits_param),
    .auto_in_c_bits_size(auto_in_c_bits_size),
    .auto_in_c_bits_source(auto_in_c_bits_source),
    .auto_in_c_bits_address(auto_in_c_bits_address),
    .auto_in_c_bits_data(auto_in_c_bits_data),
    .auto_in_c_bits_corrupt(auto_in_c_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(g_auto_in_d_bits_param),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_sink(g_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(g_auto_in_d_bits_denied),
    .auto_in_d_bits_echo_isKeyword(g_auto_in_d_bits_echo_isKeyword),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_auto_in_d_bits_corrupt),
    .auto_in_e_ready(g_auto_in_e_ready),
    .auto_in_e_valid(auto_in_e_valid),
    .auto_in_e_bits_sink(auto_in_e_bits_sink),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(g_auto_out_a_valid),
    .auto_out_a_bits_opcode(g_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(g_auto_out_a_bits_param),
    .auto_out_a_bits_size(g_auto_out_a_bits_size),
    .auto_out_a_bits_source(g_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias(g_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_vaddr(g_auto_out_a_bits_user_vaddr),
    .auto_out_a_bits_user_reqSource(g_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint(g_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_echo_isKeyword(g_auto_out_a_bits_echo_isKeyword),
    .auto_out_a_bits_mask(g_auto_out_a_bits_mask),
    .auto_out_a_bits_data(g_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(g_auto_out_a_bits_corrupt),
    .auto_out_b_ready(g_auto_out_b_ready),
    .auto_out_b_valid(auto_out_b_valid),
    .auto_out_b_bits_opcode(auto_out_b_bits_opcode),
    .auto_out_b_bits_param(auto_out_b_bits_param),
    .auto_out_b_bits_size(auto_out_b_bits_size),
    .auto_out_b_bits_source(auto_out_b_bits_source),
    .auto_out_b_bits_address(auto_out_b_bits_address),
    .auto_out_b_bits_mask(auto_out_b_bits_mask),
    .auto_out_b_bits_data(auto_out_b_bits_data),
    .auto_out_b_bits_corrupt(auto_out_b_bits_corrupt),
    .auto_out_c_ready(auto_out_c_ready),
    .auto_out_c_valid(g_auto_out_c_valid),
    .auto_out_c_bits_opcode(g_auto_out_c_bits_opcode),
    .auto_out_c_bits_param(g_auto_out_c_bits_param),
    .auto_out_c_bits_size(g_auto_out_c_bits_size),
    .auto_out_c_bits_source(g_auto_out_c_bits_source),
    .auto_out_c_bits_address(g_auto_out_c_bits_address),
    .auto_out_c_bits_user_alias(g_auto_out_c_bits_user_alias),
    .auto_out_c_bits_user_vaddr(g_auto_out_c_bits_user_vaddr),
    .auto_out_c_bits_user_reqSource(g_auto_out_c_bits_user_reqSource),
    .auto_out_c_bits_user_needHint(g_auto_out_c_bits_user_needHint),
    .auto_out_c_bits_echo_isKeyword(g_auto_out_c_bits_echo_isKeyword),
    .auto_out_c_bits_data(g_auto_out_c_bits_data),
    .auto_out_c_bits_corrupt(g_auto_out_c_bits_corrupt),
    .auto_out_d_ready(g_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_echo_isKeyword(auto_out_d_bits_echo_isKeyword),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt),
    .auto_out_e_ready(auto_out_e_ready),
    .auto_out_e_valid(g_auto_out_e_valid),
    .auto_out_e_bits_sink(g_auto_out_e_bits_sink)
  );

  TLBuffer_7_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_param(auto_in_a_bits_param),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_alias(auto_in_a_bits_user_alias),
    .auto_in_a_bits_user_vaddr(auto_in_a_bits_user_vaddr),
    .auto_in_a_bits_user_reqSource(auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint(auto_in_a_bits_user_needHint),
    .auto_in_a_bits_echo_isKeyword(auto_in_a_bits_echo_isKeyword),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_b_ready(auto_in_b_ready),
    .auto_in_b_valid(i_auto_in_b_valid),
    .auto_in_b_bits_opcode(i_auto_in_b_bits_opcode),
    .auto_in_b_bits_param(i_auto_in_b_bits_param),
    .auto_in_b_bits_address(i_auto_in_b_bits_address),
    .auto_in_b_bits_data(i_auto_in_b_bits_data),
    .auto_in_c_ready(i_auto_in_c_ready),
    .auto_in_c_valid(auto_in_c_valid),
    .auto_in_c_bits_opcode(auto_in_c_bits_opcode),
    .auto_in_c_bits_param(auto_in_c_bits_param),
    .auto_in_c_bits_size(auto_in_c_bits_size),
    .auto_in_c_bits_source(auto_in_c_bits_source),
    .auto_in_c_bits_address(auto_in_c_bits_address),
    .auto_in_c_bits_data(auto_in_c_bits_data),
    .auto_in_c_bits_corrupt(auto_in_c_bits_corrupt),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(i_auto_in_d_bits_param),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_sink(i_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(i_auto_in_d_bits_denied),
    .auto_in_d_bits_echo_isKeyword(i_auto_in_d_bits_echo_isKeyword),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_auto_in_d_bits_corrupt),
    .auto_in_e_ready(i_auto_in_e_ready),
    .auto_in_e_valid(auto_in_e_valid),
    .auto_in_e_bits_sink(auto_in_e_bits_sink),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(i_auto_out_a_valid),
    .auto_out_a_bits_opcode(i_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(i_auto_out_a_bits_param),
    .auto_out_a_bits_size(i_auto_out_a_bits_size),
    .auto_out_a_bits_source(i_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias(i_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_vaddr(i_auto_out_a_bits_user_vaddr),
    .auto_out_a_bits_user_reqSource(i_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint(i_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_echo_isKeyword(i_auto_out_a_bits_echo_isKeyword),
    .auto_out_a_bits_mask(i_auto_out_a_bits_mask),
    .auto_out_a_bits_data(i_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(i_auto_out_a_bits_corrupt),
    .auto_out_b_ready(i_auto_out_b_ready),
    .auto_out_b_valid(auto_out_b_valid),
    .auto_out_b_bits_opcode(auto_out_b_bits_opcode),
    .auto_out_b_bits_param(auto_out_b_bits_param),
    .auto_out_b_bits_size(auto_out_b_bits_size),
    .auto_out_b_bits_source(auto_out_b_bits_source),
    .auto_out_b_bits_address(auto_out_b_bits_address),
    .auto_out_b_bits_mask(auto_out_b_bits_mask),
    .auto_out_b_bits_data(auto_out_b_bits_data),
    .auto_out_b_bits_corrupt(auto_out_b_bits_corrupt),
    .auto_out_c_ready(auto_out_c_ready),
    .auto_out_c_valid(i_auto_out_c_valid),
    .auto_out_c_bits_opcode(i_auto_out_c_bits_opcode),
    .auto_out_c_bits_param(i_auto_out_c_bits_param),
    .auto_out_c_bits_size(i_auto_out_c_bits_size),
    .auto_out_c_bits_source(i_auto_out_c_bits_source),
    .auto_out_c_bits_address(i_auto_out_c_bits_address),
    .auto_out_c_bits_user_alias(i_auto_out_c_bits_user_alias),
    .auto_out_c_bits_user_vaddr(i_auto_out_c_bits_user_vaddr),
    .auto_out_c_bits_user_reqSource(i_auto_out_c_bits_user_reqSource),
    .auto_out_c_bits_user_needHint(i_auto_out_c_bits_user_needHint),
    .auto_out_c_bits_echo_isKeyword(i_auto_out_c_bits_echo_isKeyword),
    .auto_out_c_bits_data(i_auto_out_c_bits_data),
    .auto_out_c_bits_corrupt(i_auto_out_c_bits_corrupt),
    .auto_out_d_ready(i_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_param(auto_out_d_bits_param),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_sink(auto_out_d_bits_sink),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_echo_isKeyword(auto_out_d_bits_echo_isKeyword),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt),
    .auto_out_e_ready(auto_out_e_ready),
    .auto_out_e_valid(i_auto_out_e_valid),
    .auto_out_e_bits_sink(i_auto_out_e_bits_sink)
  );

  task automatic drive_random_inputs();
    auto_in_a_valid <= $urandom_range(0, 1);
    auto_in_a_bits_opcode <= 4'({$urandom});
    auto_in_a_bits_param <= 3'({$urandom});
    auto_in_a_bits_size <= 3'({$urandom});
    auto_in_a_bits_source <= 6'({$urandom});
    auto_in_a_bits_address <= 48'({$urandom, $urandom});
    auto_in_a_bits_user_alias <= 2'({$urandom});
    auto_in_a_bits_user_vaddr <= 44'({$urandom, $urandom});
    auto_in_a_bits_user_reqSource <= 5'({$urandom});
    auto_in_a_bits_user_needHint <= $urandom_range(0, 1);
    auto_in_a_bits_echo_isKeyword <= $urandom_range(0, 1);
    auto_in_a_bits_mask <= 32'({$urandom});
    auto_in_b_ready <= $urandom_range(0, 1);
    auto_in_c_valid <= $urandom_range(0, 1);
    auto_in_c_bits_opcode <= 3'({$urandom});
    auto_in_c_bits_param <= 3'({$urandom});
    auto_in_c_bits_size <= 3'({$urandom});
    auto_in_c_bits_source <= 6'({$urandom});
    auto_in_c_bits_address <= 48'({$urandom, $urandom});
    auto_in_c_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_in_c_bits_corrupt <= $urandom_range(0, 1);
    auto_in_d_ready <= $urandom_range(0, 1);
    auto_in_e_valid <= $urandom_range(0, 1);
    auto_in_e_bits_sink <= 10'({$urandom});
    auto_out_a_ready <= $urandom_range(0, 1);
    auto_out_b_valid <= $urandom_range(0, 1);
    auto_out_b_bits_opcode <= 3'({$urandom});
    auto_out_b_bits_param <= 2'({$urandom});
    auto_out_b_bits_size <= 3'({$urandom});
    auto_out_b_bits_source <= 6'({$urandom});
    auto_out_b_bits_address <= 48'({$urandom, $urandom});
    auto_out_b_bits_mask <= 32'({$urandom});
    auto_out_b_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_out_b_bits_corrupt <= $urandom_range(0, 1);
    auto_out_c_ready <= $urandom_range(0, 1);
    auto_out_d_valid <= $urandom_range(0, 1);
    auto_out_d_bits_opcode <= 4'({$urandom});
    auto_out_d_bits_param <= 2'({$urandom});
    auto_out_d_bits_size <= 3'({$urandom});
    auto_out_d_bits_source <= 6'({$urandom});
    auto_out_d_bits_sink <= 10'({$urandom});
    auto_out_d_bits_denied <= $urandom_range(0, 1);
    auto_out_d_bits_echo_isKeyword <= $urandom_range(0, 1);
    auto_out_d_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_out_d_bits_corrupt <= $urandom_range(0, 1);
    auto_out_e_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_b_valid)
    `CHECK(auto_in_b_bits_opcode)
    `CHECK(auto_in_b_bits_param)
    `CHECK(auto_in_b_bits_address)
    `CHECK(auto_in_b_bits_data)
    `CHECK(auto_in_c_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_param)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_sink)
    `CHECK(auto_in_d_bits_denied)
    `CHECK(auto_in_d_bits_echo_isKeyword)
    `CHECK(auto_in_d_bits_data)
    `CHECK(auto_in_d_bits_corrupt)
    `CHECK(auto_in_e_ready)
    `CHECK(auto_out_a_valid)
    `CHECK(auto_out_a_bits_opcode)
    `CHECK(auto_out_a_bits_param)
    `CHECK(auto_out_a_bits_size)
    `CHECK(auto_out_a_bits_source)
    `CHECK(auto_out_a_bits_address)
    `CHECK(auto_out_a_bits_user_alias)
    `CHECK(auto_out_a_bits_user_vaddr)
    `CHECK(auto_out_a_bits_user_reqSource)
    `CHECK(auto_out_a_bits_user_needHint)
    `CHECK(auto_out_a_bits_echo_isKeyword)
    `CHECK(auto_out_a_bits_mask)
    `CHECK(auto_out_a_bits_data)
    `CHECK(auto_out_a_bits_corrupt)
    `CHECK(auto_out_b_ready)
    `CHECK(auto_out_c_valid)
    `CHECK(auto_out_c_bits_opcode)
    `CHECK(auto_out_c_bits_param)
    `CHECK(auto_out_c_bits_size)
    `CHECK(auto_out_c_bits_source)
    `CHECK(auto_out_c_bits_address)
    `CHECK(auto_out_c_bits_user_alias)
    `CHECK(auto_out_c_bits_user_vaddr)
    `CHECK(auto_out_c_bits_user_reqSource)
    `CHECK(auto_out_c_bits_user_needHint)
    `CHECK(auto_out_c_bits_echo_isKeyword)
    `CHECK(auto_out_c_bits_data)
    `CHECK(auto_out_c_bits_corrupt)
    `CHECK(auto_out_d_ready)
    `CHECK(auto_out_e_valid)
    `CHECK(auto_out_e_bits_sink)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_param = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_user_alias = '0;
    auto_in_a_bits_user_vaddr = '0;
    auto_in_a_bits_user_reqSource = '0;
    auto_in_a_bits_user_needHint = '0;
    auto_in_a_bits_echo_isKeyword = '0;
    auto_in_a_bits_mask = '0;
    auto_in_b_ready = '0;
    auto_in_c_valid = '0;
    auto_in_c_bits_opcode = '0;
    auto_in_c_bits_param = '0;
    auto_in_c_bits_size = '0;
    auto_in_c_bits_source = '0;
    auto_in_c_bits_address = '0;
    auto_in_c_bits_data = '0;
    auto_in_c_bits_corrupt = '0;
    auto_in_d_ready = '0;
    auto_in_e_valid = '0;
    auto_in_e_bits_sink = '0;
    auto_out_a_ready = '0;
    auto_out_b_valid = '0;
    auto_out_b_bits_opcode = '0;
    auto_out_b_bits_param = '0;
    auto_out_b_bits_size = '0;
    auto_out_b_bits_source = '0;
    auto_out_b_bits_address = '0;
    auto_out_b_bits_mask = '0;
    auto_out_b_bits_data = '0;
    auto_out_b_bits_corrupt = '0;
    auto_out_c_ready = '0;
    auto_out_d_valid = '0;
    auto_out_d_bits_opcode = '0;
    auto_out_d_bits_param = '0;
    auto_out_d_bits_size = '0;
    auto_out_d_bits_source = '0;
    auto_out_d_bits_sink = '0;
    auto_out_d_bits_denied = '0;
    auto_out_d_bits_echo_isKeyword = '0;
    auto_out_d_bits_data = '0;
    auto_out_d_bits_corrupt = '0;
    auto_out_e_ready = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("TLBuffer_7 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
