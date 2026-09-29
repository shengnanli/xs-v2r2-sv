`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  logic [63:0] addr [17:31];
  wire [63:0] ref_rdata [17:31];
  wire [63:0] dut_rdata [17:31];
  wire [45:0] ref_address [17:31];
  wire [45:0] dut_address [17:31];

  Pmpaddr17Module ref17(.rdata(ref_rdata[17]), .regOut_ADDRESS(ref_address[17]), .addrRData_17(addr[17]));
  Pmpaddr17Module_xs dut17(.rdata(dut_rdata[17]), .regOut_ADDRESS(dut_address[17]), .addrRData_17(addr[17]));
  Pmpaddr18Module ref18(.rdata(ref_rdata[18]), .regOut_ADDRESS(ref_address[18]), .addrRData_18(addr[18]));
  Pmpaddr18Module_xs dut18(.rdata(dut_rdata[18]), .regOut_ADDRESS(dut_address[18]), .addrRData_18(addr[18]));
  Pmpaddr19Module ref19(.rdata(ref_rdata[19]), .regOut_ADDRESS(ref_address[19]), .addrRData_19(addr[19]));
  Pmpaddr19Module_xs dut19(.rdata(dut_rdata[19]), .regOut_ADDRESS(dut_address[19]), .addrRData_19(addr[19]));
  Pmpaddr20Module ref20(.rdata(ref_rdata[20]), .regOut_ADDRESS(ref_address[20]), .addrRData_20(addr[20]));
  Pmpaddr20Module_xs dut20(.rdata(dut_rdata[20]), .regOut_ADDRESS(dut_address[20]), .addrRData_20(addr[20]));
  Pmpaddr21Module ref21(.rdata(ref_rdata[21]), .regOut_ADDRESS(ref_address[21]), .addrRData_21(addr[21]));
  Pmpaddr21Module_xs dut21(.rdata(dut_rdata[21]), .regOut_ADDRESS(dut_address[21]), .addrRData_21(addr[21]));
  Pmpaddr22Module ref22(.rdata(ref_rdata[22]), .regOut_ADDRESS(ref_address[22]), .addrRData_22(addr[22]));
  Pmpaddr22Module_xs dut22(.rdata(dut_rdata[22]), .regOut_ADDRESS(dut_address[22]), .addrRData_22(addr[22]));
  Pmpaddr23Module ref23(.rdata(ref_rdata[23]), .regOut_ADDRESS(ref_address[23]), .addrRData_23(addr[23]));
  Pmpaddr23Module_xs dut23(.rdata(dut_rdata[23]), .regOut_ADDRESS(dut_address[23]), .addrRData_23(addr[23]));
  Pmpaddr24Module ref24(.rdata(ref_rdata[24]), .regOut_ADDRESS(ref_address[24]), .addrRData_24(addr[24]));
  Pmpaddr24Module_xs dut24(.rdata(dut_rdata[24]), .regOut_ADDRESS(dut_address[24]), .addrRData_24(addr[24]));
  Pmpaddr25Module ref25(.rdata(ref_rdata[25]), .regOut_ADDRESS(ref_address[25]), .addrRData_25(addr[25]));
  Pmpaddr25Module_xs dut25(.rdata(dut_rdata[25]), .regOut_ADDRESS(dut_address[25]), .addrRData_25(addr[25]));
  Pmpaddr26Module ref26(.rdata(ref_rdata[26]), .regOut_ADDRESS(ref_address[26]), .addrRData_26(addr[26]));
  Pmpaddr26Module_xs dut26(.rdata(dut_rdata[26]), .regOut_ADDRESS(dut_address[26]), .addrRData_26(addr[26]));
  Pmpaddr27Module ref27(.rdata(ref_rdata[27]), .regOut_ADDRESS(ref_address[27]), .addrRData_27(addr[27]));
  Pmpaddr27Module_xs dut27(.rdata(dut_rdata[27]), .regOut_ADDRESS(dut_address[27]), .addrRData_27(addr[27]));
  Pmpaddr28Module ref28(.rdata(ref_rdata[28]), .regOut_ADDRESS(ref_address[28]), .addrRData_28(addr[28]));
  Pmpaddr28Module_xs dut28(.rdata(dut_rdata[28]), .regOut_ADDRESS(dut_address[28]), .addrRData_28(addr[28]));
  Pmpaddr29Module ref29(.rdata(ref_rdata[29]), .regOut_ADDRESS(ref_address[29]), .addrRData_29(addr[29]));
  Pmpaddr29Module_xs dut29(.rdata(dut_rdata[29]), .regOut_ADDRESS(dut_address[29]), .addrRData_29(addr[29]));
  Pmpaddr30Module ref30(.rdata(ref_rdata[30]), .regOut_ADDRESS(ref_address[30]), .addrRData_30(addr[30]));
  Pmpaddr30Module_xs dut30(.rdata(dut_rdata[30]), .regOut_ADDRESS(dut_address[30]), .addrRData_30(addr[30]));
  Pmpaddr31Module ref31(.rdata(ref_rdata[31]), .regOut_ADDRESS(ref_address[31]), .addrRData_31(addr[31]));
  Pmpaddr31Module_xs dut31(.rdata(dut_rdata[31]), .regOut_ADDRESS(dut_address[31]), .addrRData_31(addr[31]));

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 17; slot <= 31; slot++) begin
        if (dut_rdata[slot] !== ref_rdata[slot] ||
            dut_address[slot] !== ref_address[slot] ||
            dut_rdata[slot] !== {18'b0, addr[slot][45:0]} ||
            dut_address[slot] !== addr[slot][45:0])
          errors++;
      end
    end
  endtask

  initial begin
    integer slot;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) begin end
    for (slot = 17; slot <= 31; slot++)
      addr[slot] = '0;
    compare_now();
    repeat (NCYCLES) begin
      for (slot = 17; slot <= 31; slot++)
        addr[slot] = {$urandom, $urandom};
      compare_now();
    end
    $display("PmpaddrLeaves17_31 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 15, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
