// 自动生成：scripts/gen_axi4xbar.py —— 勿手改
// AXI4Xbar 双例化逐拍比对: golden AXI4Xbar vs 可读 AXI4Xbar_xs。
// 激励: 两主口 AW/AR 49 位随机地址 (≈50% MEM/MMIO); id 随机; 从口响应/握手随机。
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

  logic auto_in_1_aw_valid;
  logic [4:0] auto_in_1_aw_bits_id;
  logic [48:0] auto_in_1_aw_bits_addr;
  logic [7:0] auto_in_1_aw_bits_len;
  logic [2:0] auto_in_1_aw_bits_size;
  logic [1:0] auto_in_1_aw_bits_burst;
  logic [3:0] auto_in_1_aw_bits_cache;
  logic [3:0] auto_in_1_aw_bits_qos;
  logic auto_in_1_w_valid;
  logic [255:0] auto_in_1_w_bits_data;
  logic [31:0] auto_in_1_w_bits_strb;
  logic auto_in_1_w_bits_last;
  logic auto_in_1_ar_valid;
  logic [4:0] auto_in_1_ar_bits_id;
  logic [48:0] auto_in_1_ar_bits_addr;
  logic [7:0] auto_in_1_ar_bits_len;
  logic [2:0] auto_in_1_ar_bits_size;
  logic [1:0] auto_in_1_ar_bits_burst;
  logic [3:0] auto_in_1_ar_bits_cache;
  logic [3:0] auto_in_1_ar_bits_qos;
  logic auto_in_0_aw_valid;
  logic [5:0] auto_in_0_aw_bits_id;
  logic [48:0] auto_in_0_aw_bits_addr;
  logic [7:0] auto_in_0_aw_bits_len;
  logic [2:0] auto_in_0_aw_bits_size;
  logic [1:0] auto_in_0_aw_bits_burst;
  logic [3:0] auto_in_0_aw_bits_qos;
  logic auto_in_0_w_valid;
  logic [255:0] auto_in_0_w_bits_data;
  logic [31:0] auto_in_0_w_bits_strb;
  logic auto_in_0_w_bits_last;
  logic auto_in_0_ar_valid;
  logic [5:0] auto_in_0_ar_bits_id;
  logic [48:0] auto_in_0_ar_bits_addr;
  logic [7:0] auto_in_0_ar_bits_len;
  logic [2:0] auto_in_0_ar_bits_size;
  logic [1:0] auto_in_0_ar_bits_burst;
  logic [3:0] auto_in_0_ar_bits_qos;
  logic auto_out_1_aw_ready;
  logic auto_out_1_w_ready;
  logic auto_out_1_b_valid;
  logic [6:0] auto_out_1_b_bits_id;
  logic auto_out_1_ar_ready;
  logic auto_out_1_r_valid;
  logic [6:0] auto_out_1_r_bits_id;
  logic [255:0] auto_out_1_r_bits_data;
  logic auto_out_1_r_bits_last;
  logic auto_out_0_aw_ready;
  logic auto_out_0_w_ready;
  logic auto_out_0_b_valid;
  logic [6:0] auto_out_0_b_bits_id;
  logic auto_out_0_ar_ready;
  logic auto_out_0_r_valid;
  logic [6:0] auto_out_0_r_bits_id;
  logic [255:0] auto_out_0_r_bits_data;
  logic auto_out_0_r_bits_last;
  wire g_auto_in_1_aw_ready;
  wire i_auto_in_1_aw_ready;
  wire g_auto_in_1_w_ready;
  wire i_auto_in_1_w_ready;
  wire g_auto_in_1_b_valid;
  wire i_auto_in_1_b_valid;
  wire [4:0] g_auto_in_1_b_bits_id;
  wire [4:0] i_auto_in_1_b_bits_id;
  wire g_auto_in_1_ar_ready;
  wire i_auto_in_1_ar_ready;
  wire g_auto_in_1_r_valid;
  wire i_auto_in_1_r_valid;
  wire [4:0] g_auto_in_1_r_bits_id;
  wire [4:0] i_auto_in_1_r_bits_id;
  wire [255:0] g_auto_in_1_r_bits_data;
  wire [255:0] i_auto_in_1_r_bits_data;
  wire g_auto_in_1_r_bits_last;
  wire i_auto_in_1_r_bits_last;
  wire g_auto_in_0_aw_ready;
  wire i_auto_in_0_aw_ready;
  wire g_auto_in_0_w_ready;
  wire i_auto_in_0_w_ready;
  wire g_auto_in_0_b_valid;
  wire i_auto_in_0_b_valid;
  wire [5:0] g_auto_in_0_b_bits_id;
  wire [5:0] i_auto_in_0_b_bits_id;
  wire g_auto_in_0_ar_ready;
  wire i_auto_in_0_ar_ready;
  wire g_auto_in_0_r_valid;
  wire i_auto_in_0_r_valid;
  wire [5:0] g_auto_in_0_r_bits_id;
  wire [5:0] i_auto_in_0_r_bits_id;
  wire [255:0] g_auto_in_0_r_bits_data;
  wire [255:0] i_auto_in_0_r_bits_data;
  wire g_auto_in_0_r_bits_last;
  wire i_auto_in_0_r_bits_last;
  wire g_auto_out_1_aw_valid;
  wire i_auto_out_1_aw_valid;
  wire [6:0] g_auto_out_1_aw_bits_id;
  wire [6:0] i_auto_out_1_aw_bits_id;
  wire [48:0] g_auto_out_1_aw_bits_addr;
  wire [48:0] i_auto_out_1_aw_bits_addr;
  wire [7:0] g_auto_out_1_aw_bits_len;
  wire [7:0] i_auto_out_1_aw_bits_len;
  wire [2:0] g_auto_out_1_aw_bits_size;
  wire [2:0] i_auto_out_1_aw_bits_size;
  wire [3:0] g_auto_out_1_aw_bits_cache;
  wire [3:0] i_auto_out_1_aw_bits_cache;
  wire [2:0] g_auto_out_1_aw_bits_prot;
  wire [2:0] i_auto_out_1_aw_bits_prot;
  wire g_auto_out_1_w_valid;
  wire i_auto_out_1_w_valid;
  wire [255:0] g_auto_out_1_w_bits_data;
  wire [255:0] i_auto_out_1_w_bits_data;
  wire [31:0] g_auto_out_1_w_bits_strb;
  wire [31:0] i_auto_out_1_w_bits_strb;
  wire g_auto_out_1_w_bits_last;
  wire i_auto_out_1_w_bits_last;
  wire g_auto_out_1_b_ready;
  wire i_auto_out_1_b_ready;
  wire g_auto_out_1_ar_valid;
  wire i_auto_out_1_ar_valid;
  wire [6:0] g_auto_out_1_ar_bits_id;
  wire [6:0] i_auto_out_1_ar_bits_id;
  wire [48:0] g_auto_out_1_ar_bits_addr;
  wire [48:0] i_auto_out_1_ar_bits_addr;
  wire [7:0] g_auto_out_1_ar_bits_len;
  wire [7:0] i_auto_out_1_ar_bits_len;
  wire [2:0] g_auto_out_1_ar_bits_size;
  wire [2:0] i_auto_out_1_ar_bits_size;
  wire [3:0] g_auto_out_1_ar_bits_cache;
  wire [3:0] i_auto_out_1_ar_bits_cache;
  wire [2:0] g_auto_out_1_ar_bits_prot;
  wire [2:0] i_auto_out_1_ar_bits_prot;
  wire g_auto_out_1_r_ready;
  wire i_auto_out_1_r_ready;
  wire g_auto_out_0_aw_valid;
  wire i_auto_out_0_aw_valid;
  wire [6:0] g_auto_out_0_aw_bits_id;
  wire [6:0] i_auto_out_0_aw_bits_id;
  wire [47:0] g_auto_out_0_aw_bits_addr;
  wire [47:0] i_auto_out_0_aw_bits_addr;
  wire [7:0] g_auto_out_0_aw_bits_len;
  wire [7:0] i_auto_out_0_aw_bits_len;
  wire [2:0] g_auto_out_0_aw_bits_size;
  wire [2:0] i_auto_out_0_aw_bits_size;
  wire [1:0] g_auto_out_0_aw_bits_burst;
  wire [1:0] i_auto_out_0_aw_bits_burst;
  wire [3:0] g_auto_out_0_aw_bits_cache;
  wire [3:0] i_auto_out_0_aw_bits_cache;
  wire [2:0] g_auto_out_0_aw_bits_prot;
  wire [2:0] i_auto_out_0_aw_bits_prot;
  wire [3:0] g_auto_out_0_aw_bits_qos;
  wire [3:0] i_auto_out_0_aw_bits_qos;
  wire g_auto_out_0_w_valid;
  wire i_auto_out_0_w_valid;
  wire [255:0] g_auto_out_0_w_bits_data;
  wire [255:0] i_auto_out_0_w_bits_data;
  wire [31:0] g_auto_out_0_w_bits_strb;
  wire [31:0] i_auto_out_0_w_bits_strb;
  wire g_auto_out_0_w_bits_last;
  wire i_auto_out_0_w_bits_last;
  wire g_auto_out_0_b_ready;
  wire i_auto_out_0_b_ready;
  wire g_auto_out_0_ar_valid;
  wire i_auto_out_0_ar_valid;
  wire [6:0] g_auto_out_0_ar_bits_id;
  wire [6:0] i_auto_out_0_ar_bits_id;
  wire [47:0] g_auto_out_0_ar_bits_addr;
  wire [47:0] i_auto_out_0_ar_bits_addr;
  wire [7:0] g_auto_out_0_ar_bits_len;
  wire [7:0] i_auto_out_0_ar_bits_len;
  wire [2:0] g_auto_out_0_ar_bits_size;
  wire [2:0] i_auto_out_0_ar_bits_size;
  wire [1:0] g_auto_out_0_ar_bits_burst;
  wire [1:0] i_auto_out_0_ar_bits_burst;
  wire [3:0] g_auto_out_0_ar_bits_cache;
  wire [3:0] i_auto_out_0_ar_bits_cache;
  wire [2:0] g_auto_out_0_ar_bits_prot;
  wire [2:0] i_auto_out_0_ar_bits_prot;
  wire [3:0] g_auto_out_0_ar_bits_qos;
  wire [3:0] i_auto_out_0_ar_bits_qos;
  wire g_auto_out_0_r_ready;
  wire i_auto_out_0_r_ready;

  AXI4Xbar u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_1_aw_ready(g_auto_in_1_aw_ready),
    .auto_in_1_aw_valid(auto_in_1_aw_valid),
    .auto_in_1_aw_bits_id(auto_in_1_aw_bits_id),
    .auto_in_1_aw_bits_addr(auto_in_1_aw_bits_addr),
    .auto_in_1_aw_bits_len(auto_in_1_aw_bits_len),
    .auto_in_1_aw_bits_size(auto_in_1_aw_bits_size),
    .auto_in_1_aw_bits_burst(auto_in_1_aw_bits_burst),
    .auto_in_1_aw_bits_cache(auto_in_1_aw_bits_cache),
    .auto_in_1_aw_bits_qos(auto_in_1_aw_bits_qos),
    .auto_in_1_w_ready(g_auto_in_1_w_ready),
    .auto_in_1_w_valid(auto_in_1_w_valid),
    .auto_in_1_w_bits_data(auto_in_1_w_bits_data),
    .auto_in_1_w_bits_strb(auto_in_1_w_bits_strb),
    .auto_in_1_w_bits_last(auto_in_1_w_bits_last),
    .auto_in_1_b_valid(g_auto_in_1_b_valid),
    .auto_in_1_b_bits_id(g_auto_in_1_b_bits_id),
    .auto_in_1_ar_ready(g_auto_in_1_ar_ready),
    .auto_in_1_ar_valid(auto_in_1_ar_valid),
    .auto_in_1_ar_bits_id(auto_in_1_ar_bits_id),
    .auto_in_1_ar_bits_addr(auto_in_1_ar_bits_addr),
    .auto_in_1_ar_bits_len(auto_in_1_ar_bits_len),
    .auto_in_1_ar_bits_size(auto_in_1_ar_bits_size),
    .auto_in_1_ar_bits_burst(auto_in_1_ar_bits_burst),
    .auto_in_1_ar_bits_cache(auto_in_1_ar_bits_cache),
    .auto_in_1_ar_bits_qos(auto_in_1_ar_bits_qos),
    .auto_in_1_r_valid(g_auto_in_1_r_valid),
    .auto_in_1_r_bits_id(g_auto_in_1_r_bits_id),
    .auto_in_1_r_bits_data(g_auto_in_1_r_bits_data),
    .auto_in_1_r_bits_last(g_auto_in_1_r_bits_last),
    .auto_in_0_aw_ready(g_auto_in_0_aw_ready),
    .auto_in_0_aw_valid(auto_in_0_aw_valid),
    .auto_in_0_aw_bits_id(auto_in_0_aw_bits_id),
    .auto_in_0_aw_bits_addr(auto_in_0_aw_bits_addr),
    .auto_in_0_aw_bits_len(auto_in_0_aw_bits_len),
    .auto_in_0_aw_bits_size(auto_in_0_aw_bits_size),
    .auto_in_0_aw_bits_burst(auto_in_0_aw_bits_burst),
    .auto_in_0_aw_bits_qos(auto_in_0_aw_bits_qos),
    .auto_in_0_w_ready(g_auto_in_0_w_ready),
    .auto_in_0_w_valid(auto_in_0_w_valid),
    .auto_in_0_w_bits_data(auto_in_0_w_bits_data),
    .auto_in_0_w_bits_strb(auto_in_0_w_bits_strb),
    .auto_in_0_w_bits_last(auto_in_0_w_bits_last),
    .auto_in_0_b_valid(g_auto_in_0_b_valid),
    .auto_in_0_b_bits_id(g_auto_in_0_b_bits_id),
    .auto_in_0_ar_ready(g_auto_in_0_ar_ready),
    .auto_in_0_ar_valid(auto_in_0_ar_valid),
    .auto_in_0_ar_bits_id(auto_in_0_ar_bits_id),
    .auto_in_0_ar_bits_addr(auto_in_0_ar_bits_addr),
    .auto_in_0_ar_bits_len(auto_in_0_ar_bits_len),
    .auto_in_0_ar_bits_size(auto_in_0_ar_bits_size),
    .auto_in_0_ar_bits_burst(auto_in_0_ar_bits_burst),
    .auto_in_0_ar_bits_qos(auto_in_0_ar_bits_qos),
    .auto_in_0_r_valid(g_auto_in_0_r_valid),
    .auto_in_0_r_bits_id(g_auto_in_0_r_bits_id),
    .auto_in_0_r_bits_data(g_auto_in_0_r_bits_data),
    .auto_in_0_r_bits_last(g_auto_in_0_r_bits_last),
    .auto_out_1_aw_ready(auto_out_1_aw_ready),
    .auto_out_1_aw_valid(g_auto_out_1_aw_valid),
    .auto_out_1_aw_bits_id(g_auto_out_1_aw_bits_id),
    .auto_out_1_aw_bits_addr(g_auto_out_1_aw_bits_addr),
    .auto_out_1_aw_bits_len(g_auto_out_1_aw_bits_len),
    .auto_out_1_aw_bits_size(g_auto_out_1_aw_bits_size),
    .auto_out_1_aw_bits_cache(g_auto_out_1_aw_bits_cache),
    .auto_out_1_aw_bits_prot(g_auto_out_1_aw_bits_prot),
    .auto_out_1_w_ready(auto_out_1_w_ready),
    .auto_out_1_w_valid(g_auto_out_1_w_valid),
    .auto_out_1_w_bits_data(g_auto_out_1_w_bits_data),
    .auto_out_1_w_bits_strb(g_auto_out_1_w_bits_strb),
    .auto_out_1_w_bits_last(g_auto_out_1_w_bits_last),
    .auto_out_1_b_ready(g_auto_out_1_b_ready),
    .auto_out_1_b_valid(auto_out_1_b_valid),
    .auto_out_1_b_bits_id(auto_out_1_b_bits_id),
    .auto_out_1_ar_ready(auto_out_1_ar_ready),
    .auto_out_1_ar_valid(g_auto_out_1_ar_valid),
    .auto_out_1_ar_bits_id(g_auto_out_1_ar_bits_id),
    .auto_out_1_ar_bits_addr(g_auto_out_1_ar_bits_addr),
    .auto_out_1_ar_bits_len(g_auto_out_1_ar_bits_len),
    .auto_out_1_ar_bits_size(g_auto_out_1_ar_bits_size),
    .auto_out_1_ar_bits_cache(g_auto_out_1_ar_bits_cache),
    .auto_out_1_ar_bits_prot(g_auto_out_1_ar_bits_prot),
    .auto_out_1_r_ready(g_auto_out_1_r_ready),
    .auto_out_1_r_valid(auto_out_1_r_valid),
    .auto_out_1_r_bits_id(auto_out_1_r_bits_id),
    .auto_out_1_r_bits_data(auto_out_1_r_bits_data),
    .auto_out_1_r_bits_last(auto_out_1_r_bits_last),
    .auto_out_0_aw_ready(auto_out_0_aw_ready),
    .auto_out_0_aw_valid(g_auto_out_0_aw_valid),
    .auto_out_0_aw_bits_id(g_auto_out_0_aw_bits_id),
    .auto_out_0_aw_bits_addr(g_auto_out_0_aw_bits_addr),
    .auto_out_0_aw_bits_len(g_auto_out_0_aw_bits_len),
    .auto_out_0_aw_bits_size(g_auto_out_0_aw_bits_size),
    .auto_out_0_aw_bits_burst(g_auto_out_0_aw_bits_burst),
    .auto_out_0_aw_bits_cache(g_auto_out_0_aw_bits_cache),
    .auto_out_0_aw_bits_prot(g_auto_out_0_aw_bits_prot),
    .auto_out_0_aw_bits_qos(g_auto_out_0_aw_bits_qos),
    .auto_out_0_w_ready(auto_out_0_w_ready),
    .auto_out_0_w_valid(g_auto_out_0_w_valid),
    .auto_out_0_w_bits_data(g_auto_out_0_w_bits_data),
    .auto_out_0_w_bits_strb(g_auto_out_0_w_bits_strb),
    .auto_out_0_w_bits_last(g_auto_out_0_w_bits_last),
    .auto_out_0_b_ready(g_auto_out_0_b_ready),
    .auto_out_0_b_valid(auto_out_0_b_valid),
    .auto_out_0_b_bits_id(auto_out_0_b_bits_id),
    .auto_out_0_ar_ready(auto_out_0_ar_ready),
    .auto_out_0_ar_valid(g_auto_out_0_ar_valid),
    .auto_out_0_ar_bits_id(g_auto_out_0_ar_bits_id),
    .auto_out_0_ar_bits_addr(g_auto_out_0_ar_bits_addr),
    .auto_out_0_ar_bits_len(g_auto_out_0_ar_bits_len),
    .auto_out_0_ar_bits_size(g_auto_out_0_ar_bits_size),
    .auto_out_0_ar_bits_burst(g_auto_out_0_ar_bits_burst),
    .auto_out_0_ar_bits_cache(g_auto_out_0_ar_bits_cache),
    .auto_out_0_ar_bits_prot(g_auto_out_0_ar_bits_prot),
    .auto_out_0_ar_bits_qos(g_auto_out_0_ar_bits_qos),
    .auto_out_0_r_ready(g_auto_out_0_r_ready),
    .auto_out_0_r_valid(auto_out_0_r_valid),
    .auto_out_0_r_bits_id(auto_out_0_r_bits_id),
    .auto_out_0_r_bits_data(auto_out_0_r_bits_data),
    .auto_out_0_r_bits_last(auto_out_0_r_bits_last)
  );

  AXI4Xbar_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_1_aw_ready(i_auto_in_1_aw_ready),
    .auto_in_1_aw_valid(auto_in_1_aw_valid),
    .auto_in_1_aw_bits_id(auto_in_1_aw_bits_id),
    .auto_in_1_aw_bits_addr(auto_in_1_aw_bits_addr),
    .auto_in_1_aw_bits_len(auto_in_1_aw_bits_len),
    .auto_in_1_aw_bits_size(auto_in_1_aw_bits_size),
    .auto_in_1_aw_bits_burst(auto_in_1_aw_bits_burst),
    .auto_in_1_aw_bits_cache(auto_in_1_aw_bits_cache),
    .auto_in_1_aw_bits_qos(auto_in_1_aw_bits_qos),
    .auto_in_1_w_ready(i_auto_in_1_w_ready),
    .auto_in_1_w_valid(auto_in_1_w_valid),
    .auto_in_1_w_bits_data(auto_in_1_w_bits_data),
    .auto_in_1_w_bits_strb(auto_in_1_w_bits_strb),
    .auto_in_1_w_bits_last(auto_in_1_w_bits_last),
    .auto_in_1_b_valid(i_auto_in_1_b_valid),
    .auto_in_1_b_bits_id(i_auto_in_1_b_bits_id),
    .auto_in_1_ar_ready(i_auto_in_1_ar_ready),
    .auto_in_1_ar_valid(auto_in_1_ar_valid),
    .auto_in_1_ar_bits_id(auto_in_1_ar_bits_id),
    .auto_in_1_ar_bits_addr(auto_in_1_ar_bits_addr),
    .auto_in_1_ar_bits_len(auto_in_1_ar_bits_len),
    .auto_in_1_ar_bits_size(auto_in_1_ar_bits_size),
    .auto_in_1_ar_bits_burst(auto_in_1_ar_bits_burst),
    .auto_in_1_ar_bits_cache(auto_in_1_ar_bits_cache),
    .auto_in_1_ar_bits_qos(auto_in_1_ar_bits_qos),
    .auto_in_1_r_valid(i_auto_in_1_r_valid),
    .auto_in_1_r_bits_id(i_auto_in_1_r_bits_id),
    .auto_in_1_r_bits_data(i_auto_in_1_r_bits_data),
    .auto_in_1_r_bits_last(i_auto_in_1_r_bits_last),
    .auto_in_0_aw_ready(i_auto_in_0_aw_ready),
    .auto_in_0_aw_valid(auto_in_0_aw_valid),
    .auto_in_0_aw_bits_id(auto_in_0_aw_bits_id),
    .auto_in_0_aw_bits_addr(auto_in_0_aw_bits_addr),
    .auto_in_0_aw_bits_len(auto_in_0_aw_bits_len),
    .auto_in_0_aw_bits_size(auto_in_0_aw_bits_size),
    .auto_in_0_aw_bits_burst(auto_in_0_aw_bits_burst),
    .auto_in_0_aw_bits_qos(auto_in_0_aw_bits_qos),
    .auto_in_0_w_ready(i_auto_in_0_w_ready),
    .auto_in_0_w_valid(auto_in_0_w_valid),
    .auto_in_0_w_bits_data(auto_in_0_w_bits_data),
    .auto_in_0_w_bits_strb(auto_in_0_w_bits_strb),
    .auto_in_0_w_bits_last(auto_in_0_w_bits_last),
    .auto_in_0_b_valid(i_auto_in_0_b_valid),
    .auto_in_0_b_bits_id(i_auto_in_0_b_bits_id),
    .auto_in_0_ar_ready(i_auto_in_0_ar_ready),
    .auto_in_0_ar_valid(auto_in_0_ar_valid),
    .auto_in_0_ar_bits_id(auto_in_0_ar_bits_id),
    .auto_in_0_ar_bits_addr(auto_in_0_ar_bits_addr),
    .auto_in_0_ar_bits_len(auto_in_0_ar_bits_len),
    .auto_in_0_ar_bits_size(auto_in_0_ar_bits_size),
    .auto_in_0_ar_bits_burst(auto_in_0_ar_bits_burst),
    .auto_in_0_ar_bits_qos(auto_in_0_ar_bits_qos),
    .auto_in_0_r_valid(i_auto_in_0_r_valid),
    .auto_in_0_r_bits_id(i_auto_in_0_r_bits_id),
    .auto_in_0_r_bits_data(i_auto_in_0_r_bits_data),
    .auto_in_0_r_bits_last(i_auto_in_0_r_bits_last),
    .auto_out_1_aw_ready(auto_out_1_aw_ready),
    .auto_out_1_aw_valid(i_auto_out_1_aw_valid),
    .auto_out_1_aw_bits_id(i_auto_out_1_aw_bits_id),
    .auto_out_1_aw_bits_addr(i_auto_out_1_aw_bits_addr),
    .auto_out_1_aw_bits_len(i_auto_out_1_aw_bits_len),
    .auto_out_1_aw_bits_size(i_auto_out_1_aw_bits_size),
    .auto_out_1_aw_bits_cache(i_auto_out_1_aw_bits_cache),
    .auto_out_1_aw_bits_prot(i_auto_out_1_aw_bits_prot),
    .auto_out_1_w_ready(auto_out_1_w_ready),
    .auto_out_1_w_valid(i_auto_out_1_w_valid),
    .auto_out_1_w_bits_data(i_auto_out_1_w_bits_data),
    .auto_out_1_w_bits_strb(i_auto_out_1_w_bits_strb),
    .auto_out_1_w_bits_last(i_auto_out_1_w_bits_last),
    .auto_out_1_b_ready(i_auto_out_1_b_ready),
    .auto_out_1_b_valid(auto_out_1_b_valid),
    .auto_out_1_b_bits_id(auto_out_1_b_bits_id),
    .auto_out_1_ar_ready(auto_out_1_ar_ready),
    .auto_out_1_ar_valid(i_auto_out_1_ar_valid),
    .auto_out_1_ar_bits_id(i_auto_out_1_ar_bits_id),
    .auto_out_1_ar_bits_addr(i_auto_out_1_ar_bits_addr),
    .auto_out_1_ar_bits_len(i_auto_out_1_ar_bits_len),
    .auto_out_1_ar_bits_size(i_auto_out_1_ar_bits_size),
    .auto_out_1_ar_bits_cache(i_auto_out_1_ar_bits_cache),
    .auto_out_1_ar_bits_prot(i_auto_out_1_ar_bits_prot),
    .auto_out_1_r_ready(i_auto_out_1_r_ready),
    .auto_out_1_r_valid(auto_out_1_r_valid),
    .auto_out_1_r_bits_id(auto_out_1_r_bits_id),
    .auto_out_1_r_bits_data(auto_out_1_r_bits_data),
    .auto_out_1_r_bits_last(auto_out_1_r_bits_last),
    .auto_out_0_aw_ready(auto_out_0_aw_ready),
    .auto_out_0_aw_valid(i_auto_out_0_aw_valid),
    .auto_out_0_aw_bits_id(i_auto_out_0_aw_bits_id),
    .auto_out_0_aw_bits_addr(i_auto_out_0_aw_bits_addr),
    .auto_out_0_aw_bits_len(i_auto_out_0_aw_bits_len),
    .auto_out_0_aw_bits_size(i_auto_out_0_aw_bits_size),
    .auto_out_0_aw_bits_burst(i_auto_out_0_aw_bits_burst),
    .auto_out_0_aw_bits_cache(i_auto_out_0_aw_bits_cache),
    .auto_out_0_aw_bits_prot(i_auto_out_0_aw_bits_prot),
    .auto_out_0_aw_bits_qos(i_auto_out_0_aw_bits_qos),
    .auto_out_0_w_ready(auto_out_0_w_ready),
    .auto_out_0_w_valid(i_auto_out_0_w_valid),
    .auto_out_0_w_bits_data(i_auto_out_0_w_bits_data),
    .auto_out_0_w_bits_strb(i_auto_out_0_w_bits_strb),
    .auto_out_0_w_bits_last(i_auto_out_0_w_bits_last),
    .auto_out_0_b_ready(i_auto_out_0_b_ready),
    .auto_out_0_b_valid(auto_out_0_b_valid),
    .auto_out_0_b_bits_id(auto_out_0_b_bits_id),
    .auto_out_0_ar_ready(auto_out_0_ar_ready),
    .auto_out_0_ar_valid(i_auto_out_0_ar_valid),
    .auto_out_0_ar_bits_id(i_auto_out_0_ar_bits_id),
    .auto_out_0_ar_bits_addr(i_auto_out_0_ar_bits_addr),
    .auto_out_0_ar_bits_len(i_auto_out_0_ar_bits_len),
    .auto_out_0_ar_bits_size(i_auto_out_0_ar_bits_size),
    .auto_out_0_ar_bits_burst(i_auto_out_0_ar_bits_burst),
    .auto_out_0_ar_bits_cache(i_auto_out_0_ar_bits_cache),
    .auto_out_0_ar_bits_prot(i_auto_out_0_ar_bits_prot),
    .auto_out_0_ar_bits_qos(i_auto_out_0_ar_bits_qos),
    .auto_out_0_r_ready(i_auto_out_0_r_ready),
    .auto_out_0_r_valid(auto_out_0_r_valid),
    .auto_out_0_r_bits_id(auto_out_0_r_bits_id),
    .auto_out_0_r_bits_data(auto_out_0_r_bits_data),
    .auto_out_0_r_bits_last(auto_out_0_r_bits_last)
  );

  function automatic logic [48:0] rand_axi_addr();
    case ($urandom_range(0, 3))
      0: return {18'h0, 31'($urandom)};                 // MMIO 低区 [0, 2^31)
      1: return {1'b0, 16'($urandom), 32'($urandom)} | 49'h0_0000_8000_0000; // MEM [2^31, 2^48)
      2: return {1'b1, 48'($urandom)};                  // MMIO 高位别名 (addr[48]=1)
      default: return 49'({$urandom, $urandom});        // 全随机
    endcase
  endfunction

  task automatic drive_random_inputs();
    auto_in_1_aw_valid <= $urandom_range(0, 1);
    auto_in_1_aw_bits_id <= 5'({$urandom});
    auto_in_1_aw_bits_addr <= rand_axi_addr();
    auto_in_1_aw_bits_len <= 8'({$urandom});
    auto_in_1_aw_bits_size <= 3'({$urandom});
    auto_in_1_aw_bits_burst <= 2'({$urandom});
    auto_in_1_aw_bits_cache <= 4'({$urandom});
    auto_in_1_aw_bits_qos <= 4'({$urandom});
    auto_in_1_w_valid <= $urandom_range(0, 1);
    auto_in_1_w_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_in_1_w_bits_strb <= 32'({$urandom});
    auto_in_1_w_bits_last <= $urandom_range(0, 1);
    auto_in_1_ar_valid <= $urandom_range(0, 1);
    auto_in_1_ar_bits_id <= 5'({$urandom});
    auto_in_1_ar_bits_addr <= rand_axi_addr();
    auto_in_1_ar_bits_len <= 8'({$urandom});
    auto_in_1_ar_bits_size <= 3'({$urandom});
    auto_in_1_ar_bits_burst <= 2'({$urandom});
    auto_in_1_ar_bits_cache <= 4'({$urandom});
    auto_in_1_ar_bits_qos <= 4'({$urandom});
    auto_in_0_aw_valid <= $urandom_range(0, 1);
    auto_in_0_aw_bits_id <= 6'({$urandom});
    auto_in_0_aw_bits_addr <= rand_axi_addr();
    auto_in_0_aw_bits_len <= 8'({$urandom});
    auto_in_0_aw_bits_size <= 3'({$urandom});
    auto_in_0_aw_bits_burst <= 2'({$urandom});
    auto_in_0_aw_bits_qos <= 4'({$urandom});
    auto_in_0_w_valid <= $urandom_range(0, 1);
    auto_in_0_w_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_in_0_w_bits_strb <= 32'({$urandom});
    auto_in_0_w_bits_last <= $urandom_range(0, 1);
    auto_in_0_ar_valid <= $urandom_range(0, 1);
    auto_in_0_ar_bits_id <= 6'({$urandom});
    auto_in_0_ar_bits_addr <= rand_axi_addr();
    auto_in_0_ar_bits_len <= 8'({$urandom});
    auto_in_0_ar_bits_size <= 3'({$urandom});
    auto_in_0_ar_bits_burst <= 2'({$urandom});
    auto_in_0_ar_bits_qos <= 4'({$urandom});
    auto_out_1_aw_ready <= $urandom_range(0, 1);
    auto_out_1_w_ready <= $urandom_range(0, 1);
    auto_out_1_b_valid <= $urandom_range(0, 1);
    auto_out_1_b_bits_id <= 7'({$urandom});
    auto_out_1_ar_ready <= $urandom_range(0, 1);
    auto_out_1_r_valid <= $urandom_range(0, 1);
    auto_out_1_r_bits_id <= 7'({$urandom});
    auto_out_1_r_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_out_1_r_bits_last <= $urandom_range(0, 1);
    auto_out_0_aw_ready <= $urandom_range(0, 1);
    auto_out_0_w_ready <= $urandom_range(0, 1);
    auto_out_0_b_valid <= $urandom_range(0, 1);
    auto_out_0_b_bits_id <= 7'({$urandom});
    auto_out_0_ar_ready <= $urandom_range(0, 1);
    auto_out_0_r_valid <= $urandom_range(0, 1);
    auto_out_0_r_bits_id <= 7'({$urandom});
    auto_out_0_r_bits_data <= 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
    auto_out_0_r_bits_last <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(auto_in_1_aw_ready)
    `CHECK(auto_in_1_w_ready)
    `CHECK(auto_in_1_b_valid)
    `CHECK(auto_in_1_b_bits_id)
    `CHECK(auto_in_1_ar_ready)
    `CHECK(auto_in_1_r_valid)
    `CHECK(auto_in_1_r_bits_id)
    `CHECK(auto_in_1_r_bits_data)
    `CHECK(auto_in_1_r_bits_last)
    `CHECK(auto_in_0_aw_ready)
    `CHECK(auto_in_0_w_ready)
    `CHECK(auto_in_0_b_valid)
    `CHECK(auto_in_0_b_bits_id)
    `CHECK(auto_in_0_ar_ready)
    `CHECK(auto_in_0_r_valid)
    `CHECK(auto_in_0_r_bits_id)
    `CHECK(auto_in_0_r_bits_data)
    `CHECK(auto_in_0_r_bits_last)
    `CHECK(auto_out_1_aw_valid)
    `CHECK(auto_out_1_aw_bits_id)
    `CHECK(auto_out_1_aw_bits_addr)
    `CHECK(auto_out_1_aw_bits_len)
    `CHECK(auto_out_1_aw_bits_size)
    `CHECK(auto_out_1_aw_bits_cache)
    `CHECK(auto_out_1_aw_bits_prot)
    `CHECK(auto_out_1_w_valid)
    `CHECK(auto_out_1_w_bits_data)
    `CHECK(auto_out_1_w_bits_strb)
    `CHECK(auto_out_1_w_bits_last)
    `CHECK(auto_out_1_b_ready)
    `CHECK(auto_out_1_ar_valid)
    `CHECK(auto_out_1_ar_bits_id)
    `CHECK(auto_out_1_ar_bits_addr)
    `CHECK(auto_out_1_ar_bits_len)
    `CHECK(auto_out_1_ar_bits_size)
    `CHECK(auto_out_1_ar_bits_cache)
    `CHECK(auto_out_1_ar_bits_prot)
    `CHECK(auto_out_1_r_ready)
    `CHECK(auto_out_0_aw_valid)
    `CHECK(auto_out_0_aw_bits_id)
    `CHECK(auto_out_0_aw_bits_addr)
    `CHECK(auto_out_0_aw_bits_len)
    `CHECK(auto_out_0_aw_bits_size)
    `CHECK(auto_out_0_aw_bits_burst)
    `CHECK(auto_out_0_aw_bits_cache)
    `CHECK(auto_out_0_aw_bits_prot)
    `CHECK(auto_out_0_aw_bits_qos)
    `CHECK(auto_out_0_w_valid)
    `CHECK(auto_out_0_w_bits_data)
    `CHECK(auto_out_0_w_bits_strb)
    `CHECK(auto_out_0_w_bits_last)
    `CHECK(auto_out_0_b_ready)
    `CHECK(auto_out_0_ar_valid)
    `CHECK(auto_out_0_ar_bits_id)
    `CHECK(auto_out_0_ar_bits_addr)
    `CHECK(auto_out_0_ar_bits_len)
    `CHECK(auto_out_0_ar_bits_size)
    `CHECK(auto_out_0_ar_bits_burst)
    `CHECK(auto_out_0_ar_bits_cache)
    `CHECK(auto_out_0_ar_bits_prot)
    `CHECK(auto_out_0_ar_bits_qos)
    `CHECK(auto_out_0_r_ready)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    auto_in_1_aw_valid = '0;
    auto_in_1_aw_bits_id = '0;
    auto_in_1_aw_bits_addr = '0;
    auto_in_1_aw_bits_len = '0;
    auto_in_1_aw_bits_size = '0;
    auto_in_1_aw_bits_burst = '0;
    auto_in_1_aw_bits_cache = '0;
    auto_in_1_aw_bits_qos = '0;
    auto_in_1_w_valid = '0;
    auto_in_1_w_bits_data = '0;
    auto_in_1_w_bits_strb = '0;
    auto_in_1_w_bits_last = '0;
    auto_in_1_ar_valid = '0;
    auto_in_1_ar_bits_id = '0;
    auto_in_1_ar_bits_addr = '0;
    auto_in_1_ar_bits_len = '0;
    auto_in_1_ar_bits_size = '0;
    auto_in_1_ar_bits_burst = '0;
    auto_in_1_ar_bits_cache = '0;
    auto_in_1_ar_bits_qos = '0;
    auto_in_0_aw_valid = '0;
    auto_in_0_aw_bits_id = '0;
    auto_in_0_aw_bits_addr = '0;
    auto_in_0_aw_bits_len = '0;
    auto_in_0_aw_bits_size = '0;
    auto_in_0_aw_bits_burst = '0;
    auto_in_0_aw_bits_qos = '0;
    auto_in_0_w_valid = '0;
    auto_in_0_w_bits_data = '0;
    auto_in_0_w_bits_strb = '0;
    auto_in_0_w_bits_last = '0;
    auto_in_0_ar_valid = '0;
    auto_in_0_ar_bits_id = '0;
    auto_in_0_ar_bits_addr = '0;
    auto_in_0_ar_bits_len = '0;
    auto_in_0_ar_bits_size = '0;
    auto_in_0_ar_bits_burst = '0;
    auto_in_0_ar_bits_qos = '0;
    auto_out_1_aw_ready = '0;
    auto_out_1_w_ready = '0;
    auto_out_1_b_valid = '0;
    auto_out_1_b_bits_id = '0;
    auto_out_1_ar_ready = '0;
    auto_out_1_r_valid = '0;
    auto_out_1_r_bits_id = '0;
    auto_out_1_r_bits_data = '0;
    auto_out_1_r_bits_last = '0;
    auto_out_0_aw_ready = '0;
    auto_out_0_w_ready = '0;
    auto_out_0_b_valid = '0;
    auto_out_0_b_bits_id = '0;
    auto_out_0_ar_ready = '0;
    auto_out_0_r_valid = '0;
    auto_out_0_r_bits_id = '0;
    auto_out_0_r_bits_data = '0;
    auto_out_0_r_bits_last = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("AXI4Xbar checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
