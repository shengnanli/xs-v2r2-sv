// tb -- PFEvent UT: golden PFEvent (u_g) vs readable PFEvent_xs (u_i), per-cycle compare.
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        io_distribute_csr_w_valid;
  logic [11:0] io_distribute_csr_w_bits_addr;
  logic [63:0] io_distribute_csr_w_bits_data;
  wire [63:0] g_io_hpmevent_0, i_io_hpmevent_0;
  wire [63:0] g_io_hpmevent_1, i_io_hpmevent_1;
  wire [63:0] g_io_hpmevent_2, i_io_hpmevent_2;
  wire [63:0] g_io_hpmevent_3, i_io_hpmevent_3;
  wire [63:0] g_io_hpmevent_4, i_io_hpmevent_4;
  wire [63:0] g_io_hpmevent_5, i_io_hpmevent_5;
  wire [63:0] g_io_hpmevent_6, i_io_hpmevent_6;
  wire [63:0] g_io_hpmevent_7, i_io_hpmevent_7;
  wire [63:0] g_io_hpmevent_8, i_io_hpmevent_8;
  wire [63:0] g_io_hpmevent_9, i_io_hpmevent_9;
  wire [63:0] g_io_hpmevent_10, i_io_hpmevent_10;
  wire [63:0] g_io_hpmevent_11, i_io_hpmevent_11;
  wire [63:0] g_io_hpmevent_12, i_io_hpmevent_12;
  wire [63:0] g_io_hpmevent_13, i_io_hpmevent_13;
  wire [63:0] g_io_hpmevent_14, i_io_hpmevent_14;
  wire [63:0] g_io_hpmevent_15, i_io_hpmevent_15;
  wire [63:0] g_io_hpmevent_16, i_io_hpmevent_16;
  wire [63:0] g_io_hpmevent_17, i_io_hpmevent_17;
  wire [63:0] g_io_hpmevent_18, i_io_hpmevent_18;
  wire [63:0] g_io_hpmevent_19, i_io_hpmevent_19;
  wire [63:0] g_io_hpmevent_20, i_io_hpmevent_20;
  wire [63:0] g_io_hpmevent_21, i_io_hpmevent_21;
  wire [63:0] g_io_hpmevent_22, i_io_hpmevent_22;
  wire [63:0] g_io_hpmevent_23, i_io_hpmevent_23;

  PFEvent    u_g (
    .clock(clk), .reset(rst),
    .io_distribute_csr_w_valid(io_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data),
    .io_hpmevent_0(g_io_hpmevent_0),
    .io_hpmevent_1(g_io_hpmevent_1),
    .io_hpmevent_2(g_io_hpmevent_2),
    .io_hpmevent_3(g_io_hpmevent_3),
    .io_hpmevent_4(g_io_hpmevent_4),
    .io_hpmevent_5(g_io_hpmevent_5),
    .io_hpmevent_6(g_io_hpmevent_6),
    .io_hpmevent_7(g_io_hpmevent_7),
    .io_hpmevent_8(g_io_hpmevent_8),
    .io_hpmevent_9(g_io_hpmevent_9),
    .io_hpmevent_10(g_io_hpmevent_10),
    .io_hpmevent_11(g_io_hpmevent_11),
    .io_hpmevent_12(g_io_hpmevent_12),
    .io_hpmevent_13(g_io_hpmevent_13),
    .io_hpmevent_14(g_io_hpmevent_14),
    .io_hpmevent_15(g_io_hpmevent_15),
    .io_hpmevent_16(g_io_hpmevent_16),
    .io_hpmevent_17(g_io_hpmevent_17),
    .io_hpmevent_18(g_io_hpmevent_18),
    .io_hpmevent_19(g_io_hpmevent_19),
    .io_hpmevent_20(g_io_hpmevent_20),
    .io_hpmevent_21(g_io_hpmevent_21),
    .io_hpmevent_22(g_io_hpmevent_22),
    .io_hpmevent_23(g_io_hpmevent_23)
  );

  PFEvent_xs u_i (
    .clock(clk), .reset(rst),
    .io_distribute_csr_w_valid(io_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data),
    .io_hpmevent_0(i_io_hpmevent_0),
    .io_hpmevent_1(i_io_hpmevent_1),
    .io_hpmevent_2(i_io_hpmevent_2),
    .io_hpmevent_3(i_io_hpmevent_3),
    .io_hpmevent_4(i_io_hpmevent_4),
    .io_hpmevent_5(i_io_hpmevent_5),
    .io_hpmevent_6(i_io_hpmevent_6),
    .io_hpmevent_7(i_io_hpmevent_7),
    .io_hpmevent_8(i_io_hpmevent_8),
    .io_hpmevent_9(i_io_hpmevent_9),
    .io_hpmevent_10(i_io_hpmevent_10),
    .io_hpmevent_11(i_io_hpmevent_11),
    .io_hpmevent_12(i_io_hpmevent_12),
    .io_hpmevent_13(i_io_hpmevent_13),
    .io_hpmevent_14(i_io_hpmevent_14),
    .io_hpmevent_15(i_io_hpmevent_15),
    .io_hpmevent_16(i_io_hpmevent_16),
    .io_hpmevent_17(i_io_hpmevent_17),
    .io_hpmevent_18(i_io_hpmevent_18),
    .io_hpmevent_19(i_io_hpmevent_19),
    .io_hpmevent_20(i_io_hpmevent_20),
    .io_hpmevent_21(i_io_hpmevent_21),
    .io_hpmevent_22(i_io_hpmevent_22),
    .io_hpmevent_23(i_io_hpmevent_23)
  );

  task automatic drive_inputs();
    io_distribute_csr_w_valid = $urandom & 1;
    // 偏置写地址到合法 mhpmevent 段 0x323..0x33A 以频繁命中各寄存器。
    if (($urandom & 3) != 0)
      io_distribute_csr_w_bits_addr = 12'h323 + ($urandom % 24);
    else
      io_distribute_csr_w_bits_addr = $urandom;
    io_distribute_csr_w_bits_data = {$urandom,$urandom};
  endtask

  task automatic check_outputs();
    checks++;
    if (!$isunknown(g_io_hpmevent_0) && g_io_hpmevent_0 !== i_io_hpmevent_0) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_0 g=%h i=%h", cyc, g_io_hpmevent_0, i_io_hpmevent_0); end
    if (!$isunknown(g_io_hpmevent_1) && g_io_hpmevent_1 !== i_io_hpmevent_1) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_1 g=%h i=%h", cyc, g_io_hpmevent_1, i_io_hpmevent_1); end
    if (!$isunknown(g_io_hpmevent_2) && g_io_hpmevent_2 !== i_io_hpmevent_2) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_2 g=%h i=%h", cyc, g_io_hpmevent_2, i_io_hpmevent_2); end
    if (!$isunknown(g_io_hpmevent_3) && g_io_hpmevent_3 !== i_io_hpmevent_3) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_3 g=%h i=%h", cyc, g_io_hpmevent_3, i_io_hpmevent_3); end
    if (!$isunknown(g_io_hpmevent_4) && g_io_hpmevent_4 !== i_io_hpmevent_4) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_4 g=%h i=%h", cyc, g_io_hpmevent_4, i_io_hpmevent_4); end
    if (!$isunknown(g_io_hpmevent_5) && g_io_hpmevent_5 !== i_io_hpmevent_5) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_5 g=%h i=%h", cyc, g_io_hpmevent_5, i_io_hpmevent_5); end
    if (!$isunknown(g_io_hpmevent_6) && g_io_hpmevent_6 !== i_io_hpmevent_6) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_6 g=%h i=%h", cyc, g_io_hpmevent_6, i_io_hpmevent_6); end
    if (!$isunknown(g_io_hpmevent_7) && g_io_hpmevent_7 !== i_io_hpmevent_7) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_7 g=%h i=%h", cyc, g_io_hpmevent_7, i_io_hpmevent_7); end
    if (!$isunknown(g_io_hpmevent_8) && g_io_hpmevent_8 !== i_io_hpmevent_8) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_8 g=%h i=%h", cyc, g_io_hpmevent_8, i_io_hpmevent_8); end
    if (!$isunknown(g_io_hpmevent_9) && g_io_hpmevent_9 !== i_io_hpmevent_9) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_9 g=%h i=%h", cyc, g_io_hpmevent_9, i_io_hpmevent_9); end
    if (!$isunknown(g_io_hpmevent_10) && g_io_hpmevent_10 !== i_io_hpmevent_10) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_10 g=%h i=%h", cyc, g_io_hpmevent_10, i_io_hpmevent_10); end
    if (!$isunknown(g_io_hpmevent_11) && g_io_hpmevent_11 !== i_io_hpmevent_11) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_11 g=%h i=%h", cyc, g_io_hpmevent_11, i_io_hpmevent_11); end
    if (!$isunknown(g_io_hpmevent_12) && g_io_hpmevent_12 !== i_io_hpmevent_12) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_12 g=%h i=%h", cyc, g_io_hpmevent_12, i_io_hpmevent_12); end
    if (!$isunknown(g_io_hpmevent_13) && g_io_hpmevent_13 !== i_io_hpmevent_13) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_13 g=%h i=%h", cyc, g_io_hpmevent_13, i_io_hpmevent_13); end
    if (!$isunknown(g_io_hpmevent_14) && g_io_hpmevent_14 !== i_io_hpmevent_14) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_14 g=%h i=%h", cyc, g_io_hpmevent_14, i_io_hpmevent_14); end
    if (!$isunknown(g_io_hpmevent_15) && g_io_hpmevent_15 !== i_io_hpmevent_15) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_15 g=%h i=%h", cyc, g_io_hpmevent_15, i_io_hpmevent_15); end
    if (!$isunknown(g_io_hpmevent_16) && g_io_hpmevent_16 !== i_io_hpmevent_16) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_16 g=%h i=%h", cyc, g_io_hpmevent_16, i_io_hpmevent_16); end
    if (!$isunknown(g_io_hpmevent_17) && g_io_hpmevent_17 !== i_io_hpmevent_17) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_17 g=%h i=%h", cyc, g_io_hpmevent_17, i_io_hpmevent_17); end
    if (!$isunknown(g_io_hpmevent_18) && g_io_hpmevent_18 !== i_io_hpmevent_18) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_18 g=%h i=%h", cyc, g_io_hpmevent_18, i_io_hpmevent_18); end
    if (!$isunknown(g_io_hpmevent_19) && g_io_hpmevent_19 !== i_io_hpmevent_19) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_19 g=%h i=%h", cyc, g_io_hpmevent_19, i_io_hpmevent_19); end
    if (!$isunknown(g_io_hpmevent_20) && g_io_hpmevent_20 !== i_io_hpmevent_20) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_20 g=%h i=%h", cyc, g_io_hpmevent_20, i_io_hpmevent_20); end
    if (!$isunknown(g_io_hpmevent_21) && g_io_hpmevent_21 !== i_io_hpmevent_21) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_21 g=%h i=%h", cyc, g_io_hpmevent_21, i_io_hpmevent_21); end
    if (!$isunknown(g_io_hpmevent_22) && g_io_hpmevent_22 !== i_io_hpmevent_22) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_22 g=%h i=%h", cyc, g_io_hpmevent_22, i_io_hpmevent_22); end
    if (!$isunknown(g_io_hpmevent_23) && g_io_hpmevent_23 !== i_io_hpmevent_23) begin errors++; if (errors<=40) $display("[%0d] MISMATCH hpmevent_23 g=%h i=%h", cyc, g_io_hpmevent_23, i_io_hpmevent_23); end
  endtask

  initial begin
    rst = 1'b1;
    io_distribute_csr_w_valid = 0;
    io_distribute_csr_w_bits_addr = 0;
    io_distribute_csr_w_bits_data = 0;
    repeat (6) @(negedge clk);
    rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      drive_inputs();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
