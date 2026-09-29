`timescale 1ns/1ps

module tb;
  int unsigned ncycles = 200000;
  int unsigned vectors;
  int unsigned errors;

  logic [53:0] c54_src;
  logic [5:0] c54_shift;
  wire [53:0] c54_golden, c54_impl;
  CloseShiftLeftWithMux g_c54 (.io_src(c54_src), .io_shiftValue(c54_shift), .io_result(c54_golden));
  CloseShiftLeftWithMux_xs i_c54 (.io_src(c54_src), .io_shiftValue(c54_shift), .io_result(c54_impl));

  logic [24:0] c25_src;
  logic [4:0] c25_shift;
  wire [24:0] c25_golden, c25_impl;
  CloseShiftLeftWithMux_1 g_c25 (.io_src(c25_src), .io_shiftValue(c25_shift), .io_result(c25_golden));
  CloseShiftLeftWithMux_1_xs i_c25 (.io_src(c25_src), .io_shiftValue(c25_shift), .io_result(c25_impl));

  logic [11:0] c12_src;
  logic [3:0] c12_shift;
  wire [11:0] c12_golden, c12_impl;
  CloseShiftLeftWithMux_9 g_c12 (.io_src(c12_src), .io_shiftValue(c12_shift), .io_result(c12_golden));
  CloseShiftLeftWithMux_9_xs i_c12 (.io_src(c12_src), .io_shiftValue(c12_shift), .io_result(c12_impl));

  logic [109:0] f110_src;
  logic [5:0] f110_shift;
  logic f110_fill;
  wire [109:0] f110_golden, f110_impl;
  FarShiftRightWithMuxInvFirst g_f110 (.io_src(f110_src), .io_shiftValue(f110_shift), .io_result(f110_golden), .io_EOP(f110_fill));
  FarShiftRightWithMuxInvFirst_xs i_f110 (.io_src(f110_src), .io_shiftValue(f110_shift), .io_result(f110_impl), .io_EOP(f110_fill));

  logic [51:0] f52_src;
  logic [4:0] f52_shift;
  logic f52_fill;
  wire [51:0] f52_golden, f52_impl;
  FarShiftRightWithMuxInvFirst_2 g_f52 (.io_src(f52_src), .io_shiftValue(f52_shift), .io_result(f52_golden), .io_EOP(f52_fill));
  FarShiftRightWithMuxInvFirst_2_xs i_f52 (.io_src(f52_src), .io_shiftValue(f52_shift), .io_result(f52_impl), .io_EOP(f52_fill));

  logic [25:0] f26_src;
  logic [3:0] f26_shift;
  logic f26_fill;
  wire [25:0] f26_golden, f26_impl;
  FarShiftRightWithMuxInvFirst_18 g_f26 (.io_src(f26_src), .io_shiftValue(f26_shift), .io_result(f26_golden), .io_EOP(f26_fill));
  FarShiftRightWithMuxInvFirst_18_xs i_f26 (.io_src(f26_src), .io_shiftValue(f26_shift), .io_result(f26_impl), .io_EOP(f26_fill));

  logic [63:0] l64_src;
  logic [5:0] l64_shift, l64_reverse_shift;
  wire [63:0] l64_golden, l64_reverse_golden, l64_impl, l64_reverse_impl;
  LeftShiftModule g_l64 (.io_shamt(l64_shift), .io_revShamt(l64_reverse_shift), .io_sllSrc(l64_src), .io_sll(l64_golden), .io_revSll(l64_reverse_golden));
  LeftShiftModule_xs i_l64 (.io_shamt(l64_shift), .io_revShamt(l64_reverse_shift), .io_sllSrc(l64_src), .io_sll(l64_impl), .io_revSll(l64_reverse_impl));

  logic [31:0] l32_src;
  logic [4:0] l32_shift, l32_reverse_shift;
  wire [31:0] l32_golden, l32_reverse_golden, l32_impl, l32_reverse_impl;
  LeftShiftWordModule g_l32 (.io_shamt(l32_shift), .io_revShamt(l32_reverse_shift), .io_sllSrc(l32_src), .io_sllw(l32_golden), .io_revSllw(l32_reverse_golden));
  LeftShiftWordModule_xs i_l32 (.io_shamt(l32_shift), .io_revShamt(l32_reverse_shift), .io_sllSrc(l32_src), .io_sllw(l32_impl), .io_revSllw(l32_reverse_impl));

  logic [53:0] c54_oracle;
  logic [24:0] c25_oracle;
  logic [11:0] c12_oracle;
  logic signed [110:0] f110_extended;
  logic signed [52:0] f52_extended;
  logic signed [26:0] f26_extended;
  logic [109:0] f110_oracle;
  logic [51:0] f52_oracle;
  logic [25:0] f26_oracle;
  logic [63:0] l64_oracle, l64_reverse_oracle;
  logic [31:0] l32_oracle, l32_reverse_oracle;

  task automatic randomize_inputs;
    c54_src = {$urandom, $urandom};
    c25_src = $urandom;
    c12_src = $urandom;
    c54_shift = $urandom;
    c25_shift = $urandom;
    c12_shift = $urandom;
    f110_src = {$urandom, $urandom, $urandom, $urandom};
    f52_src = {$urandom, $urandom};
    f26_src = $urandom;
    f110_shift = $urandom;
    f52_shift = $urandom;
    f26_shift = $urandom;
    f110_fill = $urandom;
    f52_fill = $urandom;
    f26_fill = $urandom;
    l64_src = {$urandom, $urandom};
    l32_src = $urandom;
    l64_shift = $urandom;
    l64_reverse_shift = $urandom;
    l32_shift = $urandom;
    l32_reverse_shift = $urandom;
  endtask

  task automatic compare_now;
    #1;
    vectors++;
    c54_oracle = c54_src << c54_shift;
    c25_oracle = c25_src << c25_shift;
    c12_oracle = c12_src << c12_shift;
    f110_extended = {f110_fill, f110_src};
    f52_extended = {f52_fill, f52_src};
    f26_extended = {f26_fill, f26_src};
    f110_oracle = f110_extended >>> f110_shift;
    f52_oracle = f52_extended >>> f52_shift;
    f26_oracle = f26_extended >>> f26_shift;
    l64_oracle = l64_src << l64_shift;
    l64_reverse_oracle = l64_src << l64_reverse_shift;
    l32_oracle = l32_src << l32_shift;
    l32_reverse_oracle = l32_src << l32_reverse_shift;

    if ({c54_impl,c25_impl,c12_impl,f110_impl,f52_impl,f26_impl,
         l64_impl,l64_reverse_impl,l32_impl,l32_reverse_impl} !==
        {c54_golden,c25_golden,c12_golden,f110_golden,f52_golden,f26_golden,
         l64_golden,l64_reverse_golden,l32_golden,l32_reverse_golden} ||
        {c54_impl,c25_impl,c12_impl,f110_impl,f52_impl,f26_impl,
         l64_impl,l64_reverse_impl,l32_impl,l32_reverse_impl} !==
        {c54_oracle,c25_oracle,c12_oracle,f110_oracle,f52_oracle,f26_oracle,
         l64_oracle,l64_reverse_oracle,l32_oracle,l32_reverse_oracle}) begin
      errors++;
      if (errors <= 8)
        $display("shift mismatch vector=%0d", vectors);
    end
  endtask

  task automatic set_directed_shift(input int unsigned amount);
    c54_shift = amount;
    c25_shift = amount;
    c12_shift = amount;
    f110_shift = amount;
    f52_shift = amount;
    f26_shift = amount;
    l64_shift = amount;
    l64_reverse_shift = amount;
    l32_shift = amount;
    l32_reverse_shift = amount;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", ncycles));
    vectors = 0;
    errors = 0;
    randomize_inputs();

    // Common edges, plus width/width+1 for the close shifters whose ports can
    // encode them. Wide far/ALU leaves intentionally expose only log2(width)
    // shift bits, so their architectural maximum is the representable maximum.
    set_directed_shift(0); compare_now();
    set_directed_shift(1); compare_now();
    set_directed_shift(11); compare_now();
    c12_shift = 12; compare_now();
    c12_shift = 13; compare_now();
    c12_shift = 15; compare_now();
    c25_shift = 25; compare_now();
    c25_shift = 26; compare_now();
    c25_shift = 31; compare_now();
    c54_shift = 54; compare_now();
    c54_shift = 55; compare_now();
    set_directed_shift(63); compare_now();

    repeat (ncycles) begin
      randomize_inputs();
      compare_now();
    end

    $display("ShiftMathLeaves8 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 8, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
