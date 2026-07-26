// topi/topei UT: golden Mtopi/Mtopei vs readable combinational primitives (_xs).
// Pure combinational: drive random IID/IPRIO, compare rdata (+ regOut for topei).
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic [11:0] topi_iid;
  logic [7:0]  topi_iprio;
  logic [10:0] topei_iid, topei_iprio;

  logic [63:0] gtopi_rd, itopi_rd;
  logic [63:0] gtopei_rd, itopei_rd;
  logic [10:0] gtopei_id, itopei_id, gtopei_ip, itopei_ip;

  MtopiModule    gtopi(.rdata(gtopi_rd), .topIR_mtopi_IID(topi_iid), .topIR_mtopi_IPRIO(topi_iprio));
  MtopiModule_xs itopi(.rdata(itopi_rd), .topIR_mtopi_IID(topi_iid), .topIR_mtopi_IPRIO(topi_iprio));
  MtopeiModule    gtopei(.rdata(gtopei_rd), .regOut_IID(gtopei_id), .regOut_IPRIO(gtopei_ip),
    .aiaToCSR_mtopei_IID(topei_iid), .aiaToCSR_mtopei_IPRIO(topei_iprio));
  MtopeiModule_xs itopei(.rdata(itopei_rd), .regOut_IID(itopei_id), .regOut_IPRIO(itopei_ip),
    .aiaToCSR_mtopei_IID(topei_iid), .aiaToCSR_mtopei_IPRIO(topei_iprio));

  always @(negedge clk) begin
    topi_iid    <= $urandom;
    topi_iprio  <= $urandom;
    topei_iid   <= $urandom;
    topei_iprio <= $urandom;
  end

  always @(posedge clk) begin
    #1; checks++;
    if (gtopi_rd!==itopi_rd || gtopei_rd!==itopei_rd ||
        gtopei_id!==itopei_id || gtopei_ip!==itopei_ip) begin
      errors++;
      if(errors<=30) $display("[%0t] topi g=%h i=%h | topei g=%h i=%h",$time,gtopi_rd,itopi_rd,gtopei_rd,itopei_rd);
    end
  end

  initial begin
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
