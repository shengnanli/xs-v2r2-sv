`timescale 1ns/1ps
module tb;
  localparam int NLEAVES = 4;
  localparam int MIN_CHECKS = 1000;
  localparam int MIN_TOGGLES = 100;
  localparam int MIN_FIRES = 100;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [63:0] live_counter [0:NLEAVES-1];
  logic debug_stop_count;
  logic count_update;
  wire [63:0] golden_rdata [0:NLEAVES-1];
  wire [63:0] readable_rdata [0:NLEAVES-1];

  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int unsigned cycles;
  int checks;
  int errors;
  int toggles;
  int fires;
  logic [63:0] previous_golden [0:NLEAVES-1];
  logic [63:0] previous_readable [0:NLEAVES-1];

  always #5 clock = ~clock;

  Hpmcounter3Module golden_3 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[0]),
    .mHPM_hpmcounters_0(live_counter[0]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter4Module golden_4 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[1]),
    .mHPM_hpmcounters_1(live_counter[1]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter5Module golden_5 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[2]),
    .mHPM_hpmcounters_2(live_counter[2]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter6Module golden_6 (
    .clock(clock), .reset(reset), .rdata(golden_rdata[3]),
    .mHPM_hpmcounters_3(live_counter[3]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));

  Hpmcounter3Module_xs readable_3 (
    .clock(clock), .reset(reset), .rdata(readable_rdata[0]),
    .mHPM_hpmcounters_0(live_counter[0]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter4Module_xs readable_4 (
    .clock(clock), .reset(reset), .rdata(readable_rdata[1]),
    .mHPM_hpmcounters_1(live_counter[1]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter5Module_xs readable_5 (
    .clock(clock), .reset(reset), .rdata(readable_rdata[2]),
    .mHPM_hpmcounters_2(live_counter[2]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter6Module_xs readable_6 (
    .clock(clock), .reset(reset), .rdata(readable_rdata[3]),
    .mHPM_hpmcounters_3(live_counter[3]),
    .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));

  task automatic check_outputs;
    int i;
    begin
      #1;
      checks++;
      for (i = 0; i < NLEAVES; i++) begin
        if (golden_rdata[i] !== readable_rdata[i]) begin
          errors++;
          if (errors <= 8)
            $display("[%0t] Hpmcounter%0d rdata mismatch: golden=%h readable=%h",
                     $time, i + 3, golden_rdata[i], readable_rdata[i]);
        end
        if (golden_rdata[i] !== previous_golden[i] ||
            readable_rdata[i] !== previous_readable[i])
          toggles++;
        previous_golden[i] = golden_rdata[i];
        previous_readable[i] = readable_rdata[i];
      end
    end
  endtask

  always @(negedge clock) begin
    int i;
    if (reset) begin
      for (i = 0; i < NLEAVES; i++) begin
        live_counter[i] <= 64'b0;
        previous_golden[i] <= 64'b0;
        previous_readable[i] <= 64'b0;
      end
      debug_stop_count <= 1'b0;
      count_update <= 1'b0;
    end else begin
      for (i = 0; i < NLEAVES; i++)
        live_counter[i] <= {$urandom, $urandom};
      // Exercise both live and stopped views, including repeated capture events.
      debug_stop_count <= ($urandom_range(0, 7) >= 3);
      count_update <= ($urandom_range(0, 9) == 0);
      if (count_update)
        fires++;
    end
  end

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($urandom(seed));
    void'($value$plusargs("ncycles=%d", ncycles));
    for (int i = 0; i < NLEAVES; i++) begin
      live_counter[i] = 64'b0;
      previous_golden[i] = 64'b0;
      previous_readable[i] = 64'b0;
    end
    debug_stop_count = 1'b0;
    count_update = 1'b0;

    // Hold reset across a clock edge, then release before the first negedge
    // stimulus so asynchronous reset and normal capture paths are both tested.
    #12;
    reset = 1'b0;
    repeat (ncycles) begin
      @(negedge clock);
      check_outputs();
      cycles++;
    end

    $display("HpmcounterLeaves4 UT: seed=%0d cycles=%0d checks=%0d toggles=%0d fires=%0d errors=%0d",
             seed, cycles, checks, toggles, fires, errors);
    if (checks < MIN_CHECKS) begin
      errors++;
      $display("CHECK GUARD FAILED: checks=%0d < %0d", checks, MIN_CHECKS);
    end
    if (toggles < MIN_TOGGLES) begin
      errors++;
      $display("TOGGLE GUARD FAILED: toggles=%0d < %0d", toggles, MIN_TOGGLES);
    end
    if (fires < MIN_FIRES) begin
      errors++;
      $display("FIRE GUARD FAILED: fires=%0d < %0d", fires, MIN_FIRES);
    end
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
