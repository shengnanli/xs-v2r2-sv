`timescale 1ns/1ps
// Differential UT for IntBuffer (1-cycle interrupt buffer, async reset to 0).
// golden vs rewritten plus an in-tb model, sampled twice per cycle so the
// asynchronous reset is observed between clock edges, not just at them.
// Reset is pulsed at random mid-cycle offsets (asserted and released away
// from the clock edge) to exercise the async clear path.  Before the first
// reset the register holds its power-up value, which differs between the
// two instances under a non-constant initreg, so checks start after the
// first reset assertion.
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int checks = 0;
  int unsigned rst_pulses = 0, mid_rst_clears = 0, rise = 0, fall = 0;

  logic clock = 1'b0;
  logic reset = 1'b0;
  logic irq_in = 1'b0;
  logic model = 1'b0;
  logic armed = 1'b0;
  wire  out_g, out_i;

  IntBuffer    g (.clock(clock), .reset(reset), .auto_in_0(irq_in), .auto_out_0(out_g));
  IntBuffer_xs i (.clock(clock), .reset(reset), .auto_in_0(irq_in), .auto_out_0(out_i));

  always #5 clock = ~clock;

  always @(posedge clock or posedge reset) begin
    if (reset) model <= 1'b0;
    else       model <= irq_in;
  end

  task automatic check(input string where);
    if (!armed) return;
    checks++;
    if (out_g !== out_i || out_i !== model) begin
      errors++;
      if (errors < 8) $display("mismatch(%s) @%0t: g=%b i=%b model=%b", where, $time, out_g, out_i, model);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    // power-up window is checked only for X-free agreement after the first reset
    #2 reset = 1'b1; armed = 1'b1;
    #1 check("por");
    repeat (NCYCLES) begin
      @(negedge clock);
      check("negedge");
      // optional async reset pulse inside the low phase
      if ($urandom % 50 == 0) begin
        logic was_high;
        was_high = out_i;
        #1 reset = 1'b1;
        rst_pulses++;
        #1 check("in-reset");
        if (was_high) mid_rst_clears++;
        #($urandom_range(1, 2)) reset = 1'b0;
      end else if (reset && ($urandom % 4 == 0)) begin
        reset = 1'b0;
      end
      begin
        logic nxt;
        nxt = ($urandom % 3 == 0) ? ~irq_in : irq_in;
        if (nxt && !irq_in) rise++;
        if (!nxt && irq_in) fall++;
        irq_in = nxt;
      end
      @(posedge clock);
      #1 check("posedge");
    end
    $display("COVERAGE reset-pulses=%0d clears-of-high-output=%0d in-rise=%0d in-fall=%0d", rst_pulses, mid_rst_clears, rise, fall);
    if (rst_pulses == 0 || mid_rst_clears == 0 || rise == 0 || fall == 0) begin
      errors++;
      $display("coverage hole");
    end
    $display("IntBuffer UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
