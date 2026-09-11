// 自动生成：scripts/gen_pipeline.py —— 勿手改
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
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

  logic io_in_valid;
  logic [47:0] io_in_bits_paddr;
  logic [1:0] io_in_bits_alias;
  logic io_in_bits_confidence;
  logic io_in_bits_is_store;
  logic [2:0] io_in_bits_pf_source_value;
  logic io_out_ready;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [47:0] g_io_out_bits_paddr;
  wire [47:0] i_io_out_bits_paddr;
  wire [1:0] g_io_out_bits_alias;
  wire [1:0] i_io_out_bits_alias;
  wire g_io_out_bits_confidence;
  wire i_io_out_bits_confidence;
  wire g_io_out_bits_is_store;
  wire i_io_out_bits_is_store;
  wire [2:0] g_io_out_bits_pf_source_value;
  wire [2:0] i_io_out_bits_pf_source_value;

  Pipeline u_g (
    .clock(clock),
    .reset(reset),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_paddr(io_in_bits_paddr),
    .io_in_bits_alias(io_in_bits_alias),
    .io_in_bits_confidence(io_in_bits_confidence),
    .io_in_bits_is_store(io_in_bits_is_store),
    .io_in_bits_pf_source_value(io_in_bits_pf_source_value),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_paddr(g_io_out_bits_paddr),
    .io_out_bits_alias(g_io_out_bits_alias),
    .io_out_bits_confidence(g_io_out_bits_confidence),
    .io_out_bits_is_store(g_io_out_bits_is_store),
    .io_out_bits_pf_source_value(g_io_out_bits_pf_source_value)
  );

  Pipeline_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_paddr(io_in_bits_paddr),
    .io_in_bits_alias(io_in_bits_alias),
    .io_in_bits_confidence(io_in_bits_confidence),
    .io_in_bits_is_store(io_in_bits_is_store),
    .io_in_bits_pf_source_value(io_in_bits_pf_source_value),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_paddr(i_io_out_bits_paddr),
    .io_out_bits_alias(i_io_out_bits_alias),
    .io_out_bits_confidence(i_io_out_bits_confidence),
    .io_out_bits_is_store(i_io_out_bits_is_store),
    .io_out_bits_pf_source_value(i_io_out_bits_pf_source_value)
  );

  task automatic drive_random_inputs();
    io_in_valid = $urandom_range(0, 1);
    io_in_bits_paddr = 48'({$urandom, $urandom});
    io_in_bits_alias = 2'({$urandom});
    io_in_bits_confidence = $urandom_range(0, 1);
    io_in_bits_is_store = $urandom_range(0, 1);
    io_in_bits_pf_source_value = 3'({$urandom});
    io_out_ready = $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_paddr)
    `CHECK(io_out_bits_alias)
    `CHECK(io_out_bits_confidence)
    `CHECK(io_out_bits_is_store)
    `CHECK(io_out_bits_pf_source_value)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_valid = '0;
    io_in_bits_paddr = '0;
    io_in_bits_alias = '0;
    io_in_bits_confidence = '0;
    io_in_bits_is_store = '0;
    io_in_bits_pf_source_value = '0;
    io_out_ready = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("Pipeline checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
