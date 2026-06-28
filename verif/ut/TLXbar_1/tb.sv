// 自动生成：scripts/gen_tlxbar1.py —— 勿手改
// TLXbar_1 双例化逐拍比对: golden TLXbar_1 vs 可读 TLXbar_1_xs。
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

  logic auto_in_1_a_valid;
  logic [3:0] auto_in_1_a_bits_opcode;
  logic [2:0] auto_in_1_a_bits_size;
  logic [48:0] auto_in_1_a_bits_address;
  logic [7:0] auto_in_1_a_bits_mask;
  logic [63:0] auto_in_1_a_bits_data;
  logic auto_in_1_d_ready;
  logic auto_in_0_a_valid;
  logic [3:0] auto_in_0_a_bits_opcode;
  logic [2:0] auto_in_0_a_bits_param;
  logic [2:0] auto_in_0_a_bits_size;
  logic [13:0] auto_in_0_a_bits_source;
  logic [48:0] auto_in_0_a_bits_address;
  logic auto_in_0_a_bits_user_amba_prot_bufferable;
  logic auto_in_0_a_bits_user_amba_prot_modifiable;
  logic auto_in_0_a_bits_user_amba_prot_readalloc;
  logic auto_in_0_a_bits_user_amba_prot_writealloc;
  logic auto_in_0_a_bits_user_amba_prot_privileged;
  logic auto_in_0_a_bits_user_amba_prot_secure;
  logic auto_in_0_a_bits_user_amba_prot_fetch;
  logic [7:0] auto_in_0_a_bits_mask;
  logic [63:0] auto_in_0_a_bits_data;
  logic auto_in_0_a_bits_corrupt;
  logic auto_in_0_d_ready;
  logic auto_out_2_a_ready;
  logic auto_out_2_d_valid;
  logic [3:0] auto_out_2_d_bits_opcode;
  logic [1:0] auto_out_2_d_bits_param;
  logic [1:0] auto_out_2_d_bits_size;
  logic [14:0] auto_out_2_d_bits_source;
  logic auto_out_2_d_bits_sink;
  logic auto_out_2_d_bits_denied;
  logic [63:0] auto_out_2_d_bits_data;
  logic auto_out_2_d_bits_corrupt;
  logic auto_out_1_a_ready;
  logic auto_out_1_d_valid;
  logic [3:0] auto_out_1_d_bits_opcode;
  logic [2:0] auto_out_1_d_bits_size;
  logic [14:0] auto_out_1_d_bits_source;
  logic auto_out_1_d_bits_denied;
  logic [63:0] auto_out_1_d_bits_data;
  logic auto_out_1_d_bits_corrupt;
  logic auto_out_0_a_ready;
  logic auto_out_0_d_valid;
  logic [3:0] auto_out_0_d_bits_opcode;
  logic [2:0] auto_out_0_d_bits_size;
  logic [14:0] auto_out_0_d_bits_source;
  logic auto_out_0_d_bits_corrupt;
  wire g_auto_in_1_a_ready;
  wire i_auto_in_1_a_ready;
  wire g_auto_in_1_d_valid;
  wire i_auto_in_1_d_valid;
  wire [3:0] g_auto_in_1_d_bits_opcode;
  wire [3:0] i_auto_in_1_d_bits_opcode;
  wire [1:0] g_auto_in_1_d_bits_param;
  wire [1:0] i_auto_in_1_d_bits_param;
  wire [2:0] g_auto_in_1_d_bits_size;
  wire [2:0] i_auto_in_1_d_bits_size;
  wire g_auto_in_1_d_bits_sink;
  wire i_auto_in_1_d_bits_sink;
  wire g_auto_in_1_d_bits_denied;
  wire i_auto_in_1_d_bits_denied;
  wire [63:0] g_auto_in_1_d_bits_data;
  wire [63:0] i_auto_in_1_d_bits_data;
  wire g_auto_in_1_d_bits_corrupt;
  wire i_auto_in_1_d_bits_corrupt;
  wire g_auto_in_0_a_ready;
  wire i_auto_in_0_a_ready;
  wire g_auto_in_0_d_valid;
  wire i_auto_in_0_d_valid;
  wire [3:0] g_auto_in_0_d_bits_opcode;
  wire [3:0] i_auto_in_0_d_bits_opcode;
  wire [1:0] g_auto_in_0_d_bits_param;
  wire [1:0] i_auto_in_0_d_bits_param;
  wire [2:0] g_auto_in_0_d_bits_size;
  wire [2:0] i_auto_in_0_d_bits_size;
  wire [13:0] g_auto_in_0_d_bits_source;
  wire [13:0] i_auto_in_0_d_bits_source;
  wire g_auto_in_0_d_bits_sink;
  wire i_auto_in_0_d_bits_sink;
  wire g_auto_in_0_d_bits_denied;
  wire i_auto_in_0_d_bits_denied;
  wire [63:0] g_auto_in_0_d_bits_data;
  wire [63:0] i_auto_in_0_d_bits_data;
  wire g_auto_in_0_d_bits_corrupt;
  wire i_auto_in_0_d_bits_corrupt;
  wire g_auto_out_2_a_valid;
  wire i_auto_out_2_a_valid;
  wire [3:0] g_auto_out_2_a_bits_opcode;
  wire [3:0] i_auto_out_2_a_bits_opcode;
  wire [2:0] g_auto_out_2_a_bits_param;
  wire [2:0] i_auto_out_2_a_bits_param;
  wire [1:0] g_auto_out_2_a_bits_size;
  wire [1:0] i_auto_out_2_a_bits_size;
  wire [14:0] g_auto_out_2_a_bits_source;
  wire [14:0] i_auto_out_2_a_bits_source;
  wire [29:0] g_auto_out_2_a_bits_address;
  wire [29:0] i_auto_out_2_a_bits_address;
  wire [7:0] g_auto_out_2_a_bits_mask;
  wire [7:0] i_auto_out_2_a_bits_mask;
  wire [63:0] g_auto_out_2_a_bits_data;
  wire [63:0] i_auto_out_2_a_bits_data;
  wire g_auto_out_2_a_bits_corrupt;
  wire i_auto_out_2_a_bits_corrupt;
  wire g_auto_out_2_d_ready;
  wire i_auto_out_2_d_ready;
  wire g_auto_out_1_a_valid;
  wire i_auto_out_1_a_valid;
  wire [3:0] g_auto_out_1_a_bits_opcode;
  wire [3:0] i_auto_out_1_a_bits_opcode;
  wire [2:0] g_auto_out_1_a_bits_size;
  wire [2:0] i_auto_out_1_a_bits_size;
  wire [14:0] g_auto_out_1_a_bits_source;
  wire [14:0] i_auto_out_1_a_bits_source;
  wire [30:0] g_auto_out_1_a_bits_address;
  wire [30:0] i_auto_out_1_a_bits_address;
  wire g_auto_out_1_a_bits_user_amba_prot_bufferable;
  wire i_auto_out_1_a_bits_user_amba_prot_bufferable;
  wire g_auto_out_1_a_bits_user_amba_prot_modifiable;
  wire i_auto_out_1_a_bits_user_amba_prot_modifiable;
  wire g_auto_out_1_a_bits_user_amba_prot_readalloc;
  wire i_auto_out_1_a_bits_user_amba_prot_readalloc;
  wire g_auto_out_1_a_bits_user_amba_prot_writealloc;
  wire i_auto_out_1_a_bits_user_amba_prot_writealloc;
  wire g_auto_out_1_a_bits_user_amba_prot_privileged;
  wire i_auto_out_1_a_bits_user_amba_prot_privileged;
  wire g_auto_out_1_a_bits_user_amba_prot_secure;
  wire i_auto_out_1_a_bits_user_amba_prot_secure;
  wire g_auto_out_1_a_bits_user_amba_prot_fetch;
  wire i_auto_out_1_a_bits_user_amba_prot_fetch;
  wire [7:0] g_auto_out_1_a_bits_mask;
  wire [7:0] i_auto_out_1_a_bits_mask;
  wire [63:0] g_auto_out_1_a_bits_data;
  wire [63:0] i_auto_out_1_a_bits_data;
  wire g_auto_out_1_d_ready;
  wire i_auto_out_1_d_ready;
  wire g_auto_out_0_a_valid;
  wire i_auto_out_0_a_valid;
  wire [3:0] g_auto_out_0_a_bits_opcode;
  wire [3:0] i_auto_out_0_a_bits_opcode;
  wire [2:0] g_auto_out_0_a_bits_param;
  wire [2:0] i_auto_out_0_a_bits_param;
  wire [2:0] g_auto_out_0_a_bits_size;
  wire [2:0] i_auto_out_0_a_bits_size;
  wire [14:0] g_auto_out_0_a_bits_source;
  wire [14:0] i_auto_out_0_a_bits_source;
  wire [48:0] g_auto_out_0_a_bits_address;
  wire [48:0] i_auto_out_0_a_bits_address;
  wire [7:0] g_auto_out_0_a_bits_mask;
  wire [7:0] i_auto_out_0_a_bits_mask;
  wire [63:0] g_auto_out_0_a_bits_data;
  wire [63:0] i_auto_out_0_a_bits_data;
  wire g_auto_out_0_a_bits_corrupt;
  wire i_auto_out_0_a_bits_corrupt;
  wire g_auto_out_0_d_ready;
  wire i_auto_out_0_d_ready;

  TLXbar_1 u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_1_a_ready(g_auto_in_1_a_ready),
    .auto_in_1_a_valid(auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_size(auto_in_1_a_bits_size),
    .auto_in_1_a_bits_address(auto_in_1_a_bits_address),
    .auto_in_1_a_bits_mask(auto_in_1_a_bits_mask),
    .auto_in_1_a_bits_data(auto_in_1_a_bits_data),
    .auto_in_1_d_ready(auto_in_1_d_ready),
    .auto_in_1_d_valid(g_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode(g_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param(g_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size(g_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_sink(g_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied(g_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data(g_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt(g_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready(g_auto_in_0_a_ready),
    .auto_in_0_a_valid(auto_in_0_a_valid),
    .auto_in_0_a_bits_opcode(auto_in_0_a_bits_opcode),
    .auto_in_0_a_bits_param(auto_in_0_a_bits_param),
    .auto_in_0_a_bits_size(auto_in_0_a_bits_size),
    .auto_in_0_a_bits_source(auto_in_0_a_bits_source),
    .auto_in_0_a_bits_address(auto_in_0_a_bits_address),
    .auto_in_0_a_bits_user_amba_prot_bufferable(auto_in_0_a_bits_user_amba_prot_bufferable),
    .auto_in_0_a_bits_user_amba_prot_modifiable(auto_in_0_a_bits_user_amba_prot_modifiable),
    .auto_in_0_a_bits_user_amba_prot_readalloc(auto_in_0_a_bits_user_amba_prot_readalloc),
    .auto_in_0_a_bits_user_amba_prot_writealloc(auto_in_0_a_bits_user_amba_prot_writealloc),
    .auto_in_0_a_bits_user_amba_prot_privileged(auto_in_0_a_bits_user_amba_prot_privileged),
    .auto_in_0_a_bits_user_amba_prot_secure(auto_in_0_a_bits_user_amba_prot_secure),
    .auto_in_0_a_bits_user_amba_prot_fetch(auto_in_0_a_bits_user_amba_prot_fetch),
    .auto_in_0_a_bits_mask(auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(auto_in_0_a_bits_corrupt),
    .auto_in_0_d_ready(auto_in_0_d_ready),
    .auto_in_0_d_valid(g_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(g_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(g_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(g_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source(g_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink(g_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(g_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_data(g_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(g_auto_in_0_d_bits_corrupt),
    .auto_out_2_a_ready(auto_out_2_a_ready),
    .auto_out_2_a_valid(g_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(g_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(g_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(g_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(g_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(g_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_mask(g_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(g_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(g_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready(g_auto_out_2_d_ready),
    .auto_out_2_d_valid(auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_data(auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(auto_out_2_d_bits_corrupt),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(g_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(g_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_size(g_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(g_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(g_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_amba_prot_bufferable(g_auto_out_1_a_bits_user_amba_prot_bufferable),
    .auto_out_1_a_bits_user_amba_prot_modifiable(g_auto_out_1_a_bits_user_amba_prot_modifiable),
    .auto_out_1_a_bits_user_amba_prot_readalloc(g_auto_out_1_a_bits_user_amba_prot_readalloc),
    .auto_out_1_a_bits_user_amba_prot_writealloc(g_auto_out_1_a_bits_user_amba_prot_writealloc),
    .auto_out_1_a_bits_user_amba_prot_privileged(g_auto_out_1_a_bits_user_amba_prot_privileged),
    .auto_out_1_a_bits_user_amba_prot_secure(g_auto_out_1_a_bits_user_amba_prot_secure),
    .auto_out_1_a_bits_user_amba_prot_fetch(g_auto_out_1_a_bits_user_amba_prot_fetch),
    .auto_out_1_a_bits_mask(g_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(g_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(g_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_size(auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_denied(auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(auto_out_1_d_bits_corrupt),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(g_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(g_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(g_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(g_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(g_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(g_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(g_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(g_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(g_auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(g_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_size(auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt)
  );

  TLXbar_1_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_1_a_ready(i_auto_in_1_a_ready),
    .auto_in_1_a_valid(auto_in_1_a_valid),
    .auto_in_1_a_bits_opcode(auto_in_1_a_bits_opcode),
    .auto_in_1_a_bits_size(auto_in_1_a_bits_size),
    .auto_in_1_a_bits_address(auto_in_1_a_bits_address),
    .auto_in_1_a_bits_mask(auto_in_1_a_bits_mask),
    .auto_in_1_a_bits_data(auto_in_1_a_bits_data),
    .auto_in_1_d_ready(auto_in_1_d_ready),
    .auto_in_1_d_valid(i_auto_in_1_d_valid),
    .auto_in_1_d_bits_opcode(i_auto_in_1_d_bits_opcode),
    .auto_in_1_d_bits_param(i_auto_in_1_d_bits_param),
    .auto_in_1_d_bits_size(i_auto_in_1_d_bits_size),
    .auto_in_1_d_bits_sink(i_auto_in_1_d_bits_sink),
    .auto_in_1_d_bits_denied(i_auto_in_1_d_bits_denied),
    .auto_in_1_d_bits_data(i_auto_in_1_d_bits_data),
    .auto_in_1_d_bits_corrupt(i_auto_in_1_d_bits_corrupt),
    .auto_in_0_a_ready(i_auto_in_0_a_ready),
    .auto_in_0_a_valid(auto_in_0_a_valid),
    .auto_in_0_a_bits_opcode(auto_in_0_a_bits_opcode),
    .auto_in_0_a_bits_param(auto_in_0_a_bits_param),
    .auto_in_0_a_bits_size(auto_in_0_a_bits_size),
    .auto_in_0_a_bits_source(auto_in_0_a_bits_source),
    .auto_in_0_a_bits_address(auto_in_0_a_bits_address),
    .auto_in_0_a_bits_user_amba_prot_bufferable(auto_in_0_a_bits_user_amba_prot_bufferable),
    .auto_in_0_a_bits_user_amba_prot_modifiable(auto_in_0_a_bits_user_amba_prot_modifiable),
    .auto_in_0_a_bits_user_amba_prot_readalloc(auto_in_0_a_bits_user_amba_prot_readalloc),
    .auto_in_0_a_bits_user_amba_prot_writealloc(auto_in_0_a_bits_user_amba_prot_writealloc),
    .auto_in_0_a_bits_user_amba_prot_privileged(auto_in_0_a_bits_user_amba_prot_privileged),
    .auto_in_0_a_bits_user_amba_prot_secure(auto_in_0_a_bits_user_amba_prot_secure),
    .auto_in_0_a_bits_user_amba_prot_fetch(auto_in_0_a_bits_user_amba_prot_fetch),
    .auto_in_0_a_bits_mask(auto_in_0_a_bits_mask),
    .auto_in_0_a_bits_data(auto_in_0_a_bits_data),
    .auto_in_0_a_bits_corrupt(auto_in_0_a_bits_corrupt),
    .auto_in_0_d_ready(auto_in_0_d_ready),
    .auto_in_0_d_valid(i_auto_in_0_d_valid),
    .auto_in_0_d_bits_opcode(i_auto_in_0_d_bits_opcode),
    .auto_in_0_d_bits_param(i_auto_in_0_d_bits_param),
    .auto_in_0_d_bits_size(i_auto_in_0_d_bits_size),
    .auto_in_0_d_bits_source(i_auto_in_0_d_bits_source),
    .auto_in_0_d_bits_sink(i_auto_in_0_d_bits_sink),
    .auto_in_0_d_bits_denied(i_auto_in_0_d_bits_denied),
    .auto_in_0_d_bits_data(i_auto_in_0_d_bits_data),
    .auto_in_0_d_bits_corrupt(i_auto_in_0_d_bits_corrupt),
    .auto_out_2_a_ready(auto_out_2_a_ready),
    .auto_out_2_a_valid(i_auto_out_2_a_valid),
    .auto_out_2_a_bits_opcode(i_auto_out_2_a_bits_opcode),
    .auto_out_2_a_bits_param(i_auto_out_2_a_bits_param),
    .auto_out_2_a_bits_size(i_auto_out_2_a_bits_size),
    .auto_out_2_a_bits_source(i_auto_out_2_a_bits_source),
    .auto_out_2_a_bits_address(i_auto_out_2_a_bits_address),
    .auto_out_2_a_bits_mask(i_auto_out_2_a_bits_mask),
    .auto_out_2_a_bits_data(i_auto_out_2_a_bits_data),
    .auto_out_2_a_bits_corrupt(i_auto_out_2_a_bits_corrupt),
    .auto_out_2_d_ready(i_auto_out_2_d_ready),
    .auto_out_2_d_valid(auto_out_2_d_valid),
    .auto_out_2_d_bits_opcode(auto_out_2_d_bits_opcode),
    .auto_out_2_d_bits_param(auto_out_2_d_bits_param),
    .auto_out_2_d_bits_size(auto_out_2_d_bits_size),
    .auto_out_2_d_bits_source(auto_out_2_d_bits_source),
    .auto_out_2_d_bits_sink(auto_out_2_d_bits_sink),
    .auto_out_2_d_bits_denied(auto_out_2_d_bits_denied),
    .auto_out_2_d_bits_data(auto_out_2_d_bits_data),
    .auto_out_2_d_bits_corrupt(auto_out_2_d_bits_corrupt),
    .auto_out_1_a_ready(auto_out_1_a_ready),
    .auto_out_1_a_valid(i_auto_out_1_a_valid),
    .auto_out_1_a_bits_opcode(i_auto_out_1_a_bits_opcode),
    .auto_out_1_a_bits_size(i_auto_out_1_a_bits_size),
    .auto_out_1_a_bits_source(i_auto_out_1_a_bits_source),
    .auto_out_1_a_bits_address(i_auto_out_1_a_bits_address),
    .auto_out_1_a_bits_user_amba_prot_bufferable(i_auto_out_1_a_bits_user_amba_prot_bufferable),
    .auto_out_1_a_bits_user_amba_prot_modifiable(i_auto_out_1_a_bits_user_amba_prot_modifiable),
    .auto_out_1_a_bits_user_amba_prot_readalloc(i_auto_out_1_a_bits_user_amba_prot_readalloc),
    .auto_out_1_a_bits_user_amba_prot_writealloc(i_auto_out_1_a_bits_user_amba_prot_writealloc),
    .auto_out_1_a_bits_user_amba_prot_privileged(i_auto_out_1_a_bits_user_amba_prot_privileged),
    .auto_out_1_a_bits_user_amba_prot_secure(i_auto_out_1_a_bits_user_amba_prot_secure),
    .auto_out_1_a_bits_user_amba_prot_fetch(i_auto_out_1_a_bits_user_amba_prot_fetch),
    .auto_out_1_a_bits_mask(i_auto_out_1_a_bits_mask),
    .auto_out_1_a_bits_data(i_auto_out_1_a_bits_data),
    .auto_out_1_d_ready(i_auto_out_1_d_ready),
    .auto_out_1_d_valid(auto_out_1_d_valid),
    .auto_out_1_d_bits_opcode(auto_out_1_d_bits_opcode),
    .auto_out_1_d_bits_size(auto_out_1_d_bits_size),
    .auto_out_1_d_bits_source(auto_out_1_d_bits_source),
    .auto_out_1_d_bits_denied(auto_out_1_d_bits_denied),
    .auto_out_1_d_bits_data(auto_out_1_d_bits_data),
    .auto_out_1_d_bits_corrupt(auto_out_1_d_bits_corrupt),
    .auto_out_0_a_ready(auto_out_0_a_ready),
    .auto_out_0_a_valid(i_auto_out_0_a_valid),
    .auto_out_0_a_bits_opcode(i_auto_out_0_a_bits_opcode),
    .auto_out_0_a_bits_param(i_auto_out_0_a_bits_param),
    .auto_out_0_a_bits_size(i_auto_out_0_a_bits_size),
    .auto_out_0_a_bits_source(i_auto_out_0_a_bits_source),
    .auto_out_0_a_bits_address(i_auto_out_0_a_bits_address),
    .auto_out_0_a_bits_mask(i_auto_out_0_a_bits_mask),
    .auto_out_0_a_bits_data(i_auto_out_0_a_bits_data),
    .auto_out_0_a_bits_corrupt(i_auto_out_0_a_bits_corrupt),
    .auto_out_0_d_ready(i_auto_out_0_d_ready),
    .auto_out_0_d_valid(auto_out_0_d_valid),
    .auto_out_0_d_bits_opcode(auto_out_0_d_bits_opcode),
    .auto_out_0_d_bits_size(auto_out_0_d_bits_size),
    .auto_out_0_d_bits_source(auto_out_0_d_bits_source),
    .auto_out_0_d_bits_corrupt(auto_out_0_d_bits_corrupt)
  );

  task automatic drive_random_inputs();
    int unsigned sel;
    auto_in_1_a_valid <= $urandom_range(0, 1);
    auto_in_1_a_bits_opcode <= 4'({$urandom});
    auto_in_1_a_bits_size <= 3'($urandom_range(0, 6));
    sel = $urandom_range(0, 3);
    if (sel == 0) auto_in_1_a_bits_address <= 49'h1000000000000 | 49'($urandom);
    else if (sel == 1) begin
      case ($urandom_range(0, 4))
        0: auto_in_1_a_bits_address <= 49'h0000000000000 + $urandom_range(0, 4095);
        1: auto_in_1_a_bits_address <= 49'h0000020000000 + $urandom_range(0, 4095);
        2: auto_in_1_a_bits_address <= 49'h0000038011000 + $urandom_range(0, 4095);
        3: auto_in_1_a_bits_address <= 49'h000003a001000 + $urandom_range(0, 4095);
        4: auto_in_1_a_bits_address <= 49'h0000040000000 + $urandom_range(0, 4095);
      endcase
    end else if (sel == 2) begin
      case ($urandom_range(0, 3))
        0: auto_in_1_a_bits_address <= 49'h0000038000000 + $urandom_range(0, 4095);
        1: auto_in_1_a_bits_address <= 49'h0000038020000 + $urandom_range(0, 4095);
        2: auto_in_1_a_bits_address <= 49'h000003a000000 + $urandom_range(0, 4095);
        3: auto_in_1_a_bits_address <= 49'h000003c000000 + $urandom_range(0, 4095);
      endcase
    end else auto_in_1_a_bits_address <= 49'({$urandom, $urandom});
    auto_in_1_a_bits_mask <= 8'({$urandom});
    auto_in_1_a_bits_data <= 64'({$urandom, $urandom});
    auto_in_1_d_ready <= $urandom_range(0, 1);
    auto_in_0_a_valid <= $urandom_range(0, 1);
    auto_in_0_a_bits_opcode <= 4'({$urandom});
    auto_in_0_a_bits_param <= 3'({$urandom});
    auto_in_0_a_bits_size <= 3'($urandom_range(0, 6));
    auto_in_0_a_bits_source <= 14'({$urandom});
    sel = $urandom_range(0, 3);
    if (sel == 0) auto_in_0_a_bits_address <= 49'h1000000000000 | 49'($urandom);
    else if (sel == 1) begin
      case ($urandom_range(0, 4))
        0: auto_in_0_a_bits_address <= 49'h0000000000000 + $urandom_range(0, 4095);
        1: auto_in_0_a_bits_address <= 49'h0000020000000 + $urandom_range(0, 4095);
        2: auto_in_0_a_bits_address <= 49'h0000038011000 + $urandom_range(0, 4095);
        3: auto_in_0_a_bits_address <= 49'h000003a001000 + $urandom_range(0, 4095);
        4: auto_in_0_a_bits_address <= 49'h0000040000000 + $urandom_range(0, 4095);
      endcase
    end else if (sel == 2) begin
      case ($urandom_range(0, 3))
        0: auto_in_0_a_bits_address <= 49'h0000038000000 + $urandom_range(0, 4095);
        1: auto_in_0_a_bits_address <= 49'h0000038020000 + $urandom_range(0, 4095);
        2: auto_in_0_a_bits_address <= 49'h000003a000000 + $urandom_range(0, 4095);
        3: auto_in_0_a_bits_address <= 49'h000003c000000 + $urandom_range(0, 4095);
      endcase
    end else auto_in_0_a_bits_address <= 49'({$urandom, $urandom});
    auto_in_0_a_bits_user_amba_prot_bufferable <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_modifiable <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_readalloc <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_writealloc <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_privileged <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_secure <= $urandom_range(0, 1);
    auto_in_0_a_bits_user_amba_prot_fetch <= $urandom_range(0, 1);
    auto_in_0_a_bits_mask <= 8'({$urandom});
    auto_in_0_a_bits_data <= 64'({$urandom, $urandom});
    auto_in_0_a_bits_corrupt <= $urandom_range(0, 1);
    auto_in_0_d_ready <= $urandom_range(0, 1);
    auto_out_2_a_ready <= $urandom_range(0, 1);
    auto_out_2_d_valid <= $urandom_range(0, 1);
    auto_out_2_d_bits_opcode <= 4'({$urandom});
    auto_out_2_d_bits_param <= 2'({$urandom});
    auto_out_2_d_bits_size <= 2'($urandom_range(0, 6));
    sel = $urandom_range(0, 2);
    if (sel == 0) auto_out_2_d_bits_source <= 15'($urandom_range(0, 16383));
    else if (sel == 1) auto_out_2_d_bits_source <= 15'h4000;
    else auto_out_2_d_bits_source <= 15'({$urandom});
    auto_out_2_d_bits_sink <= $urandom_range(0, 1);
    auto_out_2_d_bits_denied <= $urandom_range(0, 1);
    auto_out_2_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_2_d_bits_corrupt <= $urandom_range(0, 1);
    auto_out_1_a_ready <= $urandom_range(0, 1);
    auto_out_1_d_valid <= $urandom_range(0, 1);
    auto_out_1_d_bits_opcode <= 4'({$urandom});
    auto_out_1_d_bits_size <= 3'($urandom_range(0, 6));
    sel = $urandom_range(0, 2);
    if (sel == 0) auto_out_1_d_bits_source <= 15'($urandom_range(0, 16383));
    else if (sel == 1) auto_out_1_d_bits_source <= 15'h4000;
    else auto_out_1_d_bits_source <= 15'({$urandom});
    auto_out_1_d_bits_denied <= $urandom_range(0, 1);
    auto_out_1_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_1_d_bits_corrupt <= $urandom_range(0, 1);
    auto_out_0_a_ready <= $urandom_range(0, 1);
    auto_out_0_d_valid <= $urandom_range(0, 1);
    auto_out_0_d_bits_opcode <= 4'({$urandom});
    auto_out_0_d_bits_size <= 3'($urandom_range(0, 6));
    sel = $urandom_range(0, 2);
    if (sel == 0) auto_out_0_d_bits_source <= 15'($urandom_range(0, 16383));
    else if (sel == 1) auto_out_0_d_bits_source <= 15'h4000;
    else auto_out_0_d_bits_source <= 15'({$urandom});
    auto_out_0_d_bits_corrupt <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_1_a_ready)
    `CHECK(auto_in_1_d_valid)
    `CHECK(auto_in_1_d_bits_opcode)
    `CHECK(auto_in_1_d_bits_param)
    `CHECK(auto_in_1_d_bits_size)
    `CHECK(auto_in_1_d_bits_sink)
    `CHECK(auto_in_1_d_bits_denied)
    `CHECK(auto_in_1_d_bits_data)
    `CHECK(auto_in_1_d_bits_corrupt)
    `CHECK(auto_in_0_a_ready)
    `CHECK(auto_in_0_d_valid)
    `CHECK(auto_in_0_d_bits_opcode)
    `CHECK(auto_in_0_d_bits_param)
    `CHECK(auto_in_0_d_bits_size)
    `CHECK(auto_in_0_d_bits_source)
    `CHECK(auto_in_0_d_bits_sink)
    `CHECK(auto_in_0_d_bits_denied)
    `CHECK(auto_in_0_d_bits_data)
    `CHECK(auto_in_0_d_bits_corrupt)
    `CHECK(auto_out_2_a_valid)
    `CHECK(auto_out_2_a_bits_opcode)
    `CHECK(auto_out_2_a_bits_param)
    `CHECK(auto_out_2_a_bits_size)
    `CHECK(auto_out_2_a_bits_source)
    `CHECK(auto_out_2_a_bits_address)
    `CHECK(auto_out_2_a_bits_mask)
    `CHECK(auto_out_2_a_bits_data)
    `CHECK(auto_out_2_a_bits_corrupt)
    `CHECK(auto_out_2_d_ready)
    `CHECK(auto_out_1_a_valid)
    `CHECK(auto_out_1_a_bits_opcode)
    `CHECK(auto_out_1_a_bits_size)
    `CHECK(auto_out_1_a_bits_source)
    `CHECK(auto_out_1_a_bits_address)
    `CHECK(auto_out_1_a_bits_user_amba_prot_bufferable)
    `CHECK(auto_out_1_a_bits_user_amba_prot_modifiable)
    `CHECK(auto_out_1_a_bits_user_amba_prot_readalloc)
    `CHECK(auto_out_1_a_bits_user_amba_prot_writealloc)
    `CHECK(auto_out_1_a_bits_user_amba_prot_privileged)
    `CHECK(auto_out_1_a_bits_user_amba_prot_secure)
    `CHECK(auto_out_1_a_bits_user_amba_prot_fetch)
    `CHECK(auto_out_1_a_bits_mask)
    `CHECK(auto_out_1_a_bits_data)
    `CHECK(auto_out_1_d_ready)
    `CHECK(auto_out_0_a_valid)
    `CHECK(auto_out_0_a_bits_opcode)
    `CHECK(auto_out_0_a_bits_param)
    `CHECK(auto_out_0_a_bits_size)
    `CHECK(auto_out_0_a_bits_source)
    `CHECK(auto_out_0_a_bits_address)
    `CHECK(auto_out_0_a_bits_mask)
    `CHECK(auto_out_0_a_bits_data)
    `CHECK(auto_out_0_a_bits_corrupt)
    `CHECK(auto_out_0_d_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_1_a_valid = '0;
    auto_in_1_a_bits_opcode = '0;
    auto_in_1_a_bits_size = '0;
    auto_in_1_a_bits_address = '0;
    auto_in_1_a_bits_mask = '0;
    auto_in_1_a_bits_data = '0;
    auto_in_1_d_ready = '0;
    auto_in_0_a_valid = '0;
    auto_in_0_a_bits_opcode = '0;
    auto_in_0_a_bits_param = '0;
    auto_in_0_a_bits_size = '0;
    auto_in_0_a_bits_source = '0;
    auto_in_0_a_bits_address = '0;
    auto_in_0_a_bits_user_amba_prot_bufferable = '0;
    auto_in_0_a_bits_user_amba_prot_modifiable = '0;
    auto_in_0_a_bits_user_amba_prot_readalloc = '0;
    auto_in_0_a_bits_user_amba_prot_writealloc = '0;
    auto_in_0_a_bits_user_amba_prot_privileged = '0;
    auto_in_0_a_bits_user_amba_prot_secure = '0;
    auto_in_0_a_bits_user_amba_prot_fetch = '0;
    auto_in_0_a_bits_mask = '0;
    auto_in_0_a_bits_data = '0;
    auto_in_0_a_bits_corrupt = '0;
    auto_in_0_d_ready = '0;
    auto_out_2_a_ready = '0;
    auto_out_2_d_valid = '0;
    auto_out_2_d_bits_opcode = '0;
    auto_out_2_d_bits_param = '0;
    auto_out_2_d_bits_size = '0;
    auto_out_2_d_bits_source = '0;
    auto_out_2_d_bits_sink = '0;
    auto_out_2_d_bits_denied = '0;
    auto_out_2_d_bits_data = '0;
    auto_out_2_d_bits_corrupt = '0;
    auto_out_1_a_ready = '0;
    auto_out_1_d_valid = '0;
    auto_out_1_d_bits_opcode = '0;
    auto_out_1_d_bits_size = '0;
    auto_out_1_d_bits_source = '0;
    auto_out_1_d_bits_denied = '0;
    auto_out_1_d_bits_data = '0;
    auto_out_1_d_bits_corrupt = '0;
    auto_out_0_a_ready = '0;
    auto_out_0_d_valid = '0;
    auto_out_0_d_bits_opcode = '0;
    auto_out_0_d_bits_size = '0;
    auto_out_0_d_bits_source = '0;
    auto_out_0_d_bits_corrupt = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("TLXbar_1 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
