`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  bit rst;
  int errors = 0;
  int checks = 0;

  always #5 clk = ~clk;

  wire [49:0] g_io_prefetch_req_0_bits_vaddr;
  wire [49:0] g_io_prefetch_req_1_bits_vaddr;
  wire [49:0] i_io_prefetch_req_0_bits_vaddr;
  wire [49:0] i_io_prefetch_req_1_bits_vaddr;

  StorePfWrapper u_g (
    .clock(clk),
    .reset(rst),
    .io_prefetch_req_0_bits_vaddr(g_io_prefetch_req_0_bits_vaddr),
    .io_prefetch_req_1_bits_vaddr(g_io_prefetch_req_1_bits_vaddr)
  );

  StorePfWrapper_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_prefetch_req_0_bits_vaddr(i_io_prefetch_req_0_bits_vaddr),
    .io_prefetch_req_1_bits_vaddr(i_io_prefetch_req_1_bits_vaddr)
  );

  task automatic check_output(
      input string name,
      input logic [49:0] golden,
      input logic [49:0] impl);
    if (!$isunknown(golden)) begin
      checks++;
      if (impl !== golden) begin
        errors++;
        if (errors < 20) begin
          $display("[ERR] cycle=%0t %s golden=%h impl=%h", $time, name, golden, impl);
        end
      end
    end
  endtask

  initial begin
    void'($value$plusargs("NCYCLES=%d", NCYCLES));
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    repeat (NCYCLES) begin
      @(negedge clk);
      check_output("io_prefetch_req_0_bits_vaddr",
                   g_io_prefetch_req_0_bits_vaddr,
                   i_io_prefetch_req_0_bits_vaddr);
      check_output("io_prefetch_req_1_bits_vaddr",
                   g_io_prefetch_req_1_bits_vaddr,
                   i_io_prefetch_req_1_bits_vaddr);
    end

    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $display("TEST FAILED");
      $fatal(1);
    end
  end
endmodule
