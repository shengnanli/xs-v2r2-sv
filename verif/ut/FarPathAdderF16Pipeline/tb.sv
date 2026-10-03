`timescale 1ns/1ps
// Differential UT for FarPathAdderF16Pipeline (12-bit "register then add").
// golden vs rewritten (dual instantiation) plus an in-tb shadow model
// (two RegEnable copies and a 12-bit wrapping add), compared every cycle.
// The two operand registers have no reset: under a non-constant initreg the
// two instances power up with different values, so comparison is gated
// until the first fire has loaded both registers (after that the state is
// fully determined by the stimulus).  Under +vcs+initreg+0 the gate is
// irrelevant (both sides start equal) and the pre-fire window is compared too.
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int checks = 0;
  int unsigned fires = 0, holds = 0, carry_out = 0, fire_runs = 0;

  logic        clock = 1'b0;
  logic        fire;
  logic [11:0] a, b;
  wire  [11:0] res_g, res_i;
  logic [11:0] sh_a, sh_b;
  logic        loaded = 1'b0;
  logic        prev_fire = 1'b0;
  bit          zero_init;

  FarPathAdderF16Pipeline    g (.clock(clock), .io_fire(fire), .io_A(a), .io_B(b), .io_result(res_g));
  FarPathAdderF16Pipeline_xs i (.clock(clock), .io_fire(fire), .io_A(a), .io_B(b), .io_result(res_i));

  always #5 clock = ~clock;

  always @(posedge clock) begin
    if (fire) begin
      sh_a   <= a;
      sh_b   <= b;
      loaded <= 1'b1;
    end
  end

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    zero_init = $test$plusargs("vcs+initreg+0");
    fire = 1'b0; a = '0; b = '0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // compare state produced by the previous edge
      if (loaded || zero_init) begin
        checks++;
        if (res_g !== res_i) begin
          errors++;
          if (errors < 8) $display("golden mismatch @%0t: g=%h i=%h", $time, res_g, res_i);
        end
        if (loaded && res_i !== 12'(sh_a + sh_b)) begin
          errors++;
          if (errors < 8) $display("model mismatch @%0t: i=%h model=%h", $time, res_i, 12'(sh_a + sh_b));
        end
        if (loaded && ({1'b0, sh_a} + {1'b0, sh_b}) > 13'hfff) carry_out++;
      end
      // drive next stimulus: fire ~60%, operands biased toward carry corners
      fire = ($urandom % 10) < 6;
      if (fire) fires++; else holds++;
      if (fire && prev_fire) fire_runs++;
      prev_fire = fire;
      case ($urandom % 4)
        0: begin a = '1; b = 12'($urandom); end
        1: begin a = 12'($urandom); b = 12'h800 | 12'($urandom); end
        default: begin a = 12'($urandom); b = 12'($urandom); end
      endcase
    end
    $display("COVERAGE fire=%0d hold=%0d back-to-back-fire=%0d wrap-carry=%0d", fires, holds, fire_runs, carry_out);
    if (fires == 0 || holds == 0 || carry_out == 0) begin
      errors++;
      $display("coverage hole");
    end
    $display("FarPathAdderF16Pipeline UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
