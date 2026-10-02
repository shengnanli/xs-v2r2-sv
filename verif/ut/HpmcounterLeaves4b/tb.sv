// HpmcounterLeaves4b dual-instance differential testbench.
// Four G1 HPM leaves and four _xs wrappers receive identical negedge-driven
// live sources, debug-stop muxes, update-valid pulses, and asynchronous resets.
// The checks exercise reset, live reads, snapshot capture, hold, and re-entry.
`timescale 1ns/1ps

module tb;
  localparam int N_LEAVES = 4;
  localparam int N_OUT = 4;
  int unsigned NCYCLES = 200000;
  bit clock = 1'b0;
  always #5 clock = ~clock;

  logic reset;
  logic debug_stop;
  logic update_valid;
  logic [63:0] live_source [N_LEAVES];
  wire  [63:0] golden_rdata [N_LEAVES];
  wire  [63:0] xs_rdata [N_LEAVES];

  longint checks = 0;
  longint errors = 0;
  bit [N_OUT-1:0] toggled = '0;
  logic [63:0] previous_golden [N_OUT];
  longint f_reset = 0;
  longint f_live = 0;
  longint f_update = 0;
  longint f_stop = 0;

  Hpmcounter7Module u_g7 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[0]),
    .mHPM_hpmcounters_4(live_source[0]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter7Module_xs u_x7 (
    .clock(clock), .reset(reset), .rdata(xs_rdata[0]),
    .mHPM_hpmcounters_4(live_source[0]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter8Module u_g8 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[1]),
    .mHPM_hpmcounters_5(live_source[1]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter8Module_xs u_x8 (
    .clock(clock), .reset(reset), .rdata(xs_rdata[1]),
    .mHPM_hpmcounters_5(live_source[1]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter9Module u_g9 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[2]),
    .mHPM_hpmcounters_6(live_source[2]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter9Module_xs u_x9 (
    .clock(clock), .reset(reset), .rdata(xs_rdata[2]),
    .mHPM_hpmcounters_6(live_source[2]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter10Module u_g10 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[3]),
    .mHPM_hpmcounters_7(live_source[3]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );
  Hpmcounter10Module_xs u_x10 (
    .clock(clock), .reset(reset), .rdata(xs_rdata[3]),
    .mHPM_hpmcounters_7(live_source[3]),
    .debugModeStopCount(debug_stop), .unprivCountUpdate(update_valid)
  );

  function automatic logic [63:0] source_pick(input int unsigned slot);
    case ($urandom_range(0, 7))
      0:       return 64'h0;
      1:       return 64'hffff_ffff_ffff_ffff;
      2:       return 64'(slot + 1);
      default: return {$urandom, $urandom};
    endcase
  endfunction

  task automatic compare_outputs;
    for (int i = 0; i < N_LEAVES; i++) begin
      if (!$isunknown(golden_rdata[i])) begin
        checks++;
        if (golden_rdata[i] !== xs_rdata[i]) begin
          errors++;
          if (errors <= 32)
            $display("[%0t] MISMATCH leaf=%0d golden=%016h xs=%016h",
                     $time, i, golden_rdata[i], xs_rdata[i]);
        end
        if (!$isunknown(previous_golden[i]) && golden_rdata[i] !== previous_golden[i])
          toggled[i] = 1'b1;
        previous_golden[i] = golden_rdata[i];
      end
    end
  endtask

  task automatic drive_cycle(input int unsigned cycle_number);
    // The first cycles are deterministic directed corners; the remainder is
    // random but keeps every control event frequent enough for coverage.
    if (cycle_number == 0) begin
      reset = 1'b1;
      debug_stop = 1'b0;
      update_valid = 1'b0;
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = '0;
    end else if (cycle_number == 1) begin
      reset = 1'b0;
      debug_stop = 1'b0;
      update_valid = 1'b0;
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = '1;
    end else if (cycle_number == 2) begin
      reset = 1'b0;
      debug_stop = 1'b1;
      update_valid = 1'b1;
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = 64'h100 + i;
    end else if (cycle_number == 3) begin
      reset = 1'b0;
      debug_stop = 1'b1;
      update_valid = 1'b0;
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = 64'h200 + i;
    end else if (cycle_number == 4) begin
      reset = 1'b0;
      debug_stop = 1'b0;
      update_valid = 1'b0;
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = 64'h300 + i;
    end else begin
      reset = 1'b0;
      debug_stop = ($urandom_range(0, 3) == 0);
      update_valid = ($urandom_range(0, 9) < 2);
      for (int i = 0; i < N_LEAVES; i++) live_source[i] = source_pick(i);
    end
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    reset = 1'b1;
    debug_stop = 1'b0;
    update_valid = 1'b0;
    for (int i = 0; i < N_LEAVES; i++) begin
      live_source[i] = '0;
      previous_golden[i] = 'x;
    end

    // Async reset is asserted at time zero, then all subsequent stimulus is
    // changed on negedges so the state elements only see stable setup values.
    repeat (3) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;

    for (int unsigned cycle_number = 0; cycle_number < NCYCLES; cycle_number++) begin
      if (cycle_number == NCYCLES / 2) begin
        @(negedge clock);
        reset = 1'b1;
        f_reset++;
        #1 compare_outputs();
        repeat (2) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
      end
      @(negedge clock);
      drive_cycle(cycle_number);
      if (reset) f_reset++;
      else if (debug_stop) f_stop++;
      else f_live++;
      if (update_valid) f_update++;
      #1 compare_outputs();
      @(posedge clock);
    end

    $display("HpmcounterLeaves4b UT: checks=%0d errors=%0d toggled=%0d/%0d",
             checks, errors, $countones(toggled), N_OUT);
    $display("COV reset=%0d live=%0d update=%0d debug_stop=%0d",
             f_reset, f_live, f_update, f_stop);
    if (errors != 0) begin
      $display("TEST FAILED (mismatch)");
      $fatal(1);
    end
    if (checks == 0) begin
      $display("TEST FAILED (coverage: no comparison happened)");
      $fatal(1);
    end
    if ($countones(toggled) != N_OUT) begin
      $display("TEST FAILED (coverage: only %0d/%0d outputs toggled)",
               $countones(toggled), N_OUT);
      $fatal(1);
    end
    if (f_live == 0 || f_update == 0 || f_stop == 0 || f_reset == 0) begin
      $display("TEST FAILED (coverage: reset/live/update/stop event missing)");
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule
