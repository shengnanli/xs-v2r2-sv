`timescale 1ns/1ps

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
  longint unsigned illegal_a_writes = 0;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'b0;

  wire [7:0]  g_rdata [0:7];
  wire [7:0]  i_rdata [0:7];
  wire        g_R [0:7];
  wire        i_R [0:7];
  wire        g_W [0:7];
  wire        i_W [0:7];
  wire        g_X [0:7];
  wire        i_X [0:7];
  wire [1:0]  g_A [0:7];
  wire [1:0]  i_A [0:7];
  wire        g_ATOMIC [0:7];
  wire        i_ATOMIC [0:7];
  wire        g_C [0:7];
  wire        i_C [0:7];
  wire        g_L [0:7];
  wire        i_L [0:7];

  Pma0cfgModule g0(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[0]), .regOut_R(g_R[0]), .regOut_W(g_W[0]), .regOut_X(g_X[0]), .regOut_A(g_A[0]), .regOut_ATOMIC(g_ATOMIC[0]), .regOut_C(g_C[0]), .regOut_L(g_L[0]));
  Pma1cfgModule g1(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[1]), .regOut_R(g_R[1]), .regOut_W(g_W[1]), .regOut_X(g_X[1]), .regOut_A(g_A[1]), .regOut_ATOMIC(g_ATOMIC[1]), .regOut_C(g_C[1]), .regOut_L(g_L[1]));
  Pma2cfgModule g2(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[2]), .regOut_R(g_R[2]), .regOut_W(g_W[2]), .regOut_X(g_X[2]), .regOut_A(g_A[2]), .regOut_ATOMIC(g_ATOMIC[2]), .regOut_C(g_C[2]), .regOut_L(g_L[2]));
  Pma3cfgModule g3(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[3]), .regOut_R(g_R[3]), .regOut_W(g_W[3]), .regOut_X(g_X[3]), .regOut_A(g_A[3]), .regOut_ATOMIC(g_ATOMIC[3]), .regOut_C(g_C[3]), .regOut_L(g_L[3]));
  Pma4cfgModule g4(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[4]), .regOut_R(g_R[4]), .regOut_W(g_W[4]), .regOut_X(g_X[4]), .regOut_A(g_A[4]), .regOut_ATOMIC(g_ATOMIC[4]), .regOut_C(g_C[4]), .regOut_L(g_L[4]));
  Pma5cfgModule g5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[5]), .regOut_R(g_R[5]), .regOut_W(g_W[5]), .regOut_X(g_X[5]), .regOut_A(g_A[5]), .regOut_ATOMIC(g_ATOMIC[5]), .regOut_C(g_C[5]), .regOut_L(g_L[5]));
  Pma6cfgModule g6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[6]), .regOut_R(g_R[6]), .regOut_W(g_W[6]), .regOut_X(g_X[6]), .regOut_A(g_A[6]), .regOut_ATOMIC(g_ATOMIC[6]), .regOut_C(g_C[6]), .regOut_L(g_L[6]));
  Pma7cfgModule g7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[7]), .regOut_R(g_R[7]), .regOut_W(g_W[7]), .regOut_X(g_X[7]), .regOut_A(g_A[7]), .regOut_ATOMIC(g_ATOMIC[7]), .regOut_C(g_C[7]), .regOut_L(g_L[7]));

  Pma0cfgModule_xs i0(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[0]), .regOut_R(i_R[0]), .regOut_W(i_W[0]), .regOut_X(i_X[0]), .regOut_A(i_A[0]), .regOut_ATOMIC(i_ATOMIC[0]), .regOut_C(i_C[0]), .regOut_L(i_L[0]));
  Pma1cfgModule_xs i1(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[1]), .regOut_R(i_R[1]), .regOut_W(i_W[1]), .regOut_X(i_X[1]), .regOut_A(i_A[1]), .regOut_ATOMIC(i_ATOMIC[1]), .regOut_C(i_C[1]), .regOut_L(i_L[1]));
  Pma2cfgModule_xs i2(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[2]), .regOut_R(i_R[2]), .regOut_W(i_W[2]), .regOut_X(i_X[2]), .regOut_A(i_A[2]), .regOut_ATOMIC(i_ATOMIC[2]), .regOut_C(i_C[2]), .regOut_L(i_L[2]));
  Pma3cfgModule_xs i3(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[3]), .regOut_R(i_R[3]), .regOut_W(i_W[3]), .regOut_X(i_X[3]), .regOut_A(i_A[3]), .regOut_ATOMIC(i_ATOMIC[3]), .regOut_C(i_C[3]), .regOut_L(i_L[3]));
  Pma4cfgModule_xs i4(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[4]), .regOut_R(i_R[4]), .regOut_W(i_W[4]), .regOut_X(i_X[4]), .regOut_A(i_A[4]), .regOut_ATOMIC(i_ATOMIC[4]), .regOut_C(i_C[4]), .regOut_L(i_L[4]));
  Pma5cfgModule_xs i5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[5]), .regOut_R(i_R[5]), .regOut_W(i_W[5]), .regOut_X(i_X[5]), .regOut_A(i_A[5]), .regOut_ATOMIC(i_ATOMIC[5]), .regOut_C(i_C[5]), .regOut_L(i_L[5]));
  Pma6cfgModule_xs i6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[6]), .regOut_R(i_R[6]), .regOut_W(i_W[6]), .regOut_X(i_X[6]), .regOut_A(i_A[6]), .regOut_ATOMIC(i_ATOMIC[6]), .regOut_C(i_C[6]), .regOut_L(i_L[6]));
  Pma7cfgModule_xs i7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[7]), .regOut_R(i_R[7]), .regOut_W(i_W[7]), .regOut_X(i_X[7]), .regOut_A(i_A[7]), .regOut_ATOMIC(i_ATOMIC[7]), .regOut_C(i_C[7]), .regOut_L(i_L[7]));

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
        if (g_rdata[slot] !== i_rdata[slot]) errors++;
        if (g_R[slot] !== i_R[slot]) errors++;
        if (g_W[slot] !== i_W[slot]) errors++;
        if (g_X[slot] !== i_X[slot]) errors++;
        if (g_A[slot] !== i_A[slot]) errors++;
        if (g_ATOMIC[slot] !== i_ATOMIC[slot]) errors++;
        if (g_C[slot] !== i_C[slot]) errors++;
        if (g_L[slot] !== i_L[slot]) errors++;
        if (slot == 0) begin
          seen_zero |= ~g_rdata[slot];
          seen_one  |= g_rdata[slot];
          seen_a[g_A[slot]] = 1'b1;
          if (have_previous && g_rdata[slot] !== previous_rdata)
            toggle_events++;
          previous_rdata = g_rdata[slot];
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
        w_wdata = 64'h0000_0000_0000_0018; // illegal A=3: WARL must retain A=2
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
        illegal_a_writes++;
      else if (w_wen)
        legal_a_writes++;
    end
  endtask

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($urandom(seed));
    if (!$value$plusargs("ncycles=%d", ncycles))
      ncycles = 200000;

    // Hold reset across clock edges, then sample the reset state before writes.
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

    $display("PmaCfgLeaves8 UT: seed=%0d checks=%0d errors=%0d fire=%0d no_fire=%0d toggles=%0d legal_A=%0d illegal_A=%0d seen_zero=%b seen_one=%b seen_A=%b",
             seed, checks, errors, fire_count, no_fire_count, toggle_events,
             legal_a_writes, illegal_a_writes, seen_zero, seen_one, seen_a);
    if (fire_count == 0 || no_fire_count == 0) begin
      $display("COVERAGE HOLE: fire/no-fire guard failed");
      errors++;
    end
    if (toggle_events == 0 || seen_zero != 8'hff || seen_one != 8'hff) begin
      $display("COVERAGE HOLE: output toggle guard failed");
      errors++;
    end
    if (legal_a_writes == 0 || illegal_a_writes == 0 || seen_a != 4'b1111) begin
      $display("COVERAGE HOLE: WARL encoding guard failed");
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
