`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [4:0] sub_a, sub_b;
  wire [4:0] sub_g, sub_i;
  Adder_18    g_sub (.io_a(sub_a), .io_b(sub_b), .io_c(sub_g));
  Adder_18_xs i_sub (.io_a(sub_a), .io_b(sub_b), .io_c(sub_i));

  logic [63:0] add64_a, add64_b;
  logic [31:0] add32_a, add32_b;
  logic [15:0] add16_a, add16_b;
  logic [7:0]  add8_a, add8_b;
  wire add64_g, add64_i, add32_g, add32_i;
  wire add16_g, add16_i, add8_g, add8_i;
  Adder_xb       g_add64 (.io_in1(add64_a), .io_in2(add64_b), .io_cout(add64_g));
  Adder_xb_xs    i_add64 (.io_in1(add64_a), .io_in2(add64_b), .io_cout(add64_i));
  Adder_xb_3     g_add32 (.io_in1(add32_a), .io_in2(add32_b), .io_cout(add32_g));
  Adder_xb_3_xs  i_add32 (.io_in1(add32_a), .io_in2(add32_b), .io_cout(add32_i));
  Adder_xb_8     g_add16 (.io_in1(add16_a), .io_in2(add16_b), .io_cout(add16_g));
  Adder_xb_8_xs  i_add16 (.io_in1(add16_a), .io_in2(add16_b), .io_cout(add16_i));
  Adder_xb_20    g_add8  (.io_in1(add8_a),  .io_in2(add8_b),  .io_cout(add8_g));
  Adder_xb_20_xs i_add8  (.io_in1(add8_a),  .io_in2(add8_b),  .io_cout(add8_i));

  logic [199:0] c200_a, c200_b, c200_c;
  logic [71:0] c72_a, c72_b, c72_c;
  logic [63:0] c64_a, c64_b, c64_c;
  logic [31:0] c32_a, c32_b, c32_c;
  logic [15:0] c16_a, c16_b, c16_c;
  wire [199:0] c200_sg, c200_cg, c200_si, c200_ci;
  wire [71:0] c72_sg, c72_cg, c72_si, c72_ci;
  wire [63:0] c64_sg, c64_cg, c64_si, c64_ci;
  wire [31:0] c32_sg, c32_cg, c32_si, c32_ci;
  wire [15:0] c16_sg, c16_cg, c16_si, c16_ci;
  CSA3to2_20     g_c200 (.io_in_a(c200_a), .io_in_b(c200_b), .io_in_c(c200_c), .io_out_sum(c200_sg), .io_out_car(c200_cg));
  CSA3to2_20_xs  i_c200 (.io_in_a(c200_a), .io_in_b(c200_b), .io_in_c(c200_c), .io_out_sum(c200_si), .io_out_car(c200_ci));
  CSA3to2_24     g_c72  (.io_in_a(c72_a),  .io_in_b(c72_b),  .io_in_c(c72_c),  .io_out_sum(c72_sg),  .io_out_car(c72_cg));
  CSA3to2_24_xs  i_c72  (.io_in_a(c72_a),  .io_in_b(c72_b),  .io_in_c(c72_c),  .io_out_sum(c72_si),  .io_out_car(c72_ci));
  CSA3to2_124    g_c64  (.io_in_a(c64_a),  .io_in_b(c64_b),  .io_in_c(c64_c),  .io_out_sum(c64_sg),  .io_out_car(c64_cg));
  CSA3to2_124_xs i_c64  (.io_in_a(c64_a),  .io_in_b(c64_b),  .io_in_c(c64_c),  .io_out_sum(c64_si),  .io_out_car(c64_ci));
  CSA3to2_125    g_c32  (.io_in_a(c32_a),  .io_in_b(c32_b),  .io_in_c(c32_c),  .io_out_sum(c32_sg),  .io_out_car(c32_cg));
  CSA3to2_125_xs i_c32  (.io_in_a(c32_a),  .io_in_b(c32_b),  .io_in_c(c32_c),  .io_out_sum(c32_si),  .io_out_car(c32_ci));
  CSA3to2_127    g_c16  (.io_in_a(c16_a),  .io_in_b(c16_b),  .io_in_c(c16_c),  .io_out_sum(c16_sg),  .io_out_car(c16_cg));
  CSA3to2_127_xs i_c16  (.io_in_a(c16_a),  .io_in_b(c16_b),  .io_in_c(c16_c),  .io_out_sum(c16_si),  .io_out_car(c16_ci));

  task automatic randomize_inputs;
    c200_a = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    c200_b = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    c200_c = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
    c72_a = {$urandom,$urandom,$urandom}; c72_b = {$urandom,$urandom,$urandom};
    c72_c = {$urandom,$urandom,$urandom};
    c64_a = {$urandom,$urandom}; c64_b = {$urandom,$urandom}; c64_c = {$urandom,$urandom};
    c32_a = $urandom; c32_b = $urandom; c32_c = $urandom;
    c16_a = $urandom; c16_b = $urandom; c16_c = $urandom;
    add64_a = {$urandom,$urandom}; add64_b = {$urandom,$urandom};
    add32_a = $urandom; add32_b = $urandom;
    add16_a = $urandom; add16_b = $urandom;
    add8_a = $urandom; add8_b = $urandom;
    sub_a = $urandom; sub_b = $urandom;
  endtask

  task automatic compare_now;
    #1; vectors++;
    if ({sub_g,add64_g,add32_g,add16_g,add8_g,
         c200_sg,c200_cg,c72_sg,c72_cg,c64_sg,c64_cg,
         c32_sg,c32_cg,c16_sg,c16_cg} !==
        {sub_i,add64_i,add32_i,add16_i,add8_i,
         c200_si,c200_ci,c72_si,c72_ci,c64_si,c64_ci,
         c32_si,c32_ci,c16_si,c16_ci}) begin
      errors++;
      if (errors < 8) $display("arithmetic mismatch at vector %0d", vectors);
    end
  endtask

  initial begin
    // Directed extrema exercise wrap, carry, and all three majority cases.
    {sub_a,sub_b} = '0;
    {add64_a,add64_b,add32_a,add32_b,add16_a,add16_b,add8_a,add8_b} = '0;
    {c200_a,c200_b,c200_c,c72_a,c72_b,c72_c,c64_a,c64_b,c64_c,
     c32_a,c32_b,c32_c,c16_a,c16_b,c16_c} = '0;
    compare_now();
    {sub_a,sub_b} = '1;
    {add64_a,add64_b,add32_a,add32_b,add16_a,add16_b,add8_a,add8_b} = '1;
    {c200_a,c200_b,c200_c,c72_a,c72_b,c72_c,c64_a,c64_b,c64_c,
     c32_a,c32_b,c32_c,c16_a,c16_b,c16_c} = '1;
    compare_now();
    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end
    $display("ArithmeticLeaves10 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 10, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
