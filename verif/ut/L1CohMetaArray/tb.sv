// 自动生成：scripts/gen_l1metaarray.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 250000;
  int errors = 0, checks = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;
  logic io_read_0_valid;
  logic [7:0] io_read_0_bits_idx;
  logic io_read_1_valid;
  logic [7:0] io_read_1_bits_idx;
  logic io_read_2_valid;
  logic [7:0] io_read_2_bits_idx;
  logic io_read_3_valid;
  logic [7:0] io_read_3_bits_idx;
  logic io_write_0_valid;
  logic [7:0] io_write_0_bits_idx;
  logic [3:0] io_write_0_bits_way_en;
  logic [1:0] io_write_0_bits_meta_coh_state;
  wire [1:0] g_io_resp_0_0_coh_state;  wire [1:0] i_io_resp_0_0_coh_state;
  wire [1:0] g_io_resp_0_1_coh_state;  wire [1:0] i_io_resp_0_1_coh_state;
  wire [1:0] g_io_resp_0_2_coh_state;  wire [1:0] i_io_resp_0_2_coh_state;
  wire [1:0] g_io_resp_0_3_coh_state;  wire [1:0] i_io_resp_0_3_coh_state;
  wire [1:0] g_io_resp_1_0_coh_state;  wire [1:0] i_io_resp_1_0_coh_state;
  wire [1:0] g_io_resp_1_1_coh_state;  wire [1:0] i_io_resp_1_1_coh_state;
  wire [1:0] g_io_resp_1_2_coh_state;  wire [1:0] i_io_resp_1_2_coh_state;
  wire [1:0] g_io_resp_1_3_coh_state;  wire [1:0] i_io_resp_1_3_coh_state;
  wire [1:0] g_io_resp_2_0_coh_state;  wire [1:0] i_io_resp_2_0_coh_state;
  wire [1:0] g_io_resp_2_1_coh_state;  wire [1:0] i_io_resp_2_1_coh_state;
  wire [1:0] g_io_resp_2_2_coh_state;  wire [1:0] i_io_resp_2_2_coh_state;
  wire [1:0] g_io_resp_2_3_coh_state;  wire [1:0] i_io_resp_2_3_coh_state;
  wire [1:0] g_io_resp_3_0_coh_state;  wire [1:0] i_io_resp_3_0_coh_state;
  wire [1:0] g_io_resp_3_1_coh_state;  wire [1:0] i_io_resp_3_1_coh_state;
  wire [1:0] g_io_resp_3_2_coh_state;  wire [1:0] i_io_resp_3_2_coh_state;
  wire [1:0] g_io_resp_3_3_coh_state;  wire [1:0] i_io_resp_3_3_coh_state;
  L1CohMetaArray u_g_ (.clock(clock), .reset(reset), .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_0_bits_meta_coh_state(io_write_0_bits_meta_coh_state), .io_resp_0_0_coh_state(g_io_resp_0_0_coh_state), .io_resp_0_1_coh_state(g_io_resp_0_1_coh_state), .io_resp_0_2_coh_state(g_io_resp_0_2_coh_state), .io_resp_0_3_coh_state(g_io_resp_0_3_coh_state), .io_resp_1_0_coh_state(g_io_resp_1_0_coh_state), .io_resp_1_1_coh_state(g_io_resp_1_1_coh_state), .io_resp_1_2_coh_state(g_io_resp_1_2_coh_state), .io_resp_1_3_coh_state(g_io_resp_1_3_coh_state), .io_resp_2_0_coh_state(g_io_resp_2_0_coh_state), .io_resp_2_1_coh_state(g_io_resp_2_1_coh_state), .io_resp_2_2_coh_state(g_io_resp_2_2_coh_state), .io_resp_2_3_coh_state(g_io_resp_2_3_coh_state), .io_resp_3_0_coh_state(g_io_resp_3_0_coh_state), .io_resp_3_1_coh_state(g_io_resp_3_1_coh_state), .io_resp_3_2_coh_state(g_io_resp_3_2_coh_state), .io_resp_3_3_coh_state(g_io_resp_3_3_coh_state));
  L1CohMetaArray_xs u_i_ (.clock(clock), .reset(reset), .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_write_0_valid(io_write_0_valid), .io_write_0_bits_idx(io_write_0_bits_idx), .io_write_0_bits_way_en(io_write_0_bits_way_en), .io_write_0_bits_meta_coh_state(io_write_0_bits_meta_coh_state), .io_resp_0_0_coh_state(i_io_resp_0_0_coh_state), .io_resp_0_1_coh_state(i_io_resp_0_1_coh_state), .io_resp_0_2_coh_state(i_io_resp_0_2_coh_state), .io_resp_0_3_coh_state(i_io_resp_0_3_coh_state), .io_resp_1_0_coh_state(i_io_resp_1_0_coh_state), .io_resp_1_1_coh_state(i_io_resp_1_1_coh_state), .io_resp_1_2_coh_state(i_io_resp_1_2_coh_state), .io_resp_1_3_coh_state(i_io_resp_1_3_coh_state), .io_resp_2_0_coh_state(i_io_resp_2_0_coh_state), .io_resp_2_1_coh_state(i_io_resp_2_1_coh_state), .io_resp_2_2_coh_state(i_io_resp_2_2_coh_state), .io_resp_2_3_coh_state(i_io_resp_2_3_coh_state), .io_resp_3_0_coh_state(i_io_resp_3_0_coh_state), .io_resp_3_1_coh_state(i_io_resp_3_1_coh_state), .io_resp_3_2_coh_state(i_io_resp_3_2_coh_state), .io_resp_3_3_coh_state(i_io_resp_3_3_coh_state));
  task automatic do_check(int t);
    checks++;
    if (!$isunknown(g_io_resp_0_0_coh_state) && (g_io_resp_0_0_coh_state !== i_io_resp_0_0_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_0_coh_state g=%h i=%h",t,g_io_resp_0_0_coh_state,i_io_resp_0_0_coh_state); end
    if (!$isunknown(g_io_resp_0_1_coh_state) && (g_io_resp_0_1_coh_state !== i_io_resp_0_1_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_1_coh_state g=%h i=%h",t,g_io_resp_0_1_coh_state,i_io_resp_0_1_coh_state); end
    if (!$isunknown(g_io_resp_0_2_coh_state) && (g_io_resp_0_2_coh_state !== i_io_resp_0_2_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_2_coh_state g=%h i=%h",t,g_io_resp_0_2_coh_state,i_io_resp_0_2_coh_state); end
    if (!$isunknown(g_io_resp_0_3_coh_state) && (g_io_resp_0_3_coh_state !== i_io_resp_0_3_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_3_coh_state g=%h i=%h",t,g_io_resp_0_3_coh_state,i_io_resp_0_3_coh_state); end
    if (!$isunknown(g_io_resp_1_0_coh_state) && (g_io_resp_1_0_coh_state !== i_io_resp_1_0_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_0_coh_state g=%h i=%h",t,g_io_resp_1_0_coh_state,i_io_resp_1_0_coh_state); end
    if (!$isunknown(g_io_resp_1_1_coh_state) && (g_io_resp_1_1_coh_state !== i_io_resp_1_1_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_1_coh_state g=%h i=%h",t,g_io_resp_1_1_coh_state,i_io_resp_1_1_coh_state); end
    if (!$isunknown(g_io_resp_1_2_coh_state) && (g_io_resp_1_2_coh_state !== i_io_resp_1_2_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_2_coh_state g=%h i=%h",t,g_io_resp_1_2_coh_state,i_io_resp_1_2_coh_state); end
    if (!$isunknown(g_io_resp_1_3_coh_state) && (g_io_resp_1_3_coh_state !== i_io_resp_1_3_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_3_coh_state g=%h i=%h",t,g_io_resp_1_3_coh_state,i_io_resp_1_3_coh_state); end
    if (!$isunknown(g_io_resp_2_0_coh_state) && (g_io_resp_2_0_coh_state !== i_io_resp_2_0_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_0_coh_state g=%h i=%h",t,g_io_resp_2_0_coh_state,i_io_resp_2_0_coh_state); end
    if (!$isunknown(g_io_resp_2_1_coh_state) && (g_io_resp_2_1_coh_state !== i_io_resp_2_1_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_1_coh_state g=%h i=%h",t,g_io_resp_2_1_coh_state,i_io_resp_2_1_coh_state); end
    if (!$isunknown(g_io_resp_2_2_coh_state) && (g_io_resp_2_2_coh_state !== i_io_resp_2_2_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_2_coh_state g=%h i=%h",t,g_io_resp_2_2_coh_state,i_io_resp_2_2_coh_state); end
    if (!$isunknown(g_io_resp_2_3_coh_state) && (g_io_resp_2_3_coh_state !== i_io_resp_2_3_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_3_coh_state g=%h i=%h",t,g_io_resp_2_3_coh_state,i_io_resp_2_3_coh_state); end
    if (!$isunknown(g_io_resp_3_0_coh_state) && (g_io_resp_3_0_coh_state !== i_io_resp_3_0_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_0_coh_state g=%h i=%h",t,g_io_resp_3_0_coh_state,i_io_resp_3_0_coh_state); end
    if (!$isunknown(g_io_resp_3_1_coh_state) && (g_io_resp_3_1_coh_state !== i_io_resp_3_1_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_1_coh_state g=%h i=%h",t,g_io_resp_3_1_coh_state,i_io_resp_3_1_coh_state); end
    if (!$isunknown(g_io_resp_3_2_coh_state) && (g_io_resp_3_2_coh_state !== i_io_resp_3_2_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_2_coh_state g=%h i=%h",t,g_io_resp_3_2_coh_state,i_io_resp_3_2_coh_state); end
    if (!$isunknown(g_io_resp_3_3_coh_state) && (g_io_resp_3_3_coh_state !== i_io_resp_3_3_coh_state)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_3_coh_state g=%h i=%h",t,g_io_resp_3_3_coh_state,i_io_resp_3_3_coh_state); end
  endtask
  task automatic drive_random();
    io_read_0_valid = $urandom_range(0,1);
    io_read_0_bits_idx = 8'($urandom_range(0,15));
    io_read_1_valid = $urandom_range(0,1);
    io_read_1_bits_idx = 8'($urandom_range(0,15));
    io_read_2_valid = $urandom_range(0,1);
    io_read_2_bits_idx = 8'($urandom_range(0,15));
    io_read_3_valid = $urandom_range(0,1);
    io_read_3_bits_idx = 8'($urandom_range(0,15));
    io_write_0_valid = ($urandom_range(0,2) == 0);
    io_write_0_bits_idx = 8'($urandom_range(0,15));
    io_write_0_bits_way_en = 4'($urandom);
    io_write_0_bits_meta_coh_state = 2'($urandom);
  endtask
  initial begin
    reset = 1;
    io_read_0_valid = 0;  io_read_0_bits_idx = 0;
    io_read_1_valid = 0;  io_read_1_bits_idx = 0;
    io_read_2_valid = 0;  io_read_2_bits_idx = 0;
    io_read_3_valid = 0;  io_read_3_bits_idx = 0;
    io_write_0_valid = 0;  io_write_0_bits_idx = 0;  io_write_0_bits_way_en = 0;
    io_write_0_bits_meta_coh_state = 0;
    repeat (3) @(posedge clock); #1; reset = 0;
    @(posedge clock);
    for (int t = 0; t < NVEC; t++) begin
      drive_random();
      @(posedge clock); #1;
      do_check(t);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
