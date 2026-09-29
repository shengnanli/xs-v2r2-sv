`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [106:0] c107_a, c107_b, c107_c;
  wire [106:0] c107_sum_g, c107_car_g, c107_sum_i, c107_car_i;
  CSA3to2 g_c107 (
    .io_in_a(c107_a), .io_in_b(c107_b), .io_in_c(c107_c),
    .io_out_sum(c107_sum_g), .io_out_car(c107_car_g)
  );
  CSA3to2_xs i_c107 (
    .io_in_a(c107_a), .io_in_b(c107_b), .io_in_c(c107_c),
    .io_out_sum(c107_sum_i), .io_out_car(c107_car_i)
  );

  logic [7:0] c8_a, c8_b, c8_c, c8_d;
  wire [7:0] c8_sum_g, c8_car_g, c8_sum_i, c8_car_i;
  wire [7:0] c4_sum_g, c4_car_g, c4_sum_i, c4_car_i;
  CSA3to2_132 g_c8 (
    .io_in_a(c8_a), .io_in_b(c8_b), .io_in_c(c8_c),
    .io_out_sum(c8_sum_g), .io_out_car(c8_car_g)
  );
  CSA3to2_132_xs i_c8 (
    .io_in_a(c8_a), .io_in_b(c8_b), .io_in_c(c8_c),
    .io_out_sum(c8_sum_i), .io_out_car(c8_car_i)
  );
  CSA4to2_16 g_c4 (
    .io_in_a(c8_a), .io_in_b(c8_b), .io_in_c(c8_c), .io_in_d(c8_d),
    .io_out_sum(c4_sum_g), .io_out_car(c4_car_g)
  );
  CSA4to2_16_xs i_c4 (
    .io_in_a(c8_a), .io_in_b(c8_b), .io_in_c(c8_c), .io_in_d(c8_d),
    .io_out_sum(c4_sum_i), .io_out_car(c4_car_i)
  );

  logic [4:0] conversion_select;
  logic [15:0] pre16_a, pre16_b;
  logic [31:0] pre32_a, pre32_b;
  logic [63:0] pre64_a, pre64_b;
  wire [15:0] next16_ag, next16_bg, next16_ai, next16_bi;
  wire [31:0] next32_ag, next32_bg, next32_ai, next32_bi;
  wire [63:0] next64_ag, next64_bg, next64_ai, next64_bi;

  Conversion g_conv16 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre16_a), .io_pre_q_B(pre16_b),
    .io_nxt_q_A(next16_ag), .io_nxt_q_B(next16_bg)
  );
  Conversion_xs i_conv16 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre16_a), .io_pre_q_B(pre16_b),
    .io_nxt_q_A(next16_ai), .io_nxt_q_B(next16_bi)
  );
  Conversion_8 g_conv32 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre32_a), .io_pre_q_B(pre32_b),
    .io_nxt_q_A(next32_ag), .io_nxt_q_B(next32_bg)
  );
  Conversion_8_xs i_conv32 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre32_a), .io_pre_q_B(pre32_b),
    .io_nxt_q_A(next32_ai), .io_nxt_q_B(next32_bi)
  );
  Conversion_12 g_conv64 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre64_a), .io_pre_q_B(pre64_b),
    .io_nxt_q_A(next64_ag), .io_nxt_q_B(next64_bg)
  );
  Conversion_12_xs i_conv64 (
    .io_q_j_1(conversion_select), .io_pre_q_A(pre64_a), .io_pre_q_B(pre64_b),
    .io_nxt_q_A(next64_ai), .io_nxt_q_B(next64_bi)
  );

  function automatic [31:0] random32;
    random32 = $urandom;
  endfunction

  task automatic randomize_inputs;
    c107_a = {random32(), random32(), random32(), random32()};
    c107_b = {random32(), random32(), random32(), random32()};
    c107_c = {random32(), random32(), random32(), random32()};
    c8_a = random32();
    c8_b = random32();
    c8_c = random32();
    c8_d = random32();
    conversion_select = random32();
    pre16_a = random32();
    pre16_b = random32();
    pre32_a = random32();
    pre32_b = random32();
    pre64_a = {random32(), random32()};
    pre64_b = {random32(), random32()};
  endtask

  task automatic compare_now;
    logic [15:0] expected16_a, expected16_b;
    logic [31:0] expected32_a, expected32_b;
    logic [63:0] expected64_a, expected64_b;
    integer candidate;
    begin
      #1;
      vectors++;

      expected16_a = '0;
      expected16_b = '0;
      expected32_a = '0;
      expected32_b = '0;
      expected64_a = '0;
      expected64_b = '0;
      for (candidate = 0; candidate < 5; candidate = candidate + 1) begin
        if (conversion_select[candidate]) begin
          case (candidate)
            0: begin
              expected16_a |= {pre16_a[13:0], 2'b10};
              expected16_b |= {pre16_a[13:0], 2'b01};
              expected32_a |= {pre32_a[29:0], 2'b10};
              expected32_b |= {pre32_a[29:0], 2'b01};
              expected64_a |= {pre64_a[61:0], 2'b10};
              expected64_b |= {pre64_a[61:0], 2'b01};
            end
            1: begin
              expected16_a |= {pre16_a[13:0], 2'b01};
              expected16_b |= {pre16_a[13:0], 2'b00};
              expected32_a |= {pre32_a[29:0], 2'b01};
              expected32_b |= {pre32_a[29:0], 2'b00};
              expected64_a |= {pre64_a[61:0], 2'b01};
              expected64_b |= {pre64_a[61:0], 2'b00};
            end
            2: begin
              expected16_a |= {pre16_a[13:0], 2'b00};
              expected16_b |= {pre16_b[13:0], 2'b11};
              expected32_a |= {pre32_a[29:0], 2'b00};
              expected32_b |= {pre32_b[29:0], 2'b11};
              expected64_a |= {pre64_a[61:0], 2'b00};
              expected64_b |= {pre64_b[61:0], 2'b11};
            end
            3: begin
              expected16_a |= {pre16_b[13:0], 2'b11};
              expected16_b |= {pre16_b[13:0], 2'b10};
              expected32_a |= {pre32_b[29:0], 2'b11};
              expected32_b |= {pre32_b[29:0], 2'b10};
              expected64_a |= {pre64_b[61:0], 2'b11};
              expected64_b |= {pre64_b[61:0], 2'b10};
            end
            4: begin
              expected16_a |= {pre16_b[13:0], 2'b10};
              expected16_b |= {pre16_b[13:0], 2'b01};
              expected32_a |= {pre32_b[29:0], 2'b10};
              expected32_b |= {pre32_b[29:0], 2'b01};
              expected64_a |= {pre64_b[61:0], 2'b10};
              expected64_b |= {pre64_b[61:0], 2'b01};
            end
          endcase
        end
      end

      if ({c107_sum_g, c107_car_g, c8_sum_g, c8_car_g, c4_sum_g, c4_car_g,
           next16_ag, next16_bg, next32_ag, next32_bg, next64_ag, next64_bg} !==
          {c107_sum_i, c107_car_i, c8_sum_i, c8_car_i, c4_sum_i, c4_car_i,
           next16_ai, next16_bi, next32_ai, next32_bi, next64_ai, next64_bi}) begin
        errors++;
        if (errors < 8)
          $display("golden mismatch at vector %0d", vectors);
      end

      if (((c107_sum_i + c107_car_i) !== (c107_a + c107_b + c107_c)) ||
          ((c8_sum_i + c8_car_i) !== (c8_a + c8_b + c8_c)) ||
          ((c4_sum_i + c4_car_i) !== (c8_a + c8_b + c8_c + c8_d)) ||
          (next16_ai !== expected16_a) || (next16_bi !== expected16_b) ||
          (next32_ai !== expected32_a) || (next32_bi !== expected32_b) ||
          (next64_ai !== expected64_a) || (next64_bi !== expected64_b)) begin
        errors++;
        if (errors < 8)
          $display("independent oracle mismatch at vector %0d", vectors);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    {c107_a, c107_b, c107_c, c8_a, c8_b, c8_c, c8_d,
     conversion_select, pre16_a, pre16_b, pre32_a, pre32_b, pre64_a, pre64_b} = '0;
    compare_now();

    {c107_a, c107_b, c107_c, c8_a, c8_b, c8_c, c8_d,
     pre16_a, pre16_b, pre32_a, pre32_b, pre64_a, pre64_b} = '1;
    conversion_select = 5'b11111;
    compare_now();

    c107_a = '1; c107_b = {{106{1'b0}}, 1'b1}; c107_c = '0;
    c8_a = 8'hff; c8_b = 8'h01; c8_c = 8'h55; c8_d = 8'haa;
    pre16_a = 16'h8000; pre16_b = 16'h7fff;
    pre32_a = 32'h80000000; pre32_b = 32'h7fffffff;
    pre64_a = 64'h8000000000000000; pre64_b = 64'h7fffffffffffffff;
    for (int one_hot = 0; one_hot < 5; one_hot++) begin
      conversion_select = 5'b00001 << one_hot;
      compare_now();
    end

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("ArithmeticLeaves6 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 6, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
