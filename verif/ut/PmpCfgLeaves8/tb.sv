`timescale 1ns/1ps
module tb;
  localparam integer NLEAVES = 8;
  integer ncycles = 200000;
  integer seed = 1;
  integer errors = 0;
  integer checks = 0;
  integer guard_failures = 0;
  integer k;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'b0;
  wire [7:0] g_rdata [0:NLEAVES-1];
  wire [7:0] i_rdata [0:NLEAVES-1];
  wire g_R [0:NLEAVES-1];
  wire g_W [0:NLEAVES-1];
  wire g_X [0:NLEAVES-1];
  wire [1:0] g_A [0:NLEAVES-1];
  wire g_L [0:NLEAVES-1];
  wire i_R [0:NLEAVES-1];
  wire i_W [0:NLEAVES-1];
  wire i_X [0:NLEAVES-1];
  wire [1:0] i_A [0:NLEAVES-1];
  wire i_L [0:NLEAVES-1];

  Pmp5cfgModule gold5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[0]), .regOut_R(g_R[0]), .regOut_W(g_W[0]), .regOut_X(g_X[0]), .regOut_A(g_A[0]), .regOut_L(g_L[0]));
  Pmp5cfgModule_xs impl5(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[0]), .regOut_R(i_R[0]), .regOut_W(i_W[0]), .regOut_X(i_X[0]), .regOut_A(i_A[0]), .regOut_L(i_L[0]));
  Pmp6cfgModule gold6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[1]), .regOut_R(g_R[1]), .regOut_W(g_W[1]), .regOut_X(g_X[1]), .regOut_A(g_A[1]), .regOut_L(g_L[1]));
  Pmp6cfgModule_xs impl6(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[1]), .regOut_R(i_R[1]), .regOut_W(i_W[1]), .regOut_X(i_X[1]), .regOut_A(i_A[1]), .regOut_L(i_L[1]));
  Pmp7cfgModule gold7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[2]), .regOut_R(g_R[2]), .regOut_W(g_W[2]), .regOut_X(g_X[2]), .regOut_A(g_A[2]), .regOut_L(g_L[2]));
  Pmp7cfgModule_xs impl7(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[2]), .regOut_R(i_R[2]), .regOut_W(i_W[2]), .regOut_X(i_X[2]), .regOut_A(i_A[2]), .regOut_L(i_L[2]));
  Pmp8cfgModule gold8(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[3]), .regOut_R(g_R[3]), .regOut_W(g_W[3]), .regOut_X(g_X[3]), .regOut_A(g_A[3]), .regOut_L(g_L[3]));
  Pmp8cfgModule_xs impl8(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[3]), .regOut_R(i_R[3]), .regOut_W(i_W[3]), .regOut_X(i_X[3]), .regOut_A(i_A[3]), .regOut_L(i_L[3]));
  Pmp9cfgModule gold9(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[4]), .regOut_R(g_R[4]), .regOut_W(g_W[4]), .regOut_X(g_X[4]), .regOut_A(g_A[4]), .regOut_L(g_L[4]));
  Pmp9cfgModule_xs impl9(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[4]), .regOut_R(i_R[4]), .regOut_W(i_W[4]), .regOut_X(i_X[4]), .regOut_A(i_A[4]), .regOut_L(i_L[4]));
  Pmp10cfgModule gold10(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[5]), .regOut_R(g_R[5]), .regOut_W(g_W[5]), .regOut_X(g_X[5]), .regOut_A(g_A[5]), .regOut_L(g_L[5]));
  Pmp10cfgModule_xs impl10(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[5]), .regOut_R(i_R[5]), .regOut_W(i_W[5]), .regOut_X(i_X[5]), .regOut_A(i_A[5]), .regOut_L(i_L[5]));
  Pmp11cfgModule gold11(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[6]), .regOut_R(g_R[6]), .regOut_W(g_W[6]), .regOut_X(g_X[6]), .regOut_A(g_A[6]), .regOut_L(g_L[6]));
  Pmp11cfgModule_xs impl11(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[6]), .regOut_R(i_R[6]), .regOut_W(i_W[6]), .regOut_X(i_X[6]), .regOut_A(i_A[6]), .regOut_L(i_L[6]));
  Pmp12cfgModule gold12(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[7]), .regOut_R(g_R[7]), .regOut_W(g_W[7]), .regOut_X(g_X[7]), .regOut_A(g_A[7]), .regOut_L(g_L[7]));
  Pmp12cfgModule_xs impl12(.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[7]), .regOut_R(i_R[7]), .regOut_W(i_W[7]), .regOut_X(i_X[7]), .regOut_A(i_A[7]), .regOut_L(i_L[7]));

  always #5 clock = ~clock;

  task automatic check_outputs(input integer tag);
    integer j;
    begin
      #1;
      checks = checks + NLEAVES;
      for (j = 0; j < NLEAVES; j = j + 1) begin
        if (g_rdata[j] !== i_rdata[j] || g_R[j] !== i_R[j] ||
            g_W[j] !== i_W[j] || g_X[j] !== i_X[j] ||
            g_A[j] !== i_A[j] || g_L[j] !== i_L[j]) begin
          $display("PmpCfg mismatch tag=%0d leaf=%0d g={r=%h R=%b W=%b X=%b A=%b L=%b} i={r=%h R=%b W=%b X=%b A=%b L=%b}",
                   tag, j, g_rdata[j], g_R[j], g_W[j], g_X[j], g_A[j], g_L[j],
                   i_rdata[j], i_R[j], i_W[j], i_X[j], i_A[j], i_L[j]);
          errors = errors + 1;
        end
        if (^{g_rdata[j], g_R[j], g_W[j], g_X[j], g_A[j], g_L[j]} === 1'bx ||
            ^{i_rdata[j], i_R[j], i_W[j], i_X[j], i_A[j], i_L[j]} === 1'bx) begin
          guard_failures = guard_failures + 1;
          errors = errors + 1;
        end
      end
    end
  endtask

  task automatic apply_write(input logic wen, input logic [63:0] data, input integer tag);
    begin
      @(negedge clock);
      w_wen = wen;
      w_wdata = data;
      @(posedge clock);
      check_outputs(tag);
    end
  endtask

  task automatic random_cycle(input integer tag);
    logic [63:0] data;
    logic wen;
    begin
      data = {$urandom, $urandom};
      wen = ($urandom_range(0, 3) != 0);
      apply_write(wen, data, tag);
    end
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", ncycles));
    // Reuse the harness seed for stimulus as well as VCS initreg entropy.
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($value$plusargs("seed=%d", seed));
    void'($urandom(seed));

    // Asynchronous reset guard: sample several edges while reset is asserted.
    w_wen = 1'b0;
    w_wdata = 64'b0;
    repeat (3) begin
      @(posedge clock);
      check_outputs(-1);
    end
    @(negedge clock);
    reset = 1'b0;

    // Directed encodings cover reset, reserved R=0/W=1, WARL A=2, and lock.
    apply_write(1'b1, 64'h0000_0000_0000_0000, 1);
    apply_write(1'b1, 64'h0000_0000_0000_009f, 2);
    apply_write(1'b1, 64'h0000_0000_0000_0012, 3);
    apply_write(1'b1, 64'h0000_0000_0000_00f7, 4);
    apply_write(1'b0, 64'hffff_ffff_ffff_ffff, 5);
    apply_write(1'b1, 64'h0000_0000_0000_00a5, 6);

    for (k = 0; k < ncycles; k = k + 1)
      random_cycle(k + 100);

    @(negedge clock);
    w_wen = 1'b0;
    w_wdata = 64'b0;
    $display("PmpCfgLeaves8 UT: seed=%0d cycles=%0d checks=%0d errors=%0d guards=%0d",
             seed, ncycles, checks, errors, guard_failures);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
