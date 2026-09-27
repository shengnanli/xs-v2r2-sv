`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  wire [63:0] rdata [33:52];
  wire [63:0] mirror [33:52];

  Pmpaddr33Module_xs u33(.rdata(rdata[33]), .regOut_ALL(mirror[33]));
  Pmpaddr34Module_xs u34(.rdata(rdata[34]), .regOut_ALL(mirror[34]));
  Pmpaddr35Module_xs u35(.rdata(rdata[35]), .regOut_ALL(mirror[35]));
  Pmpaddr36Module_xs u36(.rdata(rdata[36]), .regOut_ALL(mirror[36]));
  Pmpaddr37Module_xs u37(.rdata(rdata[37]), .regOut_ALL(mirror[37]));
  Pmpaddr38Module_xs u38(.rdata(rdata[38]), .regOut_ALL(mirror[38]));
  Pmpaddr39Module_xs u39(.rdata(rdata[39]), .regOut_ALL(mirror[39]));
  Pmpaddr40Module_xs u40(.rdata(rdata[40]), .regOut_ALL(mirror[40]));
  Pmpaddr41Module_xs u41(.rdata(rdata[41]), .regOut_ALL(mirror[41]));
  Pmpaddr42Module_xs u42(.rdata(rdata[42]), .regOut_ALL(mirror[42]));
  Pmpaddr43Module_xs u43(.rdata(rdata[43]), .regOut_ALL(mirror[43]));
  Pmpaddr44Module_xs u44(.rdata(rdata[44]), .regOut_ALL(mirror[44]));
  Pmpaddr45Module_xs u45(.rdata(rdata[45]), .regOut_ALL(mirror[45]));
  Pmpaddr46Module_xs u46(.rdata(rdata[46]), .regOut_ALL(mirror[46]));
  Pmpaddr47Module_xs u47(.rdata(rdata[47]), .regOut_ALL(mirror[47]));
  Pmpaddr48Module_xs u48(.rdata(rdata[48]), .regOut_ALL(mirror[48]));
  Pmpaddr49Module_xs u49(.rdata(rdata[49]), .regOut_ALL(mirror[49]));
  Pmpaddr50Module_xs u50(.rdata(rdata[50]), .regOut_ALL(mirror[50]));
  Pmpaddr51Module_xs u51(.rdata(rdata[51]), .regOut_ALL(mirror[51]));
  Pmpaddr52Module_xs u52(.rdata(rdata[52]), .regOut_ALL(mirror[52]));

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 33; slot <= 52; slot++) begin
        if (rdata[slot] !== 64'b0 || mirror[slot] !== 64'b0)
          errors++;
      end
    end
  endtask

  initial begin
    compare_now();
    repeat (NCYCLES) compare_now();
    $display("PmpaddrLeaves20 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 20, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
