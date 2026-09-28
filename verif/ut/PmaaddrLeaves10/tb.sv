`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [63:0] addr_data [21:30];
  wire  [63:0] rdata [21:30];
  wire  [63:0] mirror [21:30];

  Pmaaddr21Module_xs u21(.rdata(rdata[21]), .regOut_ALL(mirror[21]), .addrRData_21(addr_data[21]));
  Pmaaddr22Module_xs u22(.rdata(rdata[22]), .regOut_ALL(mirror[22]), .addrRData_22(addr_data[22]));
  Pmaaddr23Module_xs u23(.rdata(rdata[23]), .regOut_ALL(mirror[23]), .addrRData_23(addr_data[23]));
  Pmaaddr24Module_xs u24(.rdata(rdata[24]), .regOut_ALL(mirror[24]), .addrRData_24(addr_data[24]));
  Pmaaddr25Module_xs u25(.rdata(rdata[25]), .regOut_ALL(mirror[25]), .addrRData_25(addr_data[25]));
  Pmaaddr26Module_xs u26(.rdata(rdata[26]), .regOut_ALL(mirror[26]), .addrRData_26(addr_data[26]));
  Pmaaddr27Module_xs u27(.rdata(rdata[27]), .regOut_ALL(mirror[27]), .addrRData_27(addr_data[27]));
  Pmaaddr28Module_xs u28(.rdata(rdata[28]), .regOut_ALL(mirror[28]), .addrRData_28(addr_data[28]));
  Pmaaddr29Module_xs u29(.rdata(rdata[29]), .regOut_ALL(mirror[29]), .addrRData_29(addr_data[29]));
  Pmaaddr30Module_xs u30(.rdata(rdata[30]), .regOut_ALL(mirror[30]), .addrRData_30(addr_data[30]));

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 21; slot <= 30; slot++) begin
        if (rdata[slot] !== addr_data[slot])
          errors++;
        if (mirror[slot] !== addr_data[slot])
          errors++;
      end
    end
  endtask

  task automatic set_all(input logic [63:0] value);
    integer slot;
    begin
      for (slot = 21; slot <= 30; slot++)
        addr_data[slot] = value;
    end
  endtask

  task automatic randomize_all;
    integer slot;
    begin
      for (slot = 21; slot <= 30; slot++)
        addr_data[slot] = {$urandom, $urandom};
    end
  endtask

  initial begin
    set_all(64'b0);
    compare_now();
    set_all(64'b1);
    compare_now();
    set_all(64'hAAAA_AAAA_AAAA_AAAA);
    compare_now();
    set_all(64'h5555_5555_5555_5555);
    compare_now();
    repeat (NCYCLES) begin
      randomize_all();
      compare_now();
    end
    $display("PmaaddrLeaves10 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 10, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
