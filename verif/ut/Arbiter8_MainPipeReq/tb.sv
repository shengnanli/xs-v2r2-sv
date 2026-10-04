// 自动生成：verif/ut/Arbiter8_MainPipeReq/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Arbiter8_MainPipeReq 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Arbiter8_MainPipeReq =================
  int unsigned a_mode = 0;
  logic [7:0] a_vmap;
  wire  a_g_io_in_0_ready, a_i_io_in_0_ready;
  logic a_s0_io_in_0_ready = '0, a_s1_io_in_0_ready = '0;
  logic a_io_in_0_valid;
  logic [1:0] a_io_in_0_bits_probe_param;
  logic a_io_in_0_bits_probe_need_data;
  logic [49:0] a_io_in_0_bits_vaddr;
  logic [47:0] a_io_in_0_bits_addr;
  logic [5:0] a_io_in_0_bits_id;
  wire  a_g_io_in_1_ready, a_i_io_in_1_ready;
  logic a_s0_io_in_1_ready = '0, a_s1_io_in_1_ready = '0;
  logic a_io_in_1_valid;
  logic [1:0] a_io_in_1_bits_probe_param;
  logic a_io_in_1_bits_probe_need_data;
  logic [49:0] a_io_in_1_bits_vaddr;
  logic [47:0] a_io_in_1_bits_addr;
  logic [5:0] a_io_in_1_bits_id;
  wire  a_g_io_in_2_ready, a_i_io_in_2_ready;
  logic a_s0_io_in_2_ready = '0, a_s1_io_in_2_ready = '0;
  logic a_io_in_2_valid;
  logic [1:0] a_io_in_2_bits_probe_param;
  logic a_io_in_2_bits_probe_need_data;
  logic [49:0] a_io_in_2_bits_vaddr;
  logic [47:0] a_io_in_2_bits_addr;
  logic [5:0] a_io_in_2_bits_id;
  wire  a_g_io_in_3_ready, a_i_io_in_3_ready;
  logic a_s0_io_in_3_ready = '0, a_s1_io_in_3_ready = '0;
  logic a_io_in_3_valid;
  logic [1:0] a_io_in_3_bits_probe_param;
  logic a_io_in_3_bits_probe_need_data;
  logic [49:0] a_io_in_3_bits_vaddr;
  logic [47:0] a_io_in_3_bits_addr;
  logic [5:0] a_io_in_3_bits_id;
  wire  a_g_io_in_4_ready, a_i_io_in_4_ready;
  logic a_s0_io_in_4_ready = '0, a_s1_io_in_4_ready = '0;
  logic a_io_in_4_valid;
  logic [1:0] a_io_in_4_bits_probe_param;
  logic a_io_in_4_bits_probe_need_data;
  logic [49:0] a_io_in_4_bits_vaddr;
  logic [47:0] a_io_in_4_bits_addr;
  logic [5:0] a_io_in_4_bits_id;
  wire  a_g_io_in_5_ready, a_i_io_in_5_ready;
  logic a_s0_io_in_5_ready = '0, a_s1_io_in_5_ready = '0;
  logic a_io_in_5_valid;
  logic [1:0] a_io_in_5_bits_probe_param;
  logic a_io_in_5_bits_probe_need_data;
  logic [49:0] a_io_in_5_bits_vaddr;
  logic [47:0] a_io_in_5_bits_addr;
  logic [5:0] a_io_in_5_bits_id;
  wire  a_g_io_in_6_ready, a_i_io_in_6_ready;
  logic a_s0_io_in_6_ready = '0, a_s1_io_in_6_ready = '0;
  logic a_io_in_6_valid;
  logic [1:0] a_io_in_6_bits_probe_param;
  logic a_io_in_6_bits_probe_need_data;
  logic [49:0] a_io_in_6_bits_vaddr;
  logic [47:0] a_io_in_6_bits_addr;
  logic [5:0] a_io_in_6_bits_id;
  wire  a_g_io_in_7_ready, a_i_io_in_7_ready;
  logic a_s0_io_in_7_ready = '0, a_s1_io_in_7_ready = '0;
  logic a_io_in_7_valid;
  logic [1:0] a_io_in_7_bits_probe_param;
  logic a_io_in_7_bits_probe_need_data;
  logic [49:0] a_io_in_7_bits_vaddr;
  logic [47:0] a_io_in_7_bits_addr;
  logic [5:0] a_io_in_7_bits_id;
  logic a_io_out_ready;
  wire  a_g_io_out_valid, a_i_io_out_valid;
  logic a_s0_io_out_valid = '0, a_s1_io_out_valid = '0;
  wire  [1:0] a_g_io_out_bits_probe_param, a_i_io_out_bits_probe_param;
  logic [1:0] a_s0_io_out_bits_probe_param = '0, a_s1_io_out_bits_probe_param = '0;
  wire  a_g_io_out_bits_probe_need_data, a_i_io_out_bits_probe_need_data;
  logic a_s0_io_out_bits_probe_need_data = '0, a_s1_io_out_bits_probe_need_data = '0;
  wire  [49:0] a_g_io_out_bits_vaddr, a_i_io_out_bits_vaddr;
  logic [49:0] a_s0_io_out_bits_vaddr = '0, a_s1_io_out_bits_vaddr = '0;
  wire  [47:0] a_g_io_out_bits_addr, a_i_io_out_bits_addr;
  logic [47:0] a_s0_io_out_bits_addr = '0, a_s1_io_out_bits_addr = '0;
  wire  [5:0] a_g_io_out_bits_id, a_i_io_out_bits_id;
  logic [5:0] a_s0_io_out_bits_id = '0, a_s1_io_out_bits_id = '0;
  int a_cov_none = 0;
  int a_cov_stall = 0;
  int a_cov_win0 = 0;
  int a_cov_win1 = 0;
  int a_cov_win2 = 0;
  int a_cov_win3 = 0;
  int a_cov_win4 = 0;
  int a_cov_win5 = 0;
  int a_cov_win6 = 0;
  int a_cov_win7 = 0;
  logic [0:0] a_armed = '0;
  int a_armed_at = -1;
  Arbiter8_MainPipeReq a_u_gold (
    .io_in_0_ready(a_g_io_in_0_ready),
    .io_in_0_valid(a_io_in_0_valid),
    .io_in_0_bits_probe_param(a_io_in_0_bits_probe_param),
    .io_in_0_bits_probe_need_data(a_io_in_0_bits_probe_need_data),
    .io_in_0_bits_vaddr(a_io_in_0_bits_vaddr),
    .io_in_0_bits_addr(a_io_in_0_bits_addr),
    .io_in_0_bits_id(a_io_in_0_bits_id),
    .io_in_1_ready(a_g_io_in_1_ready),
    .io_in_1_valid(a_io_in_1_valid),
    .io_in_1_bits_probe_param(a_io_in_1_bits_probe_param),
    .io_in_1_bits_probe_need_data(a_io_in_1_bits_probe_need_data),
    .io_in_1_bits_vaddr(a_io_in_1_bits_vaddr),
    .io_in_1_bits_addr(a_io_in_1_bits_addr),
    .io_in_1_bits_id(a_io_in_1_bits_id),
    .io_in_2_ready(a_g_io_in_2_ready),
    .io_in_2_valid(a_io_in_2_valid),
    .io_in_2_bits_probe_param(a_io_in_2_bits_probe_param),
    .io_in_2_bits_probe_need_data(a_io_in_2_bits_probe_need_data),
    .io_in_2_bits_vaddr(a_io_in_2_bits_vaddr),
    .io_in_2_bits_addr(a_io_in_2_bits_addr),
    .io_in_2_bits_id(a_io_in_2_bits_id),
    .io_in_3_ready(a_g_io_in_3_ready),
    .io_in_3_valid(a_io_in_3_valid),
    .io_in_3_bits_probe_param(a_io_in_3_bits_probe_param),
    .io_in_3_bits_probe_need_data(a_io_in_3_bits_probe_need_data),
    .io_in_3_bits_vaddr(a_io_in_3_bits_vaddr),
    .io_in_3_bits_addr(a_io_in_3_bits_addr),
    .io_in_3_bits_id(a_io_in_3_bits_id),
    .io_in_4_ready(a_g_io_in_4_ready),
    .io_in_4_valid(a_io_in_4_valid),
    .io_in_4_bits_probe_param(a_io_in_4_bits_probe_param),
    .io_in_4_bits_probe_need_data(a_io_in_4_bits_probe_need_data),
    .io_in_4_bits_vaddr(a_io_in_4_bits_vaddr),
    .io_in_4_bits_addr(a_io_in_4_bits_addr),
    .io_in_4_bits_id(a_io_in_4_bits_id),
    .io_in_5_ready(a_g_io_in_5_ready),
    .io_in_5_valid(a_io_in_5_valid),
    .io_in_5_bits_probe_param(a_io_in_5_bits_probe_param),
    .io_in_5_bits_probe_need_data(a_io_in_5_bits_probe_need_data),
    .io_in_5_bits_vaddr(a_io_in_5_bits_vaddr),
    .io_in_5_bits_addr(a_io_in_5_bits_addr),
    .io_in_5_bits_id(a_io_in_5_bits_id),
    .io_in_6_ready(a_g_io_in_6_ready),
    .io_in_6_valid(a_io_in_6_valid),
    .io_in_6_bits_probe_param(a_io_in_6_bits_probe_param),
    .io_in_6_bits_probe_need_data(a_io_in_6_bits_probe_need_data),
    .io_in_6_bits_vaddr(a_io_in_6_bits_vaddr),
    .io_in_6_bits_addr(a_io_in_6_bits_addr),
    .io_in_6_bits_id(a_io_in_6_bits_id),
    .io_in_7_ready(a_g_io_in_7_ready),
    .io_in_7_valid(a_io_in_7_valid),
    .io_in_7_bits_probe_param(a_io_in_7_bits_probe_param),
    .io_in_7_bits_probe_need_data(a_io_in_7_bits_probe_need_data),
    .io_in_7_bits_vaddr(a_io_in_7_bits_vaddr),
    .io_in_7_bits_addr(a_io_in_7_bits_addr),
    .io_in_7_bits_id(a_io_in_7_bits_id),
    .io_out_ready(a_io_out_ready),
    .io_out_valid(a_g_io_out_valid),
    .io_out_bits_probe_param(a_g_io_out_bits_probe_param),
    .io_out_bits_probe_need_data(a_g_io_out_bits_probe_need_data),
    .io_out_bits_vaddr(a_g_io_out_bits_vaddr),
    .io_out_bits_addr(a_g_io_out_bits_addr),
    .io_out_bits_id(a_g_io_out_bits_id)
  );
  Arbiter8_MainPipeReq_xs a_u_impl (
    .io_in_0_ready(a_i_io_in_0_ready),
    .io_in_0_valid(a_io_in_0_valid),
    .io_in_0_bits_probe_param(a_io_in_0_bits_probe_param),
    .io_in_0_bits_probe_need_data(a_io_in_0_bits_probe_need_data),
    .io_in_0_bits_vaddr(a_io_in_0_bits_vaddr),
    .io_in_0_bits_addr(a_io_in_0_bits_addr),
    .io_in_0_bits_id(a_io_in_0_bits_id),
    .io_in_1_ready(a_i_io_in_1_ready),
    .io_in_1_valid(a_io_in_1_valid),
    .io_in_1_bits_probe_param(a_io_in_1_bits_probe_param),
    .io_in_1_bits_probe_need_data(a_io_in_1_bits_probe_need_data),
    .io_in_1_bits_vaddr(a_io_in_1_bits_vaddr),
    .io_in_1_bits_addr(a_io_in_1_bits_addr),
    .io_in_1_bits_id(a_io_in_1_bits_id),
    .io_in_2_ready(a_i_io_in_2_ready),
    .io_in_2_valid(a_io_in_2_valid),
    .io_in_2_bits_probe_param(a_io_in_2_bits_probe_param),
    .io_in_2_bits_probe_need_data(a_io_in_2_bits_probe_need_data),
    .io_in_2_bits_vaddr(a_io_in_2_bits_vaddr),
    .io_in_2_bits_addr(a_io_in_2_bits_addr),
    .io_in_2_bits_id(a_io_in_2_bits_id),
    .io_in_3_ready(a_i_io_in_3_ready),
    .io_in_3_valid(a_io_in_3_valid),
    .io_in_3_bits_probe_param(a_io_in_3_bits_probe_param),
    .io_in_3_bits_probe_need_data(a_io_in_3_bits_probe_need_data),
    .io_in_3_bits_vaddr(a_io_in_3_bits_vaddr),
    .io_in_3_bits_addr(a_io_in_3_bits_addr),
    .io_in_3_bits_id(a_io_in_3_bits_id),
    .io_in_4_ready(a_i_io_in_4_ready),
    .io_in_4_valid(a_io_in_4_valid),
    .io_in_4_bits_probe_param(a_io_in_4_bits_probe_param),
    .io_in_4_bits_probe_need_data(a_io_in_4_bits_probe_need_data),
    .io_in_4_bits_vaddr(a_io_in_4_bits_vaddr),
    .io_in_4_bits_addr(a_io_in_4_bits_addr),
    .io_in_4_bits_id(a_io_in_4_bits_id),
    .io_in_5_ready(a_i_io_in_5_ready),
    .io_in_5_valid(a_io_in_5_valid),
    .io_in_5_bits_probe_param(a_io_in_5_bits_probe_param),
    .io_in_5_bits_probe_need_data(a_io_in_5_bits_probe_need_data),
    .io_in_5_bits_vaddr(a_io_in_5_bits_vaddr),
    .io_in_5_bits_addr(a_io_in_5_bits_addr),
    .io_in_5_bits_id(a_io_in_5_bits_id),
    .io_in_6_ready(a_i_io_in_6_ready),
    .io_in_6_valid(a_io_in_6_valid),
    .io_in_6_bits_probe_param(a_io_in_6_bits_probe_param),
    .io_in_6_bits_probe_need_data(a_io_in_6_bits_probe_need_data),
    .io_in_6_bits_vaddr(a_io_in_6_bits_vaddr),
    .io_in_6_bits_addr(a_io_in_6_bits_addr),
    .io_in_6_bits_id(a_io_in_6_bits_id),
    .io_in_7_ready(a_i_io_in_7_ready),
    .io_in_7_valid(a_io_in_7_valid),
    .io_in_7_bits_probe_param(a_io_in_7_bits_probe_param),
    .io_in_7_bits_probe_need_data(a_io_in_7_bits_probe_need_data),
    .io_in_7_bits_vaddr(a_io_in_7_bits_vaddr),
    .io_in_7_bits_addr(a_io_in_7_bits_addr),
    .io_in_7_bits_id(a_io_in_7_bits_id),
    .io_out_ready(a_io_out_ready),
    .io_out_valid(a_i_io_out_valid),
    .io_out_bits_probe_param(a_i_io_out_bits_probe_param),
    .io_out_bits_probe_need_data(a_i_io_out_bits_probe_need_data),
    .io_out_bits_vaddr(a_i_io_out_bits_vaddr),
    .io_out_bits_addr(a_i_io_out_bits_addr),
    .io_out_bits_id(a_i_io_out_bits_id)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) a_mode = $urandom_range(0, 15);
      a_io_in_0_valid = 1'($urandom);
      a_io_in_0_bits_probe_param = 2'($urandom);
      a_io_in_0_bits_probe_need_data = 1'($urandom);
      a_io_in_0_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_0_bits_addr = 48'({$urandom, $urandom});
      a_io_in_0_bits_id = 6'($urandom);
      a_io_in_1_valid = 1'($urandom);
      a_io_in_1_bits_probe_param = 2'($urandom);
      a_io_in_1_bits_probe_need_data = 1'($urandom);
      a_io_in_1_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_1_bits_addr = 48'({$urandom, $urandom});
      a_io_in_1_bits_id = 6'($urandom);
      a_io_in_2_valid = 1'($urandom);
      a_io_in_2_bits_probe_param = 2'($urandom);
      a_io_in_2_bits_probe_need_data = 1'($urandom);
      a_io_in_2_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_2_bits_addr = 48'({$urandom, $urandom});
      a_io_in_2_bits_id = 6'($urandom);
      a_io_in_3_valid = 1'($urandom);
      a_io_in_3_bits_probe_param = 2'($urandom);
      a_io_in_3_bits_probe_need_data = 1'($urandom);
      a_io_in_3_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_3_bits_addr = 48'({$urandom, $urandom});
      a_io_in_3_bits_id = 6'($urandom);
      a_io_in_4_valid = 1'($urandom);
      a_io_in_4_bits_probe_param = 2'($urandom);
      a_io_in_4_bits_probe_need_data = 1'($urandom);
      a_io_in_4_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_4_bits_addr = 48'({$urandom, $urandom});
      a_io_in_4_bits_id = 6'($urandom);
      a_io_in_5_valid = 1'($urandom);
      a_io_in_5_bits_probe_param = 2'($urandom);
      a_io_in_5_bits_probe_need_data = 1'($urandom);
      a_io_in_5_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_5_bits_addr = 48'({$urandom, $urandom});
      a_io_in_5_bits_id = 6'($urandom);
      a_io_in_6_valid = 1'($urandom);
      a_io_in_6_bits_probe_param = 2'($urandom);
      a_io_in_6_bits_probe_need_data = 1'($urandom);
      a_io_in_6_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_6_bits_addr = 48'({$urandom, $urandom});
      a_io_in_6_bits_id = 6'($urandom);
      a_io_in_7_valid = 1'($urandom);
      a_io_in_7_bits_probe_param = 2'($urandom);
      a_io_in_7_bits_probe_need_data = 1'($urandom);
      a_io_in_7_bits_vaddr = 50'({$urandom, $urandom});
      a_io_in_7_bits_addr = 48'({$urandom, $urandom});
      a_io_in_7_bits_id = 6'($urandom);
      a_io_out_ready = 1'($urandom);
      begin : stim_a
        case (cyc % 4)
          0: a_vmap = 8'h00;
          1: a_vmap = 8'h01 << $urandom_range(0, 7);
          2: a_vmap = 8'($urandom) & 8'($urandom) & 8'($urandom);
          default: a_vmap = 8'($urandom);
        endcase
        {a_io_in_7_valid, a_io_in_6_valid, a_io_in_5_valid, a_io_in_4_valid,
         a_io_in_3_valid, a_io_in_2_valid, a_io_in_1_valid, a_io_in_0_valid} = a_vmap;
      end
      #4;
      a_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&a_armed)) begin
        checks++;
        if (a_g_io_in_0_ready !== a_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_0_ready g=%h i=%h", cyc, a_g_io_in_0_ready, a_i_io_in_0_ready);
        end
        a_s1_io_in_0_ready |= a_g_io_in_0_ready;
        a_s0_io_in_0_ready |= ~a_g_io_in_0_ready;
        checks++;
        if (a_g_io_in_1_ready !== a_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_1_ready g=%h i=%h", cyc, a_g_io_in_1_ready, a_i_io_in_1_ready);
        end
        a_s1_io_in_1_ready |= a_g_io_in_1_ready;
        a_s0_io_in_1_ready |= ~a_g_io_in_1_ready;
        checks++;
        if (a_g_io_in_2_ready !== a_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_2_ready g=%h i=%h", cyc, a_g_io_in_2_ready, a_i_io_in_2_ready);
        end
        a_s1_io_in_2_ready |= a_g_io_in_2_ready;
        a_s0_io_in_2_ready |= ~a_g_io_in_2_ready;
        checks++;
        if (a_g_io_in_3_ready !== a_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_3_ready g=%h i=%h", cyc, a_g_io_in_3_ready, a_i_io_in_3_ready);
        end
        a_s1_io_in_3_ready |= a_g_io_in_3_ready;
        a_s0_io_in_3_ready |= ~a_g_io_in_3_ready;
        checks++;
        if (a_g_io_in_4_ready !== a_i_io_in_4_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_4_ready g=%h i=%h", cyc, a_g_io_in_4_ready, a_i_io_in_4_ready);
        end
        a_s1_io_in_4_ready |= a_g_io_in_4_ready;
        a_s0_io_in_4_ready |= ~a_g_io_in_4_ready;
        checks++;
        if (a_g_io_in_5_ready !== a_i_io_in_5_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_5_ready g=%h i=%h", cyc, a_g_io_in_5_ready, a_i_io_in_5_ready);
        end
        a_s1_io_in_5_ready |= a_g_io_in_5_ready;
        a_s0_io_in_5_ready |= ~a_g_io_in_5_ready;
        checks++;
        if (a_g_io_in_6_ready !== a_i_io_in_6_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_6_ready g=%h i=%h", cyc, a_g_io_in_6_ready, a_i_io_in_6_ready);
        end
        a_s1_io_in_6_ready |= a_g_io_in_6_ready;
        a_s0_io_in_6_ready |= ~a_g_io_in_6_ready;
        checks++;
        if (a_g_io_in_7_ready !== a_i_io_in_7_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_in_7_ready g=%h i=%h", cyc, a_g_io_in_7_ready, a_i_io_in_7_ready);
        end
        a_s1_io_in_7_ready |= a_g_io_in_7_ready;
        a_s0_io_in_7_ready |= ~a_g_io_in_7_ready;
        checks++;
        if (a_g_io_out_valid !== a_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_valid g=%h i=%h", cyc, a_g_io_out_valid, a_i_io_out_valid);
        end
        a_s1_io_out_valid |= a_g_io_out_valid;
        a_s0_io_out_valid |= ~a_g_io_out_valid;
        checks++;
        if (a_g_io_out_bits_probe_param !== a_i_io_out_bits_probe_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_bits_probe_param g=%h i=%h", cyc, a_g_io_out_bits_probe_param, a_i_io_out_bits_probe_param);
        end
        a_s1_io_out_bits_probe_param |= a_g_io_out_bits_probe_param;
        a_s0_io_out_bits_probe_param |= ~a_g_io_out_bits_probe_param;
        checks++;
        if (a_g_io_out_bits_probe_need_data !== a_i_io_out_bits_probe_need_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_bits_probe_need_data g=%h i=%h", cyc, a_g_io_out_bits_probe_need_data, a_i_io_out_bits_probe_need_data);
        end
        a_s1_io_out_bits_probe_need_data |= a_g_io_out_bits_probe_need_data;
        a_s0_io_out_bits_probe_need_data |= ~a_g_io_out_bits_probe_need_data;
        checks++;
        if (a_g_io_out_bits_vaddr !== a_i_io_out_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_bits_vaddr g=%h i=%h", cyc, a_g_io_out_bits_vaddr, a_i_io_out_bits_vaddr);
        end
        a_s1_io_out_bits_vaddr |= a_g_io_out_bits_vaddr;
        a_s0_io_out_bits_vaddr |= ~a_g_io_out_bits_vaddr;
        checks++;
        if (a_g_io_out_bits_addr !== a_i_io_out_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_bits_addr g=%h i=%h", cyc, a_g_io_out_bits_addr, a_i_io_out_bits_addr);
        end
        a_s1_io_out_bits_addr |= a_g_io_out_bits_addr;
        a_s0_io_out_bits_addr |= ~a_g_io_out_bits_addr;
        checks++;
        if (a_g_io_out_bits_id !== a_i_io_out_bits_id) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Arbiter8_MainPipeReq.io_out_bits_id g=%h i=%h", cyc, a_g_io_out_bits_id, a_i_io_out_bits_id);
        end
        a_s1_io_out_bits_id |= a_g_io_out_bits_id;
        a_s0_io_out_bits_id |= ~a_g_io_out_bits_id;
        if (!a_g_io_out_valid) a_cov_none++;
        if (a_g_io_out_valid && !a_io_out_ready) a_cov_stall++;
        if (a_io_in_0_valid && 1) a_cov_win0++;
        if (a_io_in_1_valid && !a_io_in_0_valid) a_cov_win1++;
        if (a_io_in_2_valid && !a_io_in_0_valid && !a_io_in_1_valid) a_cov_win2++;
        if (a_io_in_3_valid && !a_io_in_0_valid && !a_io_in_1_valid && !a_io_in_2_valid) a_cov_win3++;
        if (a_io_in_4_valid && !a_io_in_0_valid && !a_io_in_1_valid && !a_io_in_2_valid && !a_io_in_3_valid) a_cov_win4++;
        if (a_io_in_5_valid && !a_io_in_0_valid && !a_io_in_1_valid && !a_io_in_2_valid && !a_io_in_3_valid && !a_io_in_4_valid) a_cov_win5++;
        if (a_io_in_6_valid && !a_io_in_0_valid && !a_io_in_1_valid && !a_io_in_2_valid && !a_io_in_3_valid && !a_io_in_4_valid && !a_io_in_5_valid) a_cov_win6++;
        if (a_io_in_7_valid && !a_io_in_0_valid && !a_io_in_1_valid && !a_io_in_2_valid && !a_io_in_3_valid && !a_io_in_4_valid && !a_io_in_5_valid && !a_io_in_6_valid) a_cov_win7++;
      end
      if (a_armed_at < 0 && (&a_armed)) a_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(a_s0_io_in_0_ready && a_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_0_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_1_ready && a_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_1_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_2_ready && a_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_2_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_3_ready && a_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_3_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_4_ready && a_s1_io_in_4_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_4_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_5_ready && a_s1_io_in_5_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_5_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_6_ready && a_s1_io_in_6_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_6_ready 未见过 0 和 1"); end
    if (!(a_s0_io_in_7_ready && a_s1_io_in_7_ready)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_in_7_ready 未见过 0 和 1"); end
    if (!(a_s0_io_out_valid && a_s1_io_out_valid)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_valid 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_probe_param[0] && a_s1_io_out_bits_probe_param[0])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_probe_param[0] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_probe_param[1] && a_s1_io_out_bits_probe_param[1])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_probe_param[1] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_probe_need_data && a_s1_io_out_bits_probe_need_data)) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_probe_need_data 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[0] && a_s1_io_out_bits_vaddr[0])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[1] && a_s1_io_out_bits_vaddr[1])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[2] && a_s1_io_out_bits_vaddr[2])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[3] && a_s1_io_out_bits_vaddr[3])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[4] && a_s1_io_out_bits_vaddr[4])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[5] && a_s1_io_out_bits_vaddr[5])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[6] && a_s1_io_out_bits_vaddr[6])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[7] && a_s1_io_out_bits_vaddr[7])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[8] && a_s1_io_out_bits_vaddr[8])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[9] && a_s1_io_out_bits_vaddr[9])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[10] && a_s1_io_out_bits_vaddr[10])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[11] && a_s1_io_out_bits_vaddr[11])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[12] && a_s1_io_out_bits_vaddr[12])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[13] && a_s1_io_out_bits_vaddr[13])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[14] && a_s1_io_out_bits_vaddr[14])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[15] && a_s1_io_out_bits_vaddr[15])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[16] && a_s1_io_out_bits_vaddr[16])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[17] && a_s1_io_out_bits_vaddr[17])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[18] && a_s1_io_out_bits_vaddr[18])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[19] && a_s1_io_out_bits_vaddr[19])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[20] && a_s1_io_out_bits_vaddr[20])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[21] && a_s1_io_out_bits_vaddr[21])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[22] && a_s1_io_out_bits_vaddr[22])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[23] && a_s1_io_out_bits_vaddr[23])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[24] && a_s1_io_out_bits_vaddr[24])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[25] && a_s1_io_out_bits_vaddr[25])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[26] && a_s1_io_out_bits_vaddr[26])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[27] && a_s1_io_out_bits_vaddr[27])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[28] && a_s1_io_out_bits_vaddr[28])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[29] && a_s1_io_out_bits_vaddr[29])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[30] && a_s1_io_out_bits_vaddr[30])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[31] && a_s1_io_out_bits_vaddr[31])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[32] && a_s1_io_out_bits_vaddr[32])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[33] && a_s1_io_out_bits_vaddr[33])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[34] && a_s1_io_out_bits_vaddr[34])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[35] && a_s1_io_out_bits_vaddr[35])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[36] && a_s1_io_out_bits_vaddr[36])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[37] && a_s1_io_out_bits_vaddr[37])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[38] && a_s1_io_out_bits_vaddr[38])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[39] && a_s1_io_out_bits_vaddr[39])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[40] && a_s1_io_out_bits_vaddr[40])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[41] && a_s1_io_out_bits_vaddr[41])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[42] && a_s1_io_out_bits_vaddr[42])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[43] && a_s1_io_out_bits_vaddr[43])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[44] && a_s1_io_out_bits_vaddr[44])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[45] && a_s1_io_out_bits_vaddr[45])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[46] && a_s1_io_out_bits_vaddr[46])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[47] && a_s1_io_out_bits_vaddr[47])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[48] && a_s1_io_out_bits_vaddr[48])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_vaddr[49] && a_s1_io_out_bits_vaddr[49])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[0] && a_s1_io_out_bits_addr[0])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[0] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[1] && a_s1_io_out_bits_addr[1])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[1] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[2] && a_s1_io_out_bits_addr[2])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[2] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[3] && a_s1_io_out_bits_addr[3])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[3] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[4] && a_s1_io_out_bits_addr[4])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[4] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[5] && a_s1_io_out_bits_addr[5])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[5] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[6] && a_s1_io_out_bits_addr[6])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[6] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[7] && a_s1_io_out_bits_addr[7])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[7] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[8] && a_s1_io_out_bits_addr[8])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[8] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[9] && a_s1_io_out_bits_addr[9])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[9] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[10] && a_s1_io_out_bits_addr[10])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[10] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[11] && a_s1_io_out_bits_addr[11])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[11] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[12] && a_s1_io_out_bits_addr[12])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[12] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[13] && a_s1_io_out_bits_addr[13])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[13] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[14] && a_s1_io_out_bits_addr[14])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[14] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[15] && a_s1_io_out_bits_addr[15])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[15] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[16] && a_s1_io_out_bits_addr[16])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[16] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[17] && a_s1_io_out_bits_addr[17])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[17] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[18] && a_s1_io_out_bits_addr[18])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[18] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[19] && a_s1_io_out_bits_addr[19])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[19] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[20] && a_s1_io_out_bits_addr[20])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[20] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[21] && a_s1_io_out_bits_addr[21])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[21] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[22] && a_s1_io_out_bits_addr[22])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[22] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[23] && a_s1_io_out_bits_addr[23])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[23] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[24] && a_s1_io_out_bits_addr[24])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[24] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[25] && a_s1_io_out_bits_addr[25])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[25] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[26] && a_s1_io_out_bits_addr[26])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[26] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[27] && a_s1_io_out_bits_addr[27])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[27] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[28] && a_s1_io_out_bits_addr[28])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[28] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[29] && a_s1_io_out_bits_addr[29])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[29] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[30] && a_s1_io_out_bits_addr[30])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[30] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[31] && a_s1_io_out_bits_addr[31])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[31] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[32] && a_s1_io_out_bits_addr[32])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[32] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[33] && a_s1_io_out_bits_addr[33])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[33] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[34] && a_s1_io_out_bits_addr[34])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[34] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[35] && a_s1_io_out_bits_addr[35])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[35] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[36] && a_s1_io_out_bits_addr[36])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[36] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[37] && a_s1_io_out_bits_addr[37])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[37] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[38] && a_s1_io_out_bits_addr[38])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[38] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[39] && a_s1_io_out_bits_addr[39])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[39] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[40] && a_s1_io_out_bits_addr[40])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[40] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[41] && a_s1_io_out_bits_addr[41])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[41] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[42] && a_s1_io_out_bits_addr[42])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[42] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[43] && a_s1_io_out_bits_addr[43])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[43] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[44] && a_s1_io_out_bits_addr[44])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[44] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[45] && a_s1_io_out_bits_addr[45])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[45] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[46] && a_s1_io_out_bits_addr[46])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[46] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_addr[47] && a_s1_io_out_bits_addr[47])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_addr[47] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[0] && a_s1_io_out_bits_id[0])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[0] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[1] && a_s1_io_out_bits_id[1])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[1] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[2] && a_s1_io_out_bits_id[2])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[2] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[3] && a_s1_io_out_bits_id[3])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[3] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[4] && a_s1_io_out_bits_id[4])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[4] 未见过 0 和 1"); end
    if (!(a_s0_io_out_bits_id[5] && a_s1_io_out_bits_id[5])) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.io_out_bits_id[5] 未见过 0 和 1"); end
    $display("[ARM] Arbiter8_MainPipeReq armed_at=%0d", a_armed_at);
    if (a_armed_at < 0) begin cov_fail++; $display("[ARM] Arbiter8_MainPipeReq 从未 arm"); end
    $display("[COV] Arbiter8_MainPipeReq.none = %0d", a_cov_none);
    if (a_cov_none < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.none < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.stall = %0d", a_cov_stall);
    if (a_cov_stall < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.stall < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win0 = %0d", a_cov_win0);
    if (a_cov_win0 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win0 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win1 = %0d", a_cov_win1);
    if (a_cov_win1 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win1 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win2 = %0d", a_cov_win2);
    if (a_cov_win2 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win2 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win3 = %0d", a_cov_win3);
    if (a_cov_win3 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win3 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win4 = %0d", a_cov_win4);
    if (a_cov_win4 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win4 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win5 = %0d", a_cov_win5);
    if (a_cov_win5 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win5 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win6 = %0d", a_cov_win6);
    if (a_cov_win6 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win6 < 200"); end
    $display("[COV] Arbiter8_MainPipeReq.win7 = %0d", a_cov_win7);
    if (a_cov_win7 < 200) begin cov_fail++; $display("[COV] Arbiter8_MainPipeReq.win7 < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
