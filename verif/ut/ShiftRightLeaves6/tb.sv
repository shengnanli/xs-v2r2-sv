`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [64:0] in65;
  logic [10:0] sh65;
  wire [64:0] out65_g, out65_i;
  wire sticky65_g, sticky65_i;

  logic [24:0] in25;
  logic [7:0] sh25;
  wire [24:0] out25_g, out25_i;
  wire sticky25_g, sticky25_i;

  logic [11:0] in12a, in12b;
  logic [7:0] sh12a;
  logic [4:0] sh12b;
  wire [11:0] out12a_g, out12a_i, out12b_g, out12b_i;
  wire sticky12a_g, sticky12a_i, sticky12b_g, sticky12b_i;

  logic [63:0] srl64_src, sra64_src;
  logic [5:0] sh64, rev64;
  wire [63:0] srl64_g, sra64_g, revsrl64_g;
  wire [63:0] srl64_i, sra64_i, revsrl64_i;
  wire [63:0] expected_sra64 = $signed(sra64_src) >>> sh64;

  logic [31:0] srl32_src, sra32_src;
  logic [4:0] sh32, rev32;
  wire [31:0] srl32_g, sra32_g, revsrl32_g;
  wire [31:0] srl32_i, sra32_i, revsrl32_i;
  wire [31:0] expected_sra32 = $signed(sra32_src) >>> sh32;

  ShiftRightJam g_j65(.io_in(in65), .io_shamt(sh65), .io_out(out65_g), .io_sticky(sticky65_g));
  ShiftRightJam_xs i_j65(.io_in(in65), .io_shamt(sh65), .io_out(out65_i), .io_sticky(sticky65_i));
  ShiftRightJam_2 g_j25(.io_in(in25), .io_shamt(sh25), .io_out(out25_g), .io_sticky(sticky25_g));
  ShiftRightJam_2_xs i_j25(.io_in(in25), .io_shamt(sh25), .io_out(out25_i), .io_sticky(sticky25_i));
  ShiftRightJam_3 g_j12a(.io_in(in12a), .io_shamt(sh12a), .io_out(out12a_g), .io_sticky(sticky12a_g));
  ShiftRightJam_3_xs i_j12a(.io_in(in12a), .io_shamt(sh12a), .io_out(out12a_i), .io_sticky(sticky12a_i));
  ShiftRightJam_4 g_j12b(.io_in(in12b), .io_shamt(sh12b), .io_out(out12b_g), .io_sticky(sticky12b_g));
  ShiftRightJam_4_xs i_j12b(.io_in(in12b), .io_shamt(sh12b), .io_out(out12b_i), .io_sticky(sticky12b_i));

  RightShiftModule g_r64(
    .io_shamt(sh64), .io_revShamt(rev64), .io_srlSrc(srl64_src), .io_sraSrc(sra64_src),
    .io_srl(srl64_g), .io_sra(sra64_g), .io_revSrl(revsrl64_g)
  );
  RightShiftModule_xs i_r64(
    .io_shamt(sh64), .io_revShamt(rev64), .io_srlSrc(srl64_src), .io_sraSrc(sra64_src),
    .io_srl(srl64_i), .io_sra(sra64_i), .io_revSrl(revsrl64_i)
  );
  RightShiftWordModule g_r32(
    .io_shamt(sh32), .io_revShamt(rev32), .io_srlSrc(srl32_src), .io_sraSrc(sra32_src),
    .io_srlw(srl32_g), .io_sraw(sra32_g), .io_revSrlw(revsrl32_g)
  );
  RightShiftWordModule_xs i_r32(
    .io_shamt(sh32), .io_revShamt(rev32), .io_srlSrc(srl32_src), .io_sraSrc(sra32_src),
    .io_srlw(srl32_i), .io_sraw(sra32_i), .io_revSrlw(revsrl32_i)
  );

  function automatic logic expected_sticky65(input logic [64:0] value, input logic [10:0] amount);
    integer bit_index;
    begin
      expected_sticky65 = 1'b0;
      for (bit_index = 0; bit_index < 65; bit_index++)
        if (bit_index < amount) expected_sticky65 |= value[bit_index];
    end
  endfunction

  function automatic logic expected_sticky25(input logic [24:0] value, input logic [7:0] amount);
    integer bit_index;
    begin
      expected_sticky25 = 1'b0;
      for (bit_index = 0; bit_index < 25; bit_index++)
        if (bit_index < amount) expected_sticky25 |= value[bit_index];
    end
  endfunction

  function automatic logic expected_sticky12a(input logic [11:0] value, input logic [7:0] amount);
    integer bit_index;
    begin
      expected_sticky12a = 1'b0;
      for (bit_index = 0; bit_index < 12; bit_index++)
        if (bit_index < amount) expected_sticky12a |= value[bit_index];
    end
  endfunction

  function automatic logic expected_sticky12b(input logic [11:0] value, input logic [4:0] amount);
    integer bit_index;
    begin
      expected_sticky12b = 1'b0;
      for (bit_index = 0; bit_index < 12; bit_index++)
        if (bit_index < amount) expected_sticky12b |= value[bit_index];
    end
  endfunction

  task automatic compare_now;
    begin
      #1;
      vectors++;
      if ({out65_g,sticky65_g,out25_g,sticky25_g,out12a_g,sticky12a_g,
           out12b_g,sticky12b_g,srl64_g,sra64_g,revsrl64_g,srl32_g,sra32_g,revsrl32_g} !==
          {out65_i,sticky65_i,out25_i,sticky25_i,out12a_i,sticky12a_i,
           out12b_i,sticky12b_i,srl64_i,sra64_i,revsrl64_i,srl32_i,sra32_i,revsrl32_i})
        begin
          errors++;
          if (errors < 8)
            $display("golden mismatch v=%0d j65=%h/%b:%h/%b j25=%h/%b:%h/%b j12a=%h/%b:%h/%b j12b=%h/%b:%h/%b",
                     vectors, out65_g, sticky65_g, out65_i, sticky65_i,
                     out25_g, sticky25_g, out25_i, sticky25_i,
                     out12a_g, sticky12a_g, out12a_i, sticky12a_i,
                     out12b_g, sticky12b_g, out12b_i, sticky12b_i);
        end

      if (out65_i !== ((sh65 > 65) ? 65'b0 : (in65 >> sh65)) ||
          sticky65_i !== expected_sticky65(in65, sh65) ||
          out25_i !== ((sh25 > 25) ? 25'b0 : (in25 >> sh25)) ||
          sticky25_i !== expected_sticky25(in25, sh25) ||
          out12a_i !== ((sh12a > 12) ? 12'b0 : (in12a >> sh12a)) ||
          sticky12a_i !== expected_sticky12a(in12a, sh12a) ||
          out12b_i !== ((sh12b > 12) ? 12'b0 : (in12b >> sh12b)) ||
          sticky12b_i !== expected_sticky12b(in12b, sh12b) ||
          srl64_i !== (srl64_src >> sh64) ||
          sra64_i !== expected_sra64 ||
          revsrl64_i !== (srl64_src >> rev64) ||
          srl32_i !== (srl32_src >> sh32) ||
          sra32_i !== expected_sra32 ||
          revsrl32_i !== (srl32_src >> rev32))
        begin
          errors++;
          if (errors < 8)
            $display("oracle mismatch v=%0d sh=%0d/%0d/%0d/%0d sticky=%b/%b/%b/%b flags=%b%b%b%b%b%b%b%b%b%b%b%b%b%b",
                     vectors, sh65, sh25, sh12a, sh12b,
                     sticky65_i, sticky25_i, sticky12a_i, sticky12b_i,
                     out65_i !== ((sh65 > 65) ? 65'b0 : (in65 >> sh65)),
                     sticky65_i !== expected_sticky65(in65, sh65),
                     out25_i !== ((sh25 > 25) ? 25'b0 : (in25 >> sh25)),
                     sticky25_i !== expected_sticky25(in25, sh25),
                     out12a_i !== ((sh12a > 12) ? 12'b0 : (in12a >> sh12a)),
                     sticky12a_i !== expected_sticky12a(in12a, sh12a),
                     out12b_i !== ((sh12b > 12) ? 12'b0 : (in12b >> sh12b)),
                     sticky12b_i !== expected_sticky12b(in12b, sh12b),
                     srl64_i !== (srl64_src >> sh64),
                     sra64_i !== expected_sra64,
                     revsrl64_i !== (srl64_src >> rev64),
                     srl32_i !== (srl32_src >> sh32),
                     sra32_i !== expected_sra32,
                     revsrl32_i !== (srl32_src >> rev32));
          if (errors < 8)
            $display("sra32 src=%h sh=%0d got=%h expected=%h",
                     sra32_src, sh32, sra32_i, expected_sra32);
        end
    end
  endtask

  task automatic randomize_data;
    begin
      in65 = {$urandom, $urandom, $urandom};
      in25 = $urandom;
      in12a = $urandom;
      in12b = $urandom;
      srl64_src = {$urandom, $urandom};
      sra64_src = {$urandom, $urandom};
      srl32_src = $urandom;
      sra32_src = $urandom;
    end
  endtask

  task automatic set_shift_amounts(input integer amount);
    begin
      sh65 = amount;
      sh25 = amount;
      sh12a = amount;
      sh12b = amount;
      sh64 = amount;
      rev64 = 63 - (amount % 64);
      sh32 = amount;
      rev32 = 31 - (amount % 32);
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) begin end
    randomize_data();
    set_shift_amounts(0); compare_now();
    set_shift_amounts(1); compare_now();
    set_shift_amounts(11); compare_now();
    set_shift_amounts(12); compare_now();
    set_shift_amounts(13); compare_now();
    set_shift_amounts(24); compare_now();
    set_shift_amounts(25); compare_now();
    set_shift_amounts(26); compare_now();
    set_shift_amounts(31); compare_now();
    set_shift_amounts(32); compare_now();
    set_shift_amounts(63); compare_now();
    set_shift_amounts(64); compare_now();
    set_shift_amounts(65); compare_now();
    set_shift_amounts(66); compare_now();
    set_shift_amounts(255); compare_now();

    repeat (NCYCLES) begin
      randomize_data();
      sh65 = $urandom;
      sh25 = $urandom;
      sh12a = $urandom;
      sh12b = $urandom;
      sh64 = $urandom;
      rev64 = $urandom;
      sh32 = $urandom;
      rev32 = $urandom;
      compare_now();
    end

    $display("ShiftRightLeaves6 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 6, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
