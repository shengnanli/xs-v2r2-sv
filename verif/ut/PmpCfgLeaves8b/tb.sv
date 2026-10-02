// PmpCfgLeaves8b differential UT: eight childless NewCSR PMP leaves.
// Golden and derived _xs wrappers receive identical writes.  Stimulus is driven
// only on negedge clock, then every output is compared after the following edge.
// The directed prefix covers reset, A=2 WARL conversion, reserved R/W, L writes,
// disabled writes, and full-width payloads; random traffic supplies long-run mix.
`timescale 1ns/1ps
module tb;
  localparam int NVAR = 8;
  localparam int NSIG = 6;
  localparam int DIRECTED = 16;
  localparam longint MIN_FIRES = 10000;
  localparam longint MIN_WARL_A2 = 1000;
  localparam longint MIN_W_RES = 1000;
  localparam longint MIN_L_REWRITE = 1000;

  int unsigned ncycles = 200000;
  bit clock = 1'b0;
  bit reset;
  always #5 clock = ~clock;

  logic w_wen;
  logic [63:0] w_wdata;
  longint checks = 0;
  longint errors = 0;
  longint fires = 0;
  longint warl_a2 = 0;
  longint reserved_writes = 0;
  longint lock_rewrites = 0;

  wire [7:0] g_rdata [NVAR];
  wire       g_r [NVAR], g_w [NVAR], g_x [NVAR], g_l [NVAR];
  wire [1:0] g_a [NVAR];
  wire [7:0] i_rdata [NVAR];
  wire       i_r [NVAR], i_w [NVAR], i_x [NVAR], i_l [NVAR];
  wire [1:0] i_a [NVAR];

  Pmp13cfgModule u_g0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[0]), .regOut_R(g_r[0]), .regOut_W(g_w[0]), .regOut_X(g_x[0]), .regOut_A(g_a[0]), .regOut_L(g_l[0]));
  Pmp14cfgModule u_g1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[1]), .regOut_R(g_r[1]), .regOut_W(g_w[1]), .regOut_X(g_x[1]), .regOut_A(g_a[1]), .regOut_L(g_l[1]));
  Pmp15cfgModule u_g2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[2]), .regOut_R(g_r[2]), .regOut_W(g_w[2]), .regOut_X(g_x[2]), .regOut_A(g_a[2]), .regOut_L(g_l[2]));
  Pmp16cfgModule u_g3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[3]), .regOut_R(g_r[3]), .regOut_W(g_w[3]), .regOut_X(g_x[3]), .regOut_A(g_a[3]), .regOut_L(g_l[3]));
  Pmp17cfgModule u_g4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[4]), .regOut_R(g_r[4]), .regOut_W(g_w[4]), .regOut_X(g_x[4]), .regOut_A(g_a[4]), .regOut_L(g_l[4]));
  Pmp18cfgModule u_g5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[5]), .regOut_R(g_r[5]), .regOut_W(g_w[5]), .regOut_X(g_x[5]), .regOut_A(g_a[5]), .regOut_L(g_l[5]));
  Pmp19cfgModule u_g6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[6]), .regOut_R(g_r[6]), .regOut_W(g_w[6]), .regOut_X(g_x[6]), .regOut_A(g_a[6]), .regOut_L(g_l[6]));
  Pmp20cfgModule u_g7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(g_rdata[7]), .regOut_R(g_r[7]), .regOut_W(g_w[7]), .regOut_X(g_x[7]), .regOut_A(g_a[7]), .regOut_L(g_l[7]));
  Pmp13cfgModule_xs u_i0 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[0]), .regOut_R(i_r[0]), .regOut_W(i_w[0]), .regOut_X(i_x[0]), .regOut_A(i_a[0]), .regOut_L(i_l[0]));
  Pmp14cfgModule_xs u_i1 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[1]), .regOut_R(i_r[1]), .regOut_W(i_w[1]), .regOut_X(i_x[1]), .regOut_A(i_a[1]), .regOut_L(i_l[1]));
  Pmp15cfgModule_xs u_i2 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[2]), .regOut_R(i_r[2]), .regOut_W(i_w[2]), .regOut_X(i_x[2]), .regOut_A(i_a[2]), .regOut_L(i_l[2]));
  Pmp16cfgModule_xs u_i3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[3]), .regOut_R(i_r[3]), .regOut_W(i_w[3]), .regOut_X(i_x[3]), .regOut_A(i_a[3]), .regOut_L(i_l[3]));
  Pmp17cfgModule_xs u_i4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[4]), .regOut_R(i_r[4]), .regOut_W(i_w[4]), .regOut_X(i_x[4]), .regOut_A(i_a[4]), .regOut_L(i_l[4]));
  Pmp18cfgModule_xs u_i5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[5]), .regOut_R(i_r[5]), .regOut_W(i_w[5]), .regOut_X(i_x[5]), .regOut_A(i_a[5]), .regOut_L(i_l[5]));
  Pmp19cfgModule_xs u_i6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[6]), .regOut_R(i_r[6]), .regOut_W(i_w[6]), .regOut_X(i_x[6]), .regOut_A(i_a[6]), .regOut_L(i_l[6]));
  Pmp20cfgModule_xs u_i7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(i_rdata[7]), .regOut_R(i_r[7]), .regOut_W(i_w[7]), .regOut_X(i_x[7]), .regOut_A(i_a[7]), .regOut_L(i_l[7]));

  wire [13:0] g_pack [NVAR];
  wire [13:0] i_pack [NVAR];
  for (genvar v = 0; v < NVAR; v++) begin : pack_outputs
    assign g_pack[v] = {g_rdata[v], g_l[v], g_a[v], g_x[v], g_w[v], g_r[v]};
    assign i_pack[v] = {i_rdata[v], i_l[v], i_a[v], i_x[v], i_w[v], i_r[v]};
  end

  logic [13:0] previous [NVAR];
  bit [NVAR*NSIG-1:0] toggled;

  task automatic compare_outputs();
    for (int v = 0; v < NVAR; v++) begin
      if (!$isunknown(g_pack[v])) begin
        checks++;
        if (g_pack[v] !== i_pack[v]) begin
          errors++;
          if (errors <= 20)
            $display("[%0t] mismatch variant=%0d golden=%h impl=%h", $time, v, g_pack[v], i_pack[v]);
        end
      end
    end
  endtask

  task automatic sample_coverage();
    for (int v = 0; v < NVAR; v++) begin
      if (g_pack[v][13:6] !== previous[v][13:6]) toggled[v*NSIG+0] = 1'b1;
      if (g_pack[v][5] !== previous[v][5]) toggled[v*NSIG+1] = 1'b1;
      if (g_pack[v][4:3] !== previous[v][4:3]) toggled[v*NSIG+2] = 1'b1;
      if (g_pack[v][2] !== previous[v][2]) toggled[v*NSIG+3] = 1'b1;
      if (g_pack[v][1] !== previous[v][1]) toggled[v*NSIG+4] = 1'b1;
      if (g_pack[v][0] !== previous[v][0]) toggled[v*NSIG+5] = 1'b1;
      previous[v] = g_pack[v];
    end
    if (w_wen) begin
      fires++;
      if (w_wdata[4:3] == 2'd2) warl_a2++;
      if (!w_wdata[0] && w_wdata[1]) reserved_writes++;
      if (g_l[0]) lock_rewrites++;
    end
  endtask

  task automatic drive_directed(input int unsigned index);
    w_wen = 1'b1;
    w_wdata = 64'h0;
    case (index)
      0: w_wdata[7:0] = 8'h00;
      1: w_wdata[4:3] = 2'd0;
      2: w_wdata[4:3] = 2'd1;
      3: w_wdata[4:3] = 2'd2;
      4: w_wdata[4:3] = 2'd3;
      5: begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end
      6: begin w_wdata[0] = 1'b1; w_wdata[1] = 1'b1; end
      7: begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end
      8: w_wdata[7:0] = 8'h80;
      9: w_wdata[7:0] = 8'hff;
      10: w_wdata[7:0] = 8'h00;
      11: begin w_wen = 1'b0; w_wdata = 64'hffff_ffff_ffff_ffff; end
      12: w_wdata = 64'hffff_ffff_ffff_ffff;
      13: w_wdata = 64'h0000_0000_0000_0055;
      14: w_wdata = 64'h0000_0000_0000_00aa;
      default: w_wdata = 64'h0000_0000_0000_00ff;
    endcase
  endtask

  task automatic drive_random();
    w_wen = (($urandom % 4) != 0);
    w_wdata = {$urandom, $urandom};
    case ($urandom % 8)
      0, 1: w_wdata[4:3] = 2'd2;
      2, 3: begin w_wdata[0] = 1'b0; w_wdata[1] = 1'b1; end
      4: w_wdata[7] = 1'b1;
      5: w_wdata[7:0] = 8'hff;
      6: w_wdata[7:0] = 8'h00;
      default: begin end
    endcase
  endtask

  initial begin
    int toggled_count;
    void'($value$plusargs("ncycles=%d", ncycles));
    w_wen = 1'b0;
    w_wdata = '0;
    toggled = '0;
    for (int v = 0; v < NVAR; v++) previous[v] = '0;

    reset = 1'b1;
    repeat (5) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;

    for (int unsigned cycle = 0; cycle < ncycles; cycle++) begin
      if (cycle == ncycles/2) begin
        reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
      end
      @(negedge clock);
      if (cycle < DIRECTED) drive_directed(cycle);
      else drive_random();
      @(posedge clock);
      #1;
      compare_outputs();
      sample_coverage();
    end

    toggled_count = 0;
    for (int s = 0; s < NVAR*NSIG; s++) toggled_count += toggled[s];
    $display("PmpCfgLeaves8b checks=%0d errors=%0d toggled=%0d/%0d fires=%0d warl_a2=%0d reserved_writes=%0d lock_rewrites=%0d",
             checks, errors, toggled_count, NVAR*NSIG, fires, warl_a2, reserved_writes, lock_rewrites);
    if (errors != 0) $fatal(1, "TEST FAILED: mismatches");
    if (checks == 0) $fatal(1, "TEST FAILED: no comparisons");
    if (toggled_count != NVAR*NSIG) $fatal(1, "TEST FAILED: incomplete output coverage");
    if (fires < MIN_FIRES) $fatal(1, "TEST FAILED: insufficient write coverage");
    if (warl_a2 < MIN_WARL_A2) $fatal(1, "TEST FAILED: insufficient A=2 WARL coverage");
    if (reserved_writes < MIN_W_RES) $fatal(1, "TEST FAILED: insufficient reserved R/W coverage");
    if (lock_rewrites < MIN_L_REWRITE) $fatal(1, "TEST FAILED: insufficient L rewrite coverage");
    $display("TEST PASSED");
    $finish;
  end
endmodule
