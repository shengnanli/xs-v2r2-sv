`timescale 1ns/1ps
module tb;
  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int errors = 0;
  int vectors = 0;

  logic [63:0] addr [1:30];
  wire  [63:0] rdata [1:30];
  wire  [63:0] mirror [1:30];

  Pmaaddr1Module_xs u1(.rdata(rdata[1]), .regOut_ALL(mirror[1]), .addrRData_1(addr[1]));
  Pmaaddr2Module_xs u2(.rdata(rdata[2]), .regOut_ALL(mirror[2]), .addrRData_2(addr[2]));
  Pmaaddr3Module_xs u3(.rdata(rdata[3]), .regOut_ALL(mirror[3]), .addrRData_3(addr[3]));
  Pmaaddr4Module_xs u4(.rdata(rdata[4]), .regOut_ALL(mirror[4]), .addrRData_4(addr[4]));
  Pmaaddr5Module_xs u5(.rdata(rdata[5]), .regOut_ALL(mirror[5]), .addrRData_5(addr[5]));
  Pmaaddr6Module_xs u6(.rdata(rdata[6]), .regOut_ALL(mirror[6]), .addrRData_6(addr[6]));
  Pmaaddr7Module_xs u7(.rdata(rdata[7]), .regOut_ALL(mirror[7]), .addrRData_7(addr[7]));
  Pmaaddr8Module_xs u8(.rdata(rdata[8]), .regOut_ALL(mirror[8]), .addrRData_8(addr[8]));
  Pmaaddr9Module_xs u9(.rdata(rdata[9]), .regOut_ALL(mirror[9]), .addrRData_9(addr[9]));
  Pmaaddr10Module_xs u10(.rdata(rdata[10]), .regOut_ALL(mirror[10]), .addrRData_10(addr[10]));
  Pmaaddr11Module_xs u11(.rdata(rdata[11]), .regOut_ALL(mirror[11]), .addrRData_11(addr[11]));
  Pmaaddr12Module_xs u12(.rdata(rdata[12]), .regOut_ALL(mirror[12]), .addrRData_12(addr[12]));
  Pmaaddr13Module_xs u13(.rdata(rdata[13]), .regOut_ALL(mirror[13]), .addrRData_13(addr[13]));
  Pmaaddr14Module_xs u14(.rdata(rdata[14]), .regOut_ALL(mirror[14]), .addrRData_14(addr[14]));
  Pmaaddr15Module_xs u15(.rdata(rdata[15]), .regOut_ALL(mirror[15]), .addrRData_15(addr[15]));
  Pmaaddr16Module_xs u16(.rdata(rdata[16]), .regOut_ALL(mirror[16]), .addrRData_16(addr[16]));
  Pmaaddr17Module_xs u17(.rdata(rdata[17]), .regOut_ALL(mirror[17]), .addrRData_17(addr[17]));
  Pmaaddr18Module_xs u18(.rdata(rdata[18]), .regOut_ALL(mirror[18]), .addrRData_18(addr[18]));
  Pmaaddr19Module_xs u19(.rdata(rdata[19]), .regOut_ALL(mirror[19]), .addrRData_19(addr[19]));
  Pmaaddr20Module_xs u20(.rdata(rdata[20]), .regOut_ALL(mirror[20]), .addrRData_20(addr[20]));
  Pmaaddr21Module_xs u21(.rdata(rdata[21]), .regOut_ALL(mirror[21]), .addrRData_21(addr[21]));
  Pmaaddr22Module_xs u22(.rdata(rdata[22]), .regOut_ALL(mirror[22]), .addrRData_22(addr[22]));
  Pmaaddr23Module_xs u23(.rdata(rdata[23]), .regOut_ALL(mirror[23]), .addrRData_23(addr[23]));
  Pmaaddr24Module_xs u24(.rdata(rdata[24]), .regOut_ALL(mirror[24]), .addrRData_24(addr[24]));
  Pmaaddr25Module_xs u25(.rdata(rdata[25]), .regOut_ALL(mirror[25]), .addrRData_25(addr[25]));
  Pmaaddr26Module_xs u26(.rdata(rdata[26]), .regOut_ALL(mirror[26]), .addrRData_26(addr[26]));
  Pmaaddr27Module_xs u27(.rdata(rdata[27]), .regOut_ALL(mirror[27]), .addrRData_27(addr[27]));
  Pmaaddr28Module_xs u28(.rdata(rdata[28]), .regOut_ALL(mirror[28]), .addrRData_28(addr[28]));
  Pmaaddr29Module_xs u29(.rdata(rdata[29]), .regOut_ALL(mirror[29]), .addrRData_29(addr[29]));
  Pmaaddr30Module_xs u30(.rdata(rdata[30]), .regOut_ALL(mirror[30]), .addrRData_30(addr[30]));

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 1; slot <= 30; slot++) begin
        if (rdata[slot] !== addr[slot])
          errors++;
        if (mirror[slot] !== addr[slot])
          errors++;
      end
    end
  endtask

  task automatic drive_random;
    integer slot;
    begin
      for (slot = 1; slot <= 30; slot++)
        addr[slot] = {$urandom, $urandom};
    end
  endtask

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($urandom(seed));
    if (!$value$plusargs("ncycles=%d", ncycles))
      ncycles = 200000;

    for (int slot = 1; slot <= 30; slot++)
      addr[slot] = 64'b0;
    compare_now();

    for (int slot = 1; slot <= 30; slot++)
      addr[slot] = 64'hffff_ffff_ffff_ffff;
    compare_now();

    repeat (ncycles) begin
      drive_random();
      compare_now();
    end

    $display("PmaaddrLeaves30 UT: seed=%0d vectors=%0d module_checks=%0d errors=%0d",
             seed, vectors, vectors * 30, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
