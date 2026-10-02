`timescale 1ns/1ps

// Differential test for the eight PMA CSR leaves.  The golden instances and
// generated _xs instances receive the same negedge-driven transaction stream.
module tb;
  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int unsigned cycle;
  int errors = 0;
  longint unsigned checks = 0;
  longint unsigned fire_count = 0;
  longint unsigned no_fire_count = 0;
  longint unsigned toggle_events = 0;
  longint unsigned legal_a_writes = 0;
  longint unsigned a_three_writes = 0;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'b0;

  wire [7:0]  golden_rdata [0:7];
  wire [7:0]  impl_rdata   [0:7];
  wire        golden_R [0:7];
  wire        impl_R   [0:7];
  wire        golden_W [0:7];
  wire        impl_W   [0:7];
  wire        golden_X [0:7];
  wire        impl_X   [0:7];
  wire [1:0]  golden_A [0:7];
  wire [1:0]  impl_A   [0:7];
  wire        golden_ATOMIC [0:7];
  wire        impl_ATOMIC   [0:7];
  wire        golden_C [0:7];
  wire        impl_C   [0:7];
  wire        golden_L [0:7];
  wire        impl_L   [0:7];

  Pma8cfgModule  g0(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[0]), .regOut_R(golden_R[0]), .regOut_W(golden_W[0]), .regOut_X(golden_X[0]), .regOut_A(golden_A[0]), .regOut_ATOMIC(golden_ATOMIC[0]), .regOut_C(golden_C[0]), .regOut_L(golden_L[0]));
  Pma9cfgModule  g1(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[1]), .regOut_R(golden_R[1]), .regOut_W(golden_W[1]), .regOut_X(golden_X[1]), .regOut_A(golden_A[1]), .regOut_ATOMIC(golden_ATOMIC[1]), .regOut_C(golden_C[1]), .regOut_L(golden_L[1]));
  Pma10cfgModule g2(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[2]), .regOut_R(golden_R[2]), .regOut_W(golden_W[2]), .regOut_X(golden_X[2]), .regOut_A(golden_A[2]), .regOut_ATOMIC(golden_ATOMIC[2]), .regOut_C(golden_C[2]), .regOut_L(golden_L[2]));
  Pma11cfgModule g3(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[3]), .regOut_R(golden_R[3]), .regOut_W(golden_W[3]), .regOut_X(golden_X[3]), .regOut_A(golden_A[3]), .regOut_ATOMIC(golden_ATOMIC[3]), .regOut_C(golden_C[3]), .regOut_L(golden_L[3]));
  Pma12cfgModule g4(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[4]), .regOut_R(golden_R[4]), .regOut_W(golden_W[4]), .regOut_X(golden_X[4]), .regOut_A(golden_A[4]), .regOut_ATOMIC(golden_ATOMIC[4]), .regOut_C(golden_C[4]), .regOut_L(golden_L[4]));
  Pma13cfgModule g5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[5]), .regOut_R(golden_R[5]), .regOut_W(golden_W[5]), .regOut_X(golden_X[5]), .regOut_A(golden_A[5]), .regOut_ATOMIC(golden_ATOMIC[5]), .regOut_C(golden_C[5]), .regOut_L(golden_L[5]));
  Pma14cfgModule g6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[6]), .regOut_R(golden_R[6]), .regOut_W(golden_W[6]), .regOut_X(golden_X[6]), .regOut_A(golden_A[6]), .regOut_ATOMIC(golden_ATOMIC[6]), .regOut_C(golden_C[6]), .regOut_L(golden_L[6]));
  Pma15cfgModule g7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(golden_rdata[7]), .regOut_R(golden_R[7]), .regOut_W(golden_W[7]), .regOut_X(golden_X[7]), .regOut_A(golden_A[7]), .regOut_ATOMIC(golden_ATOMIC[7]), .regOut_C(golden_C[7]), .regOut_L(golden_L[7]));

  Pma8cfgModule_xs  i0(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[0]), .regOut_R(impl_R[0]), .regOut_W(impl_W[0]), .regOut_X(impl_X[0]), .regOut_A(impl_A[0]), .regOut_ATOMIC(impl_ATOMIC[0]), .regOut_C(impl_C[0]), .regOut_L(impl_L[0]));
  Pma9cfgModule_xs  i1(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[1]), .regOut_R(impl_R[1]), .regOut_W(impl_W[1]), .regOut_X(impl_X[1]), .regOut_A(impl_A[1]), .regOut_ATOMIC(impl_ATOMIC[1]), .regOut_C(impl_C[1]), .regOut_L(impl_L[1]));
  Pma10cfgModule_xs i2(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[2]), .regOut_R(impl_R[2]), .regOut_W(impl_W[2]), .regOut_X(impl_X[2]), .regOut_A(impl_A[2]), .regOut_ATOMIC(impl_ATOMIC[2]), .regOut_C(impl_C[2]), .regOut_L(impl_L[2]));
  Pma11cfgModule_xs i3(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[3]), .regOut_R(impl_R[3]), .regOut_W(impl_W[3]), .regOut_X(impl_X[3]), .regOut_A(impl_A[3]), .regOut_ATOMIC(impl_ATOMIC[3]), .regOut_C(impl_C[3]), .regOut_L(impl_L[3]));
  Pma12cfgModule_xs i4(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[4]), .regOut_R(impl_R[4]), .regOut_W(impl_W[4]), .regOut_X(impl_X[4]), .regOut_A(impl_A[4]), .regOut_ATOMIC(impl_ATOMIC[4]), .regOut_C(impl_C[4]), .regOut_L(impl_L[4]));
  Pma13cfgModule_xs i5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[5]), .regOut_R(impl_R[5]), .regOut_W(impl_W[5]), .regOut_X(impl_X[5]), .regOut_A(impl_A[5]), .regOut_ATOMIC(impl_ATOMIC[5]), .regOut_C(impl_C[5]), .regOut_L(impl_L[5]));
  Pma14cfgModule_xs i6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[6]), .regOut_R(impl_R[6]), .regOut_W(impl_W[6]), .regOut_X(impl_X[6]), .regOut_A(impl_A[6]), .regOut_ATOMIC(impl_ATOMIC[6]), .regOut_C(impl_C[6]), .regOut_L(impl_L[6]));
  Pma15cfgModule_xs i7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(impl_rdata[7]), .regOut_R(impl_R[7]), .regOut_W(impl_W[7]), .regOut_X(impl_X[7]), .regOut_A(impl_A[7]), .regOut_ATOMIC(impl_ATOMIC[7]), .regOut_C(impl_C[7]), .regOut_L(impl_L[7]));

  bit have_previous;
  logic [7:0] previous_rdata;
  logic [7:0] seen_zero;
  logic [7:0] seen_one;
  bit [3:0] seen_a;

  always #5 clock = ~clock;

  task automatic compare_outputs;
    integer slot;
    begin
      #1;
      for (slot = 0; slot < 8; slot = slot + 1) begin
        checks++;
        if (golden_rdata[slot] !== impl_rdata[slot]) errors++;
        if (golden_R[slot] !== impl_R[slot]) errors++;
        if (golden_W[slot] !== impl_W[slot]) errors++;
        if (golden_X[slot] !== impl_X[slot]) errors++;
        if (golden_A[slot] !== impl_A[slot]) errors++;
        if (golden_ATOMIC[slot] !== impl_ATOMIC[slot]) errors++;
        if (golden_C[slot] !== impl_C[slot]) errors++;
        if (golden_L[slot] !== impl_L[slot]) errors++;
        if (slot == 0) begin
          seen_zero |= ~golden_rdata[slot];
          seen_one  |= golden_rdata[slot];
          seen_a[golden_A[slot]] = 1'b1;
          if (have_previous && golden_rdata[slot] !== previous_rdata)
            toggle_events++;
          previous_rdata = golden_rdata[slot];
        end
      end
      have_previous = 1'b1;
    end
  endtask

  task automatic drive_vector(input integer index);
    integer pattern;
    begin
      pattern = index;
      if (pattern == 0) begin
        w_wen = 1'b0;
        w_wdata = 64'h0;
      end else if (pattern == 1) begin
        w_wen = 1'b1;
        w_wdata = 64'h0000_0000_0000_00e7; // A=0, all other writable bits set
      end else if (pattern == 2) begin
        w_wen = 1'b1;
        w_wdata = 64'h0000_0000_0000_0008; // A=1, clear the other fields
      end else if (pattern == 3) begin
        w_wen = 1'b1;
        w_wdata = 64'h0000_0000_0000_0010; // A=2, clear the other fields
      end else if (pattern == 4) begin
        w_wen = 1'b1;
        w_wdata = 64'h0000_0000_0000_0018; // A=3, the fourth legal encoding
      end else if (pattern == 5) begin
        w_wen = 1'b0;
        w_wdata = 64'hffff_ffff_ffff_ffff;
      end else begin
        w_wen = ($urandom_range(0, 99) < 72);
        w_wdata = {$urandom, $urandom};
      end
      if (w_wen)
        fire_count++;
      else
        no_fire_count++;
      if (w_wen && (w_wdata[4:3] == 2'h3))
        a_three_writes++;
      else if (w_wen)
        legal_a_writes++;
    end
  endtask

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($urandom(seed));
    if (!$value$plusargs("ncycles=%d", ncycles))
      ncycles = 200000;

    repeat (2) @(negedge clock);
    reset = 1'b0;
    @(negedge clock);
    compare_outputs();

    for (cycle = 0; cycle < ncycles; cycle = cycle + 1) begin
      @(negedge clock);
      drive_vector(cycle + 1);
      @(negedge clock);
      compare_outputs();
    end

    $display("PmaCfgLeaves8b UT: seed=%0d checks=%0d errors=%0d fire=%0d no_fire=%0d toggles=%0d legal_A=%0d A3_writes=%0d seen_zero=%b seen_one=%b seen_A=%b",
             seed, checks, errors, fire_count, no_fire_count, toggle_events,
             legal_a_writes, a_three_writes, seen_zero, seen_one, seen_a);
    if (fire_count == 0 || no_fire_count == 0) begin
      $display("COVERAGE HOLE: fire/no-fire guard failed");
      errors++;
    end
    if (toggle_events == 0 || seen_zero != 8'hff || seen_one != 8'hff) begin
      $display("COVERAGE HOLE: output toggle guard failed");
      errors++;
    end
    if (legal_a_writes == 0 || a_three_writes == 0 || seen_a != 4'b1111) begin
      $display("COVERAGE HOLE: A encoding guard failed");
      errors++;
    end
    if (checks < 8 * (ncycles + 1)) begin
      $display("COVERAGE HOLE: check guard failed checks=%0d expected_at_least=%0d", checks, 8 * (ncycles + 1));
      errors++;
    end
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
