`timescale 1ns/1ps
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'h0;
  logic v = 1'b0;
  logic [3:0] hgatp_MODE = 4'h0;

  logic [63:0] g_rdata;
  logic [3:0]  g_regOut_MODE;
  logic [15:0] g_regOut_ASID;
  logic [43:0] g_regOut_PPN;
  logic [63:0] x_rdata;
  logic [3:0]  x_regOut_MODE;
  logic [15:0] x_regOut_ASID;
  logic [43:0] x_regOut_PPN;

  integer errors = 0;
  integer checks = 0;
  integer cycle = 0;
  integer ncycles = 200000;
  reg [3:0] model_mode = 4'h0;
  reg [15:0] model_asid = 16'h0;
  reg [43:0] model_ppn = 44'h0;

  always #1 clock = ~clock;
  always @(posedge clock) cycle = cycle + 1;
  initial void'($value$plusargs("ncycles=%d", ncycles));

  VSatpModule g_dut (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(g_rdata), .regOut_MODE(g_regOut_MODE), .regOut_ASID(g_regOut_ASID),
    .regOut_PPN(g_regOut_PPN), .v(v), .hgatp_MODE(hgatp_MODE)
  );
  VSatpModule_xs x_dut (
    .clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata),
    .rdata(x_rdata), .regOut_MODE(x_regOut_MODE), .regOut_ASID(x_regOut_ASID),
    .regOut_PPN(x_regOut_PPN), .v(v), .hgatp_MODE(hgatp_MODE)
  );

  function automatic [43:0] ppn_mask(input [3:0] mode);
    case (mode)
      4'h0: ppn_mask = 44'hFFFFFFFFF;
      4'h8: ppn_mask = 44'h1FFFFFFF;
      4'h9: ppn_mask = 44'h3FFFFFFFFF;
      default: ppn_mask = 44'h0;
    endcase
  endfunction

  task automatic check_outputs(input [127:0] expected, input integer tag);
    reg [127:0] g_actual;
    reg [127:0] x_actual;
    begin
      #0;
      g_actual = {g_regOut_MODE, g_regOut_ASID, g_regOut_PPN};
      x_actual = {x_regOut_MODE, x_regOut_ASID, x_regOut_PPN};
      checks = checks + 1;
      if (g_actual !== expected || g_rdata !== expected) begin
        errors = errors + 1;
        $display("FAIL golden tag=%0d cycle=%0d expected=%h actual=%h rdata=%h", tag, cycle, expected, g_actual, g_rdata);
      end
      if (x_actual !== expected || x_rdata !== expected) begin
        errors = errors + 1;
        $display("FAIL impl tag=%0d cycle=%0d expected=%h actual=%h rdata=%h", tag, cycle, expected, x_actual, x_rdata);
      end
      if (g_actual !== x_actual || g_rdata !== x_rdata) begin
        errors = errors + 1;
        $display("FAIL differential tag=%0d cycle=%0d golden=%h impl=%h golden_rdata=%h impl_rdata=%h", tag, cycle, g_actual, x_actual, g_rdata, x_rdata);
      end
    end
  endtask

  task automatic apply_write(input logic wen_i, input logic [63:0] data_i,
                             input logic v_i, input logic [3:0] hgatp_i,
                             input integer tag);
    reg [3:0] next_mode;
    reg [15:0] next_asid;
    reg [43:0] next_ppn;
    begin
      @(negedge clock);
      w_wen = wen_i;
      w_wdata = data_i;
      v = v_i;
      hgatp_MODE = hgatp_i;
      if (wen_i) begin
        if ((data_i[63:60] == 4'h0) || (data_i[63:60] == 4'h8) || (data_i[63:60] == 4'h9)) begin
          next_mode = data_i[63:60];
          next_asid = data_i[59:44];
          next_ppn = data_i[43:0] & ppn_mask(hgatp_i);
        end
        else if (!v_i) begin
          next_mode = model_mode;
          next_asid = data_i[59:44];
          next_ppn = data_i[43:0] & ppn_mask(hgatp_i);
        end
        else begin
          next_mode = model_mode;
          next_asid = model_asid;
          next_ppn = model_ppn;
        end
        model_mode = next_mode;
        model_asid = next_asid;
        model_ppn = next_ppn;
      end
      @(posedge clock);
      #0.1;
      check_outputs({model_mode, model_asid, model_ppn}, tag);
    end
  endtask

  task automatic reset_duts;
    begin
      @(negedge clock);
      reset = 1'b1;
      w_wen = 1'b0;
      w_wdata = 64'h0;
      v = 1'b0;
      hgatp_MODE = 4'h0;
      model_mode = 4'h0;
      model_asid = 16'h0;
      model_ppn = 44'h0;
      @(posedge clock);
      #0.1;
      check_outputs(128'h0, 0);
      @(negedge clock);
      reset = 1'b0;
    end
  endtask

  integer i;
  reg [63:0] data;
  reg [3:0] mode;
  reg [3:0] gmode;
  reg [15:0] asid;
  reg [43:0] ppn;
  initial begin
    reset_duts();

    // Exercise every legal MODE, each guest-physical mode mask, and reset-like writes.
    for (i = 0; i < 24; i = i + 1) begin
      mode = (i % 6 == 0) ? 4'h0 : ((i % 6 == 1) ? 4'h8 : ((i % 6 == 2) ? 4'h9 : 4'hf));
      gmode = (i % 4 == 0) ? 4'h0 : ((i % 4 == 1) ? 4'h8 : ((i % 4 == 2) ? 4'h9 : 4'h7));
      asid = 16'h1000 + i;
      ppn = 44'hABCDE00000 + i;
      data = {mode, asid, ppn};
      apply_write(1'b1, data, (i % 3 == 0), gmode, i + 1);
      apply_write(1'b0, {$urandom, $urandom}, (i % 2), gmode, i + 100);
    end

    // Long deterministic traffic: continuously vary legal/illegal writes and inputs.
    for (i = 0; i < ncycles; i = i + 1) begin
      mode = $urandom_range(0, 15);
      gmode = $urandom_range(0, 15);
      asid = $urandom;
      ppn = $urandom;
      ppn = (ppn << 32) | $urandom;
      data = {mode, asid, ppn};
      apply_write($urandom_range(0, 1), data, $urandom_range(0, 1), gmode, i + 1000);
    end

    @(negedge clock);
    w_wen = 1'b0;
    #1;
    if (errors == 0)
      $display("TEST PASSED checks=%0d errors=%0d cycles=%0d", checks, errors, cycle);
    else
      $display("TEST FAILED checks=%0d errors=%0d cycles=%0d", checks, errors, cycle);
    $finish;
  end
endmodule
