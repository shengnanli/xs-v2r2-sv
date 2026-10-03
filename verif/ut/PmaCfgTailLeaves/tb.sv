`timescale 1ns/1ps

// Differential UT for the disjoint PMA16..31 CSR tail family.  Every golden
// leaf and its derived _xs wrapper receives the same transaction stream; all
// packed and decoded outputs are compared after each clock edge.
module tb;
  localparam int NVAR = 16;
  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int unsigned cycle;
  int errors = 0;
  longint unsigned checks = 0;
  longint unsigned fires = 0;
  longint unsigned no_fires = 0;
  longint unsigned a2_writes = 0;
  longint unsigned a3_writes = 0;
  longint unsigned toggles = 0;

  logic clock = 1'b0;
  // Start reset low so the asynchronous reset edge at time 1 initializes both sides.
  logic reset = 1'b0;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'b0;

  wire [7:0] g_rdata [0:NVAR-1];
  wire [7:0] i_rdata [0:NVAR-1];
  wire g_R [0:NVAR-1], i_R [0:NVAR-1];
  wire g_W [0:NVAR-1], i_W [0:NVAR-1];
  wire g_X [0:NVAR-1], i_X [0:NVAR-1];
  wire [1:0] g_A [0:NVAR-1], i_A [0:NVAR-1];
  wire g_ATOMIC [0:NVAR-1], i_ATOMIC [0:NVAR-1];
  wire g_C [0:NVAR-1], i_C [0:NVAR-1];
  wire g_L [0:NVAR-1], i_L [0:NVAR-1];
  wire [15:0] golden_state [0:NVAR-1];
  logic [15:0] previous_state [0:NVAR-1];
  bit have_previous;
  bit [NVAR*16-1:0] toggled;

  Pma16cfgModule g0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[0]), .regOut_R(g_R[0]), .regOut_W(g_W[0]), .regOut_X(g_X[0]), .regOut_A(g_A[0]), .regOut_ATOMIC(g_ATOMIC[0]), .regOut_C(g_C[0]), .regOut_L(g_L[0]));
  Pma17cfgModule g1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[1]), .regOut_R(g_R[1]), .regOut_W(g_W[1]), .regOut_X(g_X[1]), .regOut_A(g_A[1]), .regOut_ATOMIC(g_ATOMIC[1]), .regOut_C(g_C[1]), .regOut_L(g_L[1]));
  Pma18cfgModule g2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[2]), .regOut_R(g_R[2]), .regOut_W(g_W[2]), .regOut_X(g_X[2]), .regOut_A(g_A[2]), .regOut_ATOMIC(g_ATOMIC[2]), .regOut_C(g_C[2]), .regOut_L(g_L[2]));
  Pma19cfgModule g3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[3]), .regOut_R(g_R[3]), .regOut_W(g_W[3]), .regOut_X(g_X[3]), .regOut_A(g_A[3]), .regOut_ATOMIC(g_ATOMIC[3]), .regOut_C(g_C[3]), .regOut_L(g_L[3]));
  Pma20cfgModule g4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[4]), .regOut_R(g_R[4]), .regOut_W(g_W[4]), .regOut_X(g_X[4]), .regOut_A(g_A[4]), .regOut_ATOMIC(g_ATOMIC[4]), .regOut_C(g_C[4]), .regOut_L(g_L[4]));
  Pma21cfgModule g5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[5]), .regOut_R(g_R[5]), .regOut_W(g_W[5]), .regOut_X(g_X[5]), .regOut_A(g_A[5]), .regOut_ATOMIC(g_ATOMIC[5]), .regOut_C(g_C[5]), .regOut_L(g_L[5]));
  Pma22cfgModule g6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[6]), .regOut_R(g_R[6]), .regOut_W(g_W[6]), .regOut_X(g_X[6]), .regOut_A(g_A[6]), .regOut_ATOMIC(g_ATOMIC[6]), .regOut_C(g_C[6]), .regOut_L(g_L[6]));
  Pma23cfgModule g7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[7]), .regOut_R(g_R[7]), .regOut_W(g_W[7]), .regOut_X(g_X[7]), .regOut_A(g_A[7]), .regOut_ATOMIC(g_ATOMIC[7]), .regOut_C(g_C[7]), .regOut_L(g_L[7]));
  Pma24cfgModule g8 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[8]), .regOut_R(g_R[8]), .regOut_W(g_W[8]), .regOut_X(g_X[8]), .regOut_A(g_A[8]), .regOut_ATOMIC(g_ATOMIC[8]), .regOut_C(g_C[8]), .regOut_L(g_L[8]));
  Pma25cfgModule g9 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[9]), .regOut_R(g_R[9]), .regOut_W(g_W[9]), .regOut_X(g_X[9]), .regOut_A(g_A[9]), .regOut_ATOMIC(g_ATOMIC[9]), .regOut_C(g_C[9]), .regOut_L(g_L[9]));
  Pma26cfgModule g10 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[10]), .regOut_R(g_R[10]), .regOut_W(g_W[10]), .regOut_X(g_X[10]), .regOut_A(g_A[10]), .regOut_ATOMIC(g_ATOMIC[10]), .regOut_C(g_C[10]), .regOut_L(g_L[10]));
  Pma27cfgModule g11 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[11]), .regOut_R(g_R[11]), .regOut_W(g_W[11]), .regOut_X(g_X[11]), .regOut_A(g_A[11]), .regOut_ATOMIC(g_ATOMIC[11]), .regOut_C(g_C[11]), .regOut_L(g_L[11]));
  Pma28cfgModule g12 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[12]), .regOut_R(g_R[12]), .regOut_W(g_W[12]), .regOut_X(g_X[12]), .regOut_A(g_A[12]), .regOut_ATOMIC(g_ATOMIC[12]), .regOut_C(g_C[12]), .regOut_L(g_L[12]));
  Pma29cfgModule g13 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[13]), .regOut_R(g_R[13]), .regOut_W(g_W[13]), .regOut_X(g_X[13]), .regOut_A(g_A[13]), .regOut_ATOMIC(g_ATOMIC[13]), .regOut_C(g_C[13]), .regOut_L(g_L[13]));
  Pma30cfgModule g14 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[14]), .regOut_R(g_R[14]), .regOut_W(g_W[14]), .regOut_X(g_X[14]), .regOut_A(g_A[14]), .regOut_ATOMIC(g_ATOMIC[14]), .regOut_C(g_C[14]), .regOut_L(g_L[14]));
  Pma31cfgModule g15 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[15]), .regOut_R(g_R[15]), .regOut_W(g_W[15]), .regOut_X(g_X[15]), .regOut_A(g_A[15]), .regOut_ATOMIC(g_ATOMIC[15]), .regOut_C(g_C[15]), .regOut_L(g_L[15]));
  Pma16cfgModule_xs i0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[0]), .regOut_R(i_R[0]), .regOut_W(i_W[0]), .regOut_X(i_X[0]), .regOut_A(i_A[0]), .regOut_ATOMIC(i_ATOMIC[0]), .regOut_C(i_C[0]), .regOut_L(i_L[0]));
  Pma17cfgModule_xs i1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[1]), .regOut_R(i_R[1]), .regOut_W(i_W[1]), .regOut_X(i_X[1]), .regOut_A(i_A[1]), .regOut_ATOMIC(i_ATOMIC[1]), .regOut_C(i_C[1]), .regOut_L(i_L[1]));
  Pma18cfgModule_xs i2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[2]), .regOut_R(i_R[2]), .regOut_W(i_W[2]), .regOut_X(i_X[2]), .regOut_A(i_A[2]), .regOut_ATOMIC(i_ATOMIC[2]), .regOut_C(i_C[2]), .regOut_L(i_L[2]));
  Pma19cfgModule_xs i3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[3]), .regOut_R(i_R[3]), .regOut_W(i_W[3]), .regOut_X(i_X[3]), .regOut_A(i_A[3]), .regOut_ATOMIC(i_ATOMIC[3]), .regOut_C(i_C[3]), .regOut_L(i_L[3]));
  Pma20cfgModule_xs i4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[4]), .regOut_R(i_R[4]), .regOut_W(i_W[4]), .regOut_X(i_X[4]), .regOut_A(i_A[4]), .regOut_ATOMIC(i_ATOMIC[4]), .regOut_C(i_C[4]), .regOut_L(i_L[4]));
  Pma21cfgModule_xs i5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[5]), .regOut_R(i_R[5]), .regOut_W(i_W[5]), .regOut_X(i_X[5]), .regOut_A(i_A[5]), .regOut_ATOMIC(i_ATOMIC[5]), .regOut_C(i_C[5]), .regOut_L(i_L[5]));
  Pma22cfgModule_xs i6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[6]), .regOut_R(i_R[6]), .regOut_W(i_W[6]), .regOut_X(i_X[6]), .regOut_A(i_A[6]), .regOut_ATOMIC(i_ATOMIC[6]), .regOut_C(i_C[6]), .regOut_L(i_L[6]));
  Pma23cfgModule_xs i7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[7]), .regOut_R(i_R[7]), .regOut_W(i_W[7]), .regOut_X(i_X[7]), .regOut_A(i_A[7]), .regOut_ATOMIC(i_ATOMIC[7]), .regOut_C(i_C[7]), .regOut_L(i_L[7]));
  Pma24cfgModule_xs i8 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[8]), .regOut_R(i_R[8]), .regOut_W(i_W[8]), .regOut_X(i_X[8]), .regOut_A(i_A[8]), .regOut_ATOMIC(i_ATOMIC[8]), .regOut_C(i_C[8]), .regOut_L(i_L[8]));
  Pma25cfgModule_xs i9 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[9]), .regOut_R(i_R[9]), .regOut_W(i_W[9]), .regOut_X(i_X[9]), .regOut_A(i_A[9]), .regOut_ATOMIC(i_ATOMIC[9]), .regOut_C(i_C[9]), .regOut_L(i_L[9]));
  Pma26cfgModule_xs i10 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[10]), .regOut_R(i_R[10]), .regOut_W(i_W[10]), .regOut_X(i_X[10]), .regOut_A(i_A[10]), .regOut_ATOMIC(i_ATOMIC[10]), .regOut_C(i_C[10]), .regOut_L(i_L[10]));
  Pma27cfgModule_xs i11 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[11]), .regOut_R(i_R[11]), .regOut_W(i_W[11]), .regOut_X(i_X[11]), .regOut_A(i_A[11]), .regOut_ATOMIC(i_ATOMIC[11]), .regOut_C(i_C[11]), .regOut_L(i_L[11]));
  Pma28cfgModule_xs i12 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[12]), .regOut_R(i_R[12]), .regOut_W(i_W[12]), .regOut_X(i_X[12]), .regOut_A(i_A[12]), .regOut_ATOMIC(i_ATOMIC[12]), .regOut_C(i_C[12]), .regOut_L(i_L[12]));
  Pma29cfgModule_xs i13 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[13]), .regOut_R(i_R[13]), .regOut_W(i_W[13]), .regOut_X(i_X[13]), .regOut_A(i_A[13]), .regOut_ATOMIC(i_ATOMIC[13]), .regOut_C(i_C[13]), .regOut_L(i_L[13]));
  Pma30cfgModule_xs i14 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[14]), .regOut_R(i_R[14]), .regOut_W(i_W[14]), .regOut_X(i_X[14]), .regOut_A(i_A[14]), .regOut_ATOMIC(i_ATOMIC[14]), .regOut_C(i_C[14]), .regOut_L(i_L[14]));
  Pma31cfgModule_xs i15 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[15]), .regOut_R(i_R[15]), .regOut_W(i_W[15]), .regOut_X(i_X[15]), .regOut_A(i_A[15]), .regOut_ATOMIC(i_ATOMIC[15]), .regOut_C(i_C[15]), .regOut_L(i_L[15]));

  for (genvar v = 0; v < NVAR; v = v + 1) begin : packed_outputs
    assign golden_state[v] = {g_rdata[v], g_R[v], g_W[v], g_X[v], g_A[v],
                              g_ATOMIC[v], g_C[v], g_L[v]};
  end

  always #5 clock = ~clock;

  task automatic compare_outputs;
    integer slot;
    begin
      #1;
      for (slot = 0; slot < NVAR; slot = slot + 1) begin
        checks = checks + 1;
        if (g_rdata[slot] !== i_rdata[slot]) errors = errors + 1;
        if (g_R[slot] !== i_R[slot]) errors = errors + 1;
        if (g_W[slot] !== i_W[slot]) errors = errors + 1;
        if (g_X[slot] !== i_X[slot]) errors = errors + 1;
        if (g_A[slot] !== i_A[slot]) errors = errors + 1;
        if (g_ATOMIC[slot] !== i_ATOMIC[slot]) errors = errors + 1;
        if (g_C[slot] !== i_C[slot]) errors = errors + 1;
        if (g_L[slot] !== i_L[slot]) errors = errors + 1;
        if (have_previous) begin
          if (golden_state[slot] != previous_state[slot]) toggles = toggles + 1;
          for (int bit_index = 0; bit_index < 16; bit_index = bit_index + 1)
            if (golden_state[slot][bit_index] != previous_state[slot][bit_index])
              toggled[slot * 16 + bit_index] = 1'b1;
        end
        previous_state[slot] = golden_state[slot];
      end
      have_previous = 1'b1;
    end
  endtask

  task automatic drive(input int unsigned index);
    begin
      if (index == 0) begin w_wen = 1'b0; w_wdata = 64'h0; end
      else if (index == 1) begin w_wen = 1'b1; w_wdata = 64'h0000_0000_0000_00e7; end
      else if (index == 2) begin w_wen = 1'b1; w_wdata = 64'h0000_0000_0000_0008; end
      else if (index == 3) begin w_wen = 1'b1; w_wdata = 64'h0000_0000_0000_0010; end
      else if (index == 4) begin w_wen = 1'b1; w_wdata = 64'h0000_0000_0000_0018; end
      else if (index == 5) begin w_wen = 1'b0; w_wdata = 64'hffff_ffff_ffff_ffff; end
      else begin
        w_wen = (($urandom_range(0, 99)) < 73);
        w_wdata = {$urandom, $urandom};
      end
      if (w_wen) begin
        fires = fires + 1;
        if (w_wdata[4:3] == 2'd2) a2_writes = a2_writes + 1;
        if (w_wdata[4:3] == 2'd3) a3_writes = a3_writes + 1;
      end else no_fires = no_fires + 1;
    end
  endtask

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($value$plusargs("ncycles=%d", ncycles));
    void'($urandom(seed));
    reset = 1'b0;
    w_wen = 1'b0;
    w_wdata = 64'b0;
    #1 reset = 1'b1;
    repeat (3) @(posedge clock);
    compare_outputs();
    @(negedge clock);
    reset = 1'b0;
    for (cycle = 0; cycle < ncycles; cycle = cycle + 1) begin
      @(negedge clock);
      drive(cycle);
      @(posedge clock);
      compare_outputs();
    end
    for (int slot = 0; slot < NVAR; slot = slot + 1) begin
      if (g_rdata[slot] === 8'h00) ;
    end
    $display("PmaCfgTailLeaves seed=%0d checks=%0d errors=%0d fires=%0d no_fires=%0d A2=%0d A3=%0d toggles=%0d", seed, checks, errors, fires, no_fires, a2_writes, a3_writes, toggles);
    if (fires == 0 || no_fires == 0 || a2_writes == 0 || a3_writes == 0) begin
      $display("COVERAGE HOLE: write/WARL guard failed");
      errors = errors + 1;
    end
    if (toggled !== {NVAR*16{1'b1}}) begin
      $display("COVERAGE HOLE: state-bit toggle guard failed mask=%h", toggled);
      errors = errors + 1;
    end
    if (checks < NVAR * (ncycles + 1)) begin
      $display("COVERAGE HOLE: comparison count too small");
      errors = errors + 1;
    end
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
