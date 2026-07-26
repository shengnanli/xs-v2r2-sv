// cause family UT: golden McauseModule vs readable primitive (_xs).
// Exercises the Interrupt/ExceptionCode split, trap-write, and concurrent
// CSR-write OR path.
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
  logic        trap_int;
  logic [62:0] trap_code;

  logic [63:0] g_rd, i_rd; logic g_int, i_int; logic [62:0] g_code, i_code;
  McauseModule    g(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(g_rd),.regOut_Interrupt(g_int),.regOut_ExceptionCode(g_code),
    .trapToM_mcause_valid(trap_valid),.trapToM_mcause_bits_Interrupt(trap_int),
    .trapToM_mcause_bits_ExceptionCode(trap_code));
  McauseModule_xs i(.clock(clk),.reset(rst),.w_wen(w_wen),.w_wdata(w_wdata),
    .rdata(i_rd),.regOut_Interrupt(i_int),.regOut_ExceptionCode(i_code),
    .trapToM_mcause_valid(trap_valid),.trapToM_mcause_bits_Interrupt(trap_int),
    .trapToM_mcause_bits_ExceptionCode(trap_code));

  always @(negedge clk) begin
    if (rst) begin w_wen<='0; w_wdata<='0; trap_valid<='0; trap_int<='0; trap_code<='0; end
    else begin
      w_wen      <= ($urandom_range(0,1)==0);
      w_wdata    <= {$urandom, $urandom};
      trap_valid <= ($urandom_range(0,3)==0);
      trap_int   <= ($urandom_range(0,1)==0);
      trap_code  <= {$urandom, ($urandom & 32'h7fff_ffff)};
    end
  end

  always @(negedge clk) if (!rst) begin
    cyc++;
    if (cyc > WARMUP) begin
      #4; checks++;
      if (g_rd!==i_rd || g_int!==i_int || g_code!==i_code) begin
        errors++; if(errors<=30) $display("[%0t] rd g=%h i=%h int g=%b i=%b",$time,g_rd,i_rd,g_int,i_int);
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
