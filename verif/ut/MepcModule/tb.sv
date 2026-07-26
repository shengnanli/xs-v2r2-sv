// epc family UT: golden MepcModule vs readable primitive (_xs), cycle-by-cycle.
// Exercises WARL bit[0]->0, the trap-write port, and the OR-of-CSR-write path
// (both w_wen and trap_valid asserted in the same cycle).
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  int unsigned WARMUP  = 4;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic        w_wen;
  logic [63:0] w_wdata;
  logic        trap_valid;
  logic [62:0] trap_bits;

  logic [63:0] g_rd, i_rd; logic [62:0] g_epc, i_epc;
  MepcModule    g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_epc(g_epc),
    .trapToM_mepc_valid(trap_valid),.trapToM_mepc_bits_epc(trap_bits));
  MepcModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_epc(i_epc),
    .trapToM_mepc_valid(trap_valid),.trapToM_mepc_bits_epc(trap_bits));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; trap_valid<='0; trap_bits<='0; end
    else begin
      w_wen      <= ($urandom_range(0,1)==0);
      w_wdata    <= {$urandom, $urandom};        // low bit sweeps WARL 0-force
      trap_valid <= ($urandom_range(0,3)==0);    // ~25% trap entries
      trap_bits  <= {$urandom, ($urandom & 32'h7fff_ffff)};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_epc!==i_epc) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h epc g=%h i=%h",$time,g_rd,i_rd,g_epc,i_epc);
      end
    end
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
