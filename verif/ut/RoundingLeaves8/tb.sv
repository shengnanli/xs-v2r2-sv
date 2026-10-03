`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [22:0] in23;
  logic [51:0] in52;
  logic [9:0] in10;
  logic [63:0] in64;
  logic [23:0] in24;
  logic [10:0] in11;
  logic guard_bit, sticky_bit, sign;
  logic [2:0] rounding_mode;

  wire [22:0] out23_g, out23_i;
  wire [51:0] out52_g, out52_i;
  wire [9:0] out10_g, out10_i;
  wire inex0_g, inex0_i, carry0_g, carry0_i;
  wire inex1_g, inex1_i, carry1_g, carry1_i;
  wire inex2_g, inex2_i, carry2_g, carry2_i;
  wire inex3_g, inex3_i, up3_g, up3_i;
  wire inex4_g, inex4_i, up4_g, up4_i;
  wire inex8_g, inex8_i, up8_g, up8_i;
  wire inex9_g, inex9_i, up9_g, up9_i;
  wire inex11_g, inex11_i, up11_g, up11_i;

  RoundingUnit g0 (
    .io_in(in23), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out23_g),
    .io_inexact(inex0_g), .io_cout(carry0_g)
  );
  RoundingUnit_xs i0 (
    .io_in(in23), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out23_i),
    .io_inexact(inex0_i), .io_cout(carry0_i)
  );
  RoundingUnit_1 g1 (
    .io_in(in52), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out52_g),
    .io_inexact(inex1_g), .io_cout(carry1_g)
  );
  RoundingUnit_1_xs i1 (
    .io_in(in52), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out52_i),
    .io_inexact(inex1_i), .io_cout(carry1_i)
  );
  RoundingUnit_2 g2 (
    .io_in(in10), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out10_g),
    .io_inexact(inex2_g), .io_cout(carry2_g)
  );
  RoundingUnit_2_xs i2 (
    .io_in(in10), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode), .io_out(out10_i),
    .io_inexact(inex2_i), .io_cout(carry2_i)
  );

  RoundingUnit_3 g3 (
    .io_in(in64), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex3_g), .io_r_up(up3_g)
  );
  RoundingUnit_3_xs i3 (
    .io_in(in64), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex3_i), .io_r_up(up3_i)
  );
  RoundingUnit_4 g4 (
    .io_in(in23), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex4_g), .io_r_up(up4_g)
  );
  RoundingUnit_4_xs i4 (
    .io_in(in23), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex4_i), .io_r_up(up4_i)
  );
  RoundingUnit_8 g8 (
    .io_in(in24), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex8_g), .io_r_up(up8_g)
  );
  RoundingUnit_8_xs i8 (
    .io_in(in24), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex8_i), .io_r_up(up8_i)
  );
  RoundingUnit_9 g9 (
    .io_in(in10), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex9_g), .io_r_up(up9_g)
  );
  RoundingUnit_9_xs i9 (
    .io_in(in10), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex9_i), .io_r_up(up9_i)
  );
  RoundingUnit_11 g11 (
    .io_in(in11), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex11_g), .io_r_up(up11_g)
  );
  RoundingUnit_11_xs i11 (
    .io_in(in11), .io_roundIn(guard_bit), .io_stickyIn(sticky_bit),
    .io_signIn(sign), .io_rm(rounding_mode),
    .io_inexact(inex11_i), .io_r_up(up11_i)
  );

  function automatic logic oracle_increment(
    input logic lsb,
    input logic guard_value,
    input logic sticky_value,
    input logic sign_value,
    input logic [2:0] mode,
    input logic allow_round_to_odd
  );
    logic discarded_nonzero;
    begin
      discarded_nonzero = guard_value | sticky_value;
      oracle_increment = 1'b0;
      case (mode)
        3'd0: oracle_increment = guard_value & (sticky_value | lsb);
        3'd1: oracle_increment = 1'b0;
        3'd2: oracle_increment = discarded_nonzero & sign_value;
        3'd3: oracle_increment = discarded_nonzero & ~sign_value;
        3'd4: oracle_increment = guard_value;
        3'd6: oracle_increment = allow_round_to_odd
                                & discarded_nonzero & ~lsb;
        default: oracle_increment = 1'b0;
      endcase
    end
  endfunction

  task automatic compare_now;
    logic increment0, increment1, increment2;
    logic increment3, increment4, increment8, increment9, increment11;
    logic expected_inexact;
    logic [22:0] expected23;
    logic [51:0] expected52;
    logic [9:0] expected10;
    begin
      #1;
      vectors++;

      if ({out23_g, inex0_g, carry0_g, out52_g, inex1_g, carry1_g,
           out10_g, inex2_g, carry2_g, inex3_g, up3_g, inex4_g, up4_g,
           inex8_g, up8_g, inex9_g, up9_g, inex11_g, up11_g} !==
          {out23_i, inex0_i, carry0_i, out52_i, inex1_i, carry1_i,
           out10_i, inex2_i, carry2_i, inex3_i, up3_i, inex4_i, up4_i,
           inex8_i, up8_i, inex9_i, up9_i, inex11_i, up11_i}) begin
        errors++;
        if (errors < 8)
          $display("golden mismatch vector=%0d rm=%0d sign=%0b g=%0b s=%0b",
                   vectors, rounding_mode, sign, guard_bit, sticky_bit);
      end

      expected_inexact = guard_bit | sticky_bit;
      increment0 = oracle_increment(in23[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b0);
      increment1 = oracle_increment(in52[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b0);
      increment2 = oracle_increment(in10[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b0);
      increment3 = oracle_increment(in64[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b1);
      increment4 = oracle_increment(in23[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b1);
      increment8 = oracle_increment(in24[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b1);
      increment9 = oracle_increment(in10[0], guard_bit, sticky_bit,
                                    sign, rounding_mode, 1'b1);
      increment11 = oracle_increment(in11[0], guard_bit, sticky_bit,
                                     sign, rounding_mode, 1'b1);
      expected23 = in23 + increment0;
      expected52 = in52 + increment1;
      expected10 = in10 + increment2;

      if ((out23_i !== expected23) || (inex0_i !== expected_inexact) ||
          (carry0_i !== (increment0 & (&in23))) ||
          (out52_i !== expected52) || (inex1_i !== expected_inexact) ||
          (carry1_i !== (increment1 & (&in52))) ||
          (out10_i !== expected10) || (inex2_i !== expected_inexact) ||
          (carry2_i !== (increment2 & (&in10))) ||
          (inex3_i !== expected_inexact) || (up3_i !== increment3) ||
          (inex4_i !== expected_inexact) || (up4_i !== increment4) ||
          (inex8_i !== expected_inexact) || (up8_i !== increment8) ||
          (inex9_i !== expected_inexact) || (up9_i !== increment9) ||
          (inex11_i !== expected_inexact) || (up11_i !== increment11)) begin
        errors++;
        if (errors < 8)
          $display("oracle mismatch vector=%0d rm=%0d sign=%0b g=%0b s=%0b",
                   vectors, rounding_mode, sign, guard_bit, sticky_bit);
      end
    end
  endtask

  task automatic randomize_inputs;
    begin
      in23 = $urandom;
      in52 = {$urandom, $urandom};
      in10 = $urandom;
      in64 = {$urandom, $urandom};
      in24 = $urandom;
      in11 = $urandom;
      guard_bit = $urandom;
      sticky_bit = $urandom;
      sign = $urandom;
      rounding_mode = $urandom;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // Exhaust all modes, signs, guard/sticky pairs, retained parities, and
    // both ordinary/carry-boundary significands before random stress.
    for (int mode = 0; mode < 8; mode++) begin
      for (int sign_value = 0; sign_value < 2; sign_value++) begin
        for (int guard_value = 0; guard_value < 2; guard_value++) begin
          for (int sticky_value = 0; sticky_value < 2; sticky_value++) begin
            for (int parity = 0; parity < 2; parity++) begin
              for (int carry_boundary = 0; carry_boundary < 2; carry_boundary++) begin
                rounding_mode = mode;
                sign = sign_value;
                guard_bit = guard_value;
                sticky_bit = sticky_value;
                if (carry_boundary) begin
                  in23 = '1;
                  in52 = '1;
                  in10 = '1;
                  in64 = '1;
                  in24 = '1;
                  in11 = '1;
                end else begin
                  in23 = 23'h12_3456 | parity;
                  in52 = 52'h12345_6789_abce | parity;
                  in10 = 10'h156 | parity;
                  in64 = 64'h0123_4567_89ab_cdee | parity;
                  in24 = 24'h12_3456 | parity;
                  in11 = 11'h356 | parity;
                end
                compare_now();
              end
            end
          end
        end
      end
    end

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("RoundingLeaves8 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 8, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
