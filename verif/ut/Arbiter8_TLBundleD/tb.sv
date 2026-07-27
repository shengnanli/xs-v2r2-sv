// 自动生成: scripts/gen_arbiter8.py —— 勿手改
// Arbiter8_TLBundleD 双例化逐拍比对: golden Arbiter8_TLBundleD vs 可读 Arbiter8_TLBundleD_xs (随机激励).
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
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
  logic io_in_0_valid;
  logic [3:0] io_in_0_bits_opcode;
  logic [1:0] io_in_0_bits_size;
  logic [2:0] io_in_0_bits_source;
  logic io_in_0_bits_denied;
  logic [63:0] io_in_0_bits_data;
  logic io_in_0_bits_corrupt;
  logic io_in_1_valid;
  logic [3:0] io_in_1_bits_opcode;
  logic [1:0] io_in_1_bits_size;
  logic [2:0] io_in_1_bits_source;
  logic io_in_1_bits_denied;
  logic [63:0] io_in_1_bits_data;
  logic io_in_1_bits_corrupt;
  logic io_in_2_valid;
  logic [3:0] io_in_2_bits_opcode;
  logic [1:0] io_in_2_bits_size;
  logic [2:0] io_in_2_bits_source;
  logic io_in_2_bits_denied;
  logic [63:0] io_in_2_bits_data;
  logic io_in_2_bits_corrupt;
  logic io_in_3_valid;
  logic [3:0] io_in_3_bits_opcode;
  logic [1:0] io_in_3_bits_size;
  logic [2:0] io_in_3_bits_source;
  logic io_in_3_bits_denied;
  logic [63:0] io_in_3_bits_data;
  logic io_in_3_bits_corrupt;
  logic io_in_4_valid;
  logic [3:0] io_in_4_bits_opcode;
  logic [1:0] io_in_4_bits_size;
  logic [2:0] io_in_4_bits_source;
  logic io_in_4_bits_denied;
  logic [63:0] io_in_4_bits_data;
  logic io_in_4_bits_corrupt;
  logic io_in_5_valid;
  logic [3:0] io_in_5_bits_opcode;
  logic [1:0] io_in_5_bits_size;
  logic [2:0] io_in_5_bits_source;
  logic io_in_5_bits_denied;
  logic [63:0] io_in_5_bits_data;
  logic io_in_5_bits_corrupt;
  logic io_in_6_valid;
  logic [3:0] io_in_6_bits_opcode;
  logic [1:0] io_in_6_bits_size;
  logic [2:0] io_in_6_bits_source;
  logic io_in_6_bits_denied;
  logic [63:0] io_in_6_bits_data;
  logic io_in_6_bits_corrupt;
  logic io_in_7_valid;
  logic [3:0] io_in_7_bits_opcode;
  logic [1:0] io_in_7_bits_size;
  logic [2:0] io_in_7_bits_source;
  logic io_in_7_bits_denied;
  logic [63:0] io_in_7_bits_data;
  logic io_in_7_bits_corrupt;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_in_4_ready;
  wire i_io_in_4_ready;
  wire g_io_in_5_ready;
  wire i_io_in_5_ready;
  wire g_io_in_6_ready;
  wire i_io_in_6_ready;
  wire g_io_in_7_ready;
  wire i_io_in_7_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [3:0] g_io_out_bits_opcode;
  wire [3:0] i_io_out_bits_opcode;
  wire [1:0] g_io_out_bits_size;
  wire [1:0] i_io_out_bits_size;
  wire [2:0] g_io_out_bits_source;
  wire [2:0] i_io_out_bits_source;
  wire g_io_out_bits_denied;
  wire i_io_out_bits_denied;
  wire [63:0] g_io_out_bits_data;
  wire [63:0] i_io_out_bits_data;
  wire g_io_out_bits_corrupt;
  wire i_io_out_bits_corrupt;
  Arbiter8_TLBundleD u_g (
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_source(io_in_0_bits_source),
    .io_in_0_bits_denied(io_in_0_bits_denied),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_corrupt(io_in_0_bits_corrupt),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_source(io_in_1_bits_source),
    .io_in_1_bits_denied(io_in_1_bits_denied),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_corrupt(io_in_1_bits_corrupt),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_source(io_in_2_bits_source),
    .io_in_2_bits_denied(io_in_2_bits_denied),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_corrupt(io_in_2_bits_corrupt),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_source(io_in_3_bits_source),
    .io_in_3_bits_denied(io_in_3_bits_denied),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_corrupt(io_in_3_bits_corrupt),
    .io_in_4_ready(g_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_source(io_in_4_bits_source),
    .io_in_4_bits_denied(io_in_4_bits_denied),
    .io_in_4_bits_data(io_in_4_bits_data),
    .io_in_4_bits_corrupt(io_in_4_bits_corrupt),
    .io_in_5_ready(g_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_source(io_in_5_bits_source),
    .io_in_5_bits_denied(io_in_5_bits_denied),
    .io_in_5_bits_data(io_in_5_bits_data),
    .io_in_5_bits_corrupt(io_in_5_bits_corrupt),
    .io_in_6_ready(g_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_source(io_in_6_bits_source),
    .io_in_6_bits_denied(io_in_6_bits_denied),
    .io_in_6_bits_data(io_in_6_bits_data),
    .io_in_6_bits_corrupt(io_in_6_bits_corrupt),
    .io_in_7_ready(g_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_source(io_in_7_bits_source),
    .io_in_7_bits_denied(io_in_7_bits_denied),
    .io_in_7_bits_data(io_in_7_bits_data),
    .io_in_7_bits_corrupt(io_in_7_bits_corrupt),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_opcode(g_io_out_bits_opcode),
    .io_out_bits_size(g_io_out_bits_size),
    .io_out_bits_source(g_io_out_bits_source),
    .io_out_bits_denied(g_io_out_bits_denied),
    .io_out_bits_data(g_io_out_bits_data),
    .io_out_bits_corrupt(g_io_out_bits_corrupt)
  );
  Arbiter8_TLBundleD_xs u_i (
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_opcode(io_in_0_bits_opcode),
    .io_in_0_bits_size(io_in_0_bits_size),
    .io_in_0_bits_source(io_in_0_bits_source),
    .io_in_0_bits_denied(io_in_0_bits_denied),
    .io_in_0_bits_data(io_in_0_bits_data),
    .io_in_0_bits_corrupt(io_in_0_bits_corrupt),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_opcode(io_in_1_bits_opcode),
    .io_in_1_bits_size(io_in_1_bits_size),
    .io_in_1_bits_source(io_in_1_bits_source),
    .io_in_1_bits_denied(io_in_1_bits_denied),
    .io_in_1_bits_data(io_in_1_bits_data),
    .io_in_1_bits_corrupt(io_in_1_bits_corrupt),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_opcode(io_in_2_bits_opcode),
    .io_in_2_bits_size(io_in_2_bits_size),
    .io_in_2_bits_source(io_in_2_bits_source),
    .io_in_2_bits_denied(io_in_2_bits_denied),
    .io_in_2_bits_data(io_in_2_bits_data),
    .io_in_2_bits_corrupt(io_in_2_bits_corrupt),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_opcode(io_in_3_bits_opcode),
    .io_in_3_bits_size(io_in_3_bits_size),
    .io_in_3_bits_source(io_in_3_bits_source),
    .io_in_3_bits_denied(io_in_3_bits_denied),
    .io_in_3_bits_data(io_in_3_bits_data),
    .io_in_3_bits_corrupt(io_in_3_bits_corrupt),
    .io_in_4_ready(i_io_in_4_ready),
    .io_in_4_valid(io_in_4_valid),
    .io_in_4_bits_opcode(io_in_4_bits_opcode),
    .io_in_4_bits_size(io_in_4_bits_size),
    .io_in_4_bits_source(io_in_4_bits_source),
    .io_in_4_bits_denied(io_in_4_bits_denied),
    .io_in_4_bits_data(io_in_4_bits_data),
    .io_in_4_bits_corrupt(io_in_4_bits_corrupt),
    .io_in_5_ready(i_io_in_5_ready),
    .io_in_5_valid(io_in_5_valid),
    .io_in_5_bits_opcode(io_in_5_bits_opcode),
    .io_in_5_bits_size(io_in_5_bits_size),
    .io_in_5_bits_source(io_in_5_bits_source),
    .io_in_5_bits_denied(io_in_5_bits_denied),
    .io_in_5_bits_data(io_in_5_bits_data),
    .io_in_5_bits_corrupt(io_in_5_bits_corrupt),
    .io_in_6_ready(i_io_in_6_ready),
    .io_in_6_valid(io_in_6_valid),
    .io_in_6_bits_opcode(io_in_6_bits_opcode),
    .io_in_6_bits_size(io_in_6_bits_size),
    .io_in_6_bits_source(io_in_6_bits_source),
    .io_in_6_bits_denied(io_in_6_bits_denied),
    .io_in_6_bits_data(io_in_6_bits_data),
    .io_in_6_bits_corrupt(io_in_6_bits_corrupt),
    .io_in_7_ready(i_io_in_7_ready),
    .io_in_7_valid(io_in_7_valid),
    .io_in_7_bits_opcode(io_in_7_bits_opcode),
    .io_in_7_bits_size(io_in_7_bits_size),
    .io_in_7_bits_source(io_in_7_bits_source),
    .io_in_7_bits_denied(io_in_7_bits_denied),
    .io_in_7_bits_data(io_in_7_bits_data),
    .io_in_7_bits_corrupt(io_in_7_bits_corrupt),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_opcode(i_io_out_bits_opcode),
    .io_out_bits_size(i_io_out_bits_size),
    .io_out_bits_source(i_io_out_bits_source),
    .io_out_bits_denied(i_io_out_bits_denied),
    .io_out_bits_data(i_io_out_bits_data),
    .io_out_bits_corrupt(i_io_out_bits_corrupt)
  );
  task automatic drive_random_inputs();
    io_in_0_valid = $urandom_range(0, 1);
    io_in_0_bits_opcode = 4'($urandom);
    io_in_0_bits_size = 2'($urandom);
    io_in_0_bits_source = 3'($urandom);
    io_in_0_bits_denied = $urandom_range(0, 1);
    io_in_0_bits_data = 64'($urandom);
    io_in_0_bits_corrupt = $urandom_range(0, 1);
    io_in_1_valid = $urandom_range(0, 1);
    io_in_1_bits_opcode = 4'($urandom);
    io_in_1_bits_size = 2'($urandom);
    io_in_1_bits_source = 3'($urandom);
    io_in_1_bits_denied = $urandom_range(0, 1);
    io_in_1_bits_data = 64'($urandom);
    io_in_1_bits_corrupt = $urandom_range(0, 1);
    io_in_2_valid = $urandom_range(0, 1);
    io_in_2_bits_opcode = 4'($urandom);
    io_in_2_bits_size = 2'($urandom);
    io_in_2_bits_source = 3'($urandom);
    io_in_2_bits_denied = $urandom_range(0, 1);
    io_in_2_bits_data = 64'($urandom);
    io_in_2_bits_corrupt = $urandom_range(0, 1);
    io_in_3_valid = $urandom_range(0, 1);
    io_in_3_bits_opcode = 4'($urandom);
    io_in_3_bits_size = 2'($urandom);
    io_in_3_bits_source = 3'($urandom);
    io_in_3_bits_denied = $urandom_range(0, 1);
    io_in_3_bits_data = 64'($urandom);
    io_in_3_bits_corrupt = $urandom_range(0, 1);
    io_in_4_valid = $urandom_range(0, 1);
    io_in_4_bits_opcode = 4'($urandom);
    io_in_4_bits_size = 2'($urandom);
    io_in_4_bits_source = 3'($urandom);
    io_in_4_bits_denied = $urandom_range(0, 1);
    io_in_4_bits_data = 64'($urandom);
    io_in_4_bits_corrupt = $urandom_range(0, 1);
    io_in_5_valid = $urandom_range(0, 1);
    io_in_5_bits_opcode = 4'($urandom);
    io_in_5_bits_size = 2'($urandom);
    io_in_5_bits_source = 3'($urandom);
    io_in_5_bits_denied = $urandom_range(0, 1);
    io_in_5_bits_data = 64'($urandom);
    io_in_5_bits_corrupt = $urandom_range(0, 1);
    io_in_6_valid = $urandom_range(0, 1);
    io_in_6_bits_opcode = 4'($urandom);
    io_in_6_bits_size = 2'($urandom);
    io_in_6_bits_source = 3'($urandom);
    io_in_6_bits_denied = $urandom_range(0, 1);
    io_in_6_bits_data = 64'($urandom);
    io_in_6_bits_corrupt = $urandom_range(0, 1);
    io_in_7_valid = $urandom_range(0, 1);
    io_in_7_bits_opcode = 4'($urandom);
    io_in_7_bits_size = 2'($urandom);
    io_in_7_bits_source = 3'($urandom);
    io_in_7_bits_denied = $urandom_range(0, 1);
    io_in_7_bits_data = 64'($urandom);
    io_in_7_bits_corrupt = $urandom_range(0, 1);
    io_out_ready = $urandom_range(0, 1);
  endtask
  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_in_4_ready)
    `CHECK(io_in_5_ready)
    `CHECK(io_in_6_ready)
    `CHECK(io_in_7_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_opcode)
    `CHECK(io_out_bits_size)
    `CHECK(io_out_bits_source)
    `CHECK(io_out_bits_denied)
    `CHECK(io_out_bits_data)
    `CHECK(io_out_bits_corrupt)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    io_in_0_valid = '0;
    io_in_0_bits_opcode = '0;
    io_in_0_bits_size = '0;
    io_in_0_bits_source = '0;
    io_in_0_bits_denied = '0;
    io_in_0_bits_data = '0;
    io_in_0_bits_corrupt = '0;
    io_in_1_valid = '0;
    io_in_1_bits_opcode = '0;
    io_in_1_bits_size = '0;
    io_in_1_bits_source = '0;
    io_in_1_bits_denied = '0;
    io_in_1_bits_data = '0;
    io_in_1_bits_corrupt = '0;
    io_in_2_valid = '0;
    io_in_2_bits_opcode = '0;
    io_in_2_bits_size = '0;
    io_in_2_bits_source = '0;
    io_in_2_bits_denied = '0;
    io_in_2_bits_data = '0;
    io_in_2_bits_corrupt = '0;
    io_in_3_valid = '0;
    io_in_3_bits_opcode = '0;
    io_in_3_bits_size = '0;
    io_in_3_bits_source = '0;
    io_in_3_bits_denied = '0;
    io_in_3_bits_data = '0;
    io_in_3_bits_corrupt = '0;
    io_in_4_valid = '0;
    io_in_4_bits_opcode = '0;
    io_in_4_bits_size = '0;
    io_in_4_bits_source = '0;
    io_in_4_bits_denied = '0;
    io_in_4_bits_data = '0;
    io_in_4_bits_corrupt = '0;
    io_in_5_valid = '0;
    io_in_5_bits_opcode = '0;
    io_in_5_bits_size = '0;
    io_in_5_bits_source = '0;
    io_in_5_bits_denied = '0;
    io_in_5_bits_data = '0;
    io_in_5_bits_corrupt = '0;
    io_in_6_valid = '0;
    io_in_6_bits_opcode = '0;
    io_in_6_bits_size = '0;
    io_in_6_bits_source = '0;
    io_in_6_bits_denied = '0;
    io_in_6_bits_data = '0;
    io_in_6_bits_corrupt = '0;
    io_in_7_valid = '0;
    io_in_7_bits_opcode = '0;
    io_in_7_bits_size = '0;
    io_in_7_bits_source = '0;
    io_in_7_bits_denied = '0;
    io_in_7_bits_data = '0;
    io_in_7_bits_corrupt = '0;
    io_out_ready = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("Arbiter8_TLBundleD checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
