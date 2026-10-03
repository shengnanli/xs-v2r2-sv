`timescale 1ns/1ps

// Dedicated G1 trigger CSR family verification.  The _xs instances are the
// rewritten wrappers; the un-suffixed instances come from G1 golden RTL.
// Every cycle compares both implementations and an independent canonical
// mcontrol6 WARL model.  tdata2 is intentionally not reset by the G1 contract.
module tb;
  logic clock = 1'b0;
  logic reset = 1'b0;
  int unsigned NCYCLES = 200000;
  int unsigned cycles = 0;
  int unsigned checks = 0;
  int unsigned errors = 0;

  logic [3:0]  t1_wen;
  logic [3:0]  t2_wen;
  logic [63:0] t1_wdata [0:3];
  logic [63:0] t2_wdata [0:3];
  logic [3:0]  can_write_dmode;
  logic [3:0]  chainable;
  logic [2:0]  dmode_next_trigger;

  wire [63:0] impl_t1 [0:3];
  wire [63:0] gold_t1 [0:3];
  wire [63:0] impl_t2 [0:3];
  wire [63:0] gold_t2 [0:3];

  logic [63:0] expected_t1 [0:3];
  logic [63:0] expected_t2 [0:3];
  logic [3:0]  expected_t2_valid;

  always #5 clock = ~clock;

  Trigger0_Tdata1Module_xs impl_t1_0 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[0]), .w_wdata(t1_wdata[0]),
    .rdata(impl_t1[0]), .canWriteDmode(can_write_dmode[0]),
    .chainable(chainable[0]), .dmodeNextTrigger(dmode_next_trigger[0]));
  Trigger1_Tdata1Module_xs impl_t1_1 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[1]), .w_wdata(t1_wdata[1]),
    .rdata(impl_t1[1]), .canWriteDmode(can_write_dmode[1]),
    .chainable(chainable[1]), .dmodeNextTrigger(dmode_next_trigger[1]));
  Trigger2_Tdata1Module_xs impl_t1_2 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[2]), .w_wdata(t1_wdata[2]),
    .rdata(impl_t1[2]), .canWriteDmode(can_write_dmode[2]),
    .chainable(chainable[2]), .dmodeNextTrigger(dmode_next_trigger[2]));
  Trigger3_Tdata1Module_xs impl_t1_3 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[3]), .w_wdata(t1_wdata[3]),
    .rdata(impl_t1[3]), .canWriteDmode(can_write_dmode[3]),
    .chainable(chainable[3]));

  Trigger0_Tdata2Module_xs impl_t2_0 (
    .clock(clock), .w_wen(t2_wen[0]), .w_wdata(t2_wdata[0]), .rdata(impl_t2[0]));
  Trigger1_Tdata2Module_xs impl_t2_1 (
    .clock(clock), .w_wen(t2_wen[1]), .w_wdata(t2_wdata[1]), .rdata(impl_t2[1]));
  Trigger2_Tdata2Module_xs impl_t2_2 (
    .clock(clock), .w_wen(t2_wen[2]), .w_wdata(t2_wdata[2]), .rdata(impl_t2[2]));
  Trigger3_Tdata2Module_xs impl_t2_3 (
    .clock(clock), .w_wen(t2_wen[3]), .w_wdata(t2_wdata[3]), .rdata(impl_t2[3]));

  Trigger0_Tdata1Module gold_t1_0 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[0]), .w_wdata(t1_wdata[0]),
    .rdata(gold_t1[0]), .canWriteDmode(can_write_dmode[0]),
    .chainable(chainable[0]), .dmodeNextTrigger(dmode_next_trigger[0]));
  Trigger1_Tdata1Module gold_t1_1 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[1]), .w_wdata(t1_wdata[1]),
    .rdata(gold_t1[1]), .canWriteDmode(can_write_dmode[1]),
    .chainable(chainable[1]), .dmodeNextTrigger(dmode_next_trigger[1]));
  Trigger2_Tdata1Module gold_t1_2 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[2]), .w_wdata(t1_wdata[2]),
    .rdata(gold_t1[2]), .canWriteDmode(can_write_dmode[2]),
    .chainable(chainable[2]), .dmodeNextTrigger(dmode_next_trigger[2]));
  Trigger3_Tdata1Module gold_t1_3 (
    .clock(clock), .reset(reset), .w_wen(t1_wen[3]), .w_wdata(t1_wdata[3]),
    .rdata(gold_t1[3]), .canWriteDmode(can_write_dmode[3]),
    .chainable(chainable[3]));

  Trigger0_Tdata2Module gold_t2_0 (
    .clock(clock), .w_wen(t2_wen[0]), .w_wdata(t2_wdata[0]), .rdata(gold_t2[0]));
  Trigger1_Tdata2Module gold_t2_1 (
    .clock(clock), .w_wen(t2_wen[1]), .w_wdata(t2_wdata[1]), .rdata(gold_t2[1]));
  Trigger2_Tdata2Module gold_t2_2 (
    .clock(clock), .w_wen(t2_wen[2]), .w_wdata(t2_wdata[2]), .rdata(gold_t2[2]));
  Trigger3_Tdata2Module gold_t2_3 (
    .clock(clock), .w_wen(t2_wen[3]), .w_wdata(t2_wdata[3]), .rdata(gold_t2[3]));

  function automatic [63:0] canonical_tdata1(
    input [63:0] wdata,
    input        can_write,
    input        chain,
    input        next_trigger
  );
    logic dmode;
    logic type_is_mcontrol6;
    logic action_legal;
    logic match_legal;
    begin
      dmode = wdata[59] & can_write;
      type_is_mcontrol6 = (wdata[63:60] == 4'h6);
      action_legal = (wdata[15:12] == 4'h0) ||
                     ((wdata[15:12] == 4'h1) && dmode);
      match_legal = (wdata[10:7] == 4'h0) ||
                    (wdata[10:7] == 4'h2) ||
                    (wdata[10:7] == 4'h3);
      if (type_is_mcontrol6) begin
        canonical_tdata1 = {
          4'h6, dmode,
          34'h0, wdata[24:23], 7'h0,
          action_legal ? wdata[15:12] : 4'h0,
          wdata[11] & chain & ~(~dmode & next_trigger),
          match_legal ? wdata[10:7] : 4'h0,
          wdata[6], 1'b0, wdata[4:0]
        };
      end else begin
        // G1 still captures the gated dmode bit on a non-mcontrol6 write;
        // only TYPE and DATA are legalized to their reset values.
        canonical_tdata1 = {4'hf, dmode, 59'h0};
      end
    end
  endfunction

  task automatic compare_outputs;
    int i;
    begin
      checks++;
      for (i = 0; i < 4; i++) begin
        if (impl_t1[i] !== gold_t1[i]) begin
          errors++;
          $display("ERROR tdata1[%0d] impl/golden mismatch cycle=%0d impl=%h gold=%h",
                   i, cycles, impl_t1[i], gold_t1[i]);
        end
        if (impl_t1[i] !== expected_t1[i]) begin
          errors++;
          $display("ERROR tdata1[%0d] canonical mismatch cycle=%0d got=%h exp=%h",
                   i, cycles, impl_t1[i], expected_t1[i]);
        end
        if (expected_t2_valid[i]) begin
          if (impl_t2[i] !== gold_t2[i]) begin
            errors++;
            $display("ERROR tdata2[%0d] impl/golden mismatch cycle=%0d impl=%h gold=%h",
                     i, cycles, impl_t2[i], gold_t2[i]);
          end
          if (impl_t2[i] !== expected_t2[i]) begin
            errors++;
            $display("ERROR tdata2[%0d] canonical mismatch cycle=%0d got=%h exp=%h",
                     i, cycles, impl_t2[i], expected_t2[i]);
          end
        end
      end
    end
  endtask

  task automatic update_model;
    int i;
    begin
      if (reset) begin
        for (i = 0; i < 4; i++) expected_t1[i] = {4'hf, 60'h0};
      end else begin
        for (i = 0; i < 4; i++) begin
          if (t1_wen[i]) begin
            expected_t1[i] = canonical_tdata1(
              t1_wdata[i], can_write_dmode[i], chainable[i],
              (i == 3) ? 1'b0 : dmode_next_trigger[i]);
          end
          if (t2_wen[i]) begin
            expected_t2[i] = t2_wdata[i];
            expected_t2_valid[i] = 1'b1;
          end
        end
      end
    end
  endtask

  task automatic clock_and_check;
    begin
      @(posedge clock);
      #1;
      update_model();
      compare_outputs();
      cycles++;
    end
  endtask

  task automatic clear_writes;
    int i;
    begin
      t1_wen = '0;
      t2_wen = '0;
      for (i = 0; i < 4; i++) begin
        t1_wdata[i] = '0;
        t2_wdata[i] = '0;
      end
      can_write_dmode = '0;
      chainable = '0;
      dmode_next_trigger = '0;
    end
  endtask

  task automatic directed_cycle(input [63:0] base);
    int i;
    begin
      for (i = 0; i < 4; i++) begin
        t1_wen[i] = 1'b1;
        t2_wen[i] = 1'b1;
        t1_wdata[i] = base ^ (64'h1111_2222_3333_4444 * (i + 1));
        t2_wdata[i] = base ^ (64'hdead_beef_0000_1000 + i);
      end
      // Deliberately exercise dmode/action/chain gating independently by slot.
      t1_wdata[0][63:60] = 4'h6; t1_wdata[0][59] = 1'b1; t1_wdata[0][15:12] = 4'h1;
      t1_wdata[1][63:60] = 4'h6; t1_wdata[1][59] = 1'b0; t1_wdata[1][15:12] = 4'h1;
      t1_wdata[2][63:60] = 4'h5; t1_wdata[2][15:12] = 4'hf;
      t1_wdata[3][63:60] = 4'h6; t1_wdata[3][10:7] = 4'h1;
      can_write_dmode = 4'b0101;
      chainable = 4'b1011;
      dmode_next_trigger = 3'b101;
      clock_and_check();
    end
  endtask

  task automatic random_cycle;
    int i;
    begin
      for (i = 0; i < 4; i++) begin
        t1_wdata[i] = {$urandom, $urandom};
        t2_wdata[i] = {$urandom, $urandom};
      end
      t1_wen = $urandom;
      t2_wen = $urandom;
      can_write_dmode = $urandom;
      chainable = $urandom;
      dmode_next_trigger = $urandom;
      clock_and_check();
    end
  endtask

  initial begin
    int i;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    clear_writes();
    for (i = 0; i < 4; i++) begin
      expected_t1[i] = {4'hf, 60'h0};
      expected_t2[i] = '0;
    end
    expected_t2_valid = '0;

    // Hold reset across a clock edge and verify all resettable tdata1 state.
    reset = 1'b1;
    repeat (2) @(posedge clock);
    #1;
    update_model();
    compare_outputs();
    @(negedge clock);
    reset = 1'b0;

    directed_cycle(64'h0123_4567_89ab_cdef);

    // Verify write-enable hold semantics before entering the long random run.
    t1_wen = '0;
    t2_wen = '0;
    can_write_dmode = 4'b1111;
    chainable = 4'b1111;
    dmode_next_trigger = 3'b111;
    for (i = 0; i < 4; i++) begin
      t1_wdata[i] = {$urandom, $urandom};
      t2_wdata[i] = {$urandom, $urandom};
    end
    clock_and_check();

    repeat (NCYCLES) random_cycle();

    $display("Trigger200c UT: cycles=%0d checks=%0d errors=%0d", cycles, checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
