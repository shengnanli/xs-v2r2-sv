`timescale 1ns/1ps
module tb;
  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int errors = 0;
  longint unsigned vectors = 0;
  integer slot;
  integer unused_random;

  logic [63:0] addr [0:16];
  wire [63:0] rdata [0:16];
  wire [45:0] address [0:16];

  Pmpaddr0Module_xs u0(.rdata(rdata[0]), .regOut_ADDRESS(address[0]), .addrRData_0(addr[0]));
  Pmpaddr1Module_xs u1(.rdata(rdata[1]), .regOut_ADDRESS(address[1]), .addrRData_1(addr[1]));
  Pmpaddr2Module_xs u2(.rdata(rdata[2]), .regOut_ADDRESS(address[2]), .addrRData_2(addr[2]));
  Pmpaddr3Module_xs u3(.rdata(rdata[3]), .regOut_ADDRESS(address[3]), .addrRData_3(addr[3]));
  Pmpaddr4Module_xs u4(.rdata(rdata[4]), .regOut_ADDRESS(address[4]), .addrRData_4(addr[4]));
  Pmpaddr5Module_xs u5(.rdata(rdata[5]), .regOut_ADDRESS(address[5]), .addrRData_5(addr[5]));
  Pmpaddr6Module_xs u6(.rdata(rdata[6]), .regOut_ADDRESS(address[6]), .addrRData_6(addr[6]));
  Pmpaddr7Module_xs u7(.rdata(rdata[7]), .regOut_ADDRESS(address[7]), .addrRData_7(addr[7]));
  Pmpaddr8Module_xs u8(.rdata(rdata[8]), .regOut_ADDRESS(address[8]), .addrRData_8(addr[8]));
  Pmpaddr9Module_xs u9(.rdata(rdata[9]), .regOut_ADDRESS(address[9]), .addrRData_9(addr[9]));
  Pmpaddr10Module_xs u10(.rdata(rdata[10]), .regOut_ADDRESS(address[10]), .addrRData_10(addr[10]));
  Pmpaddr11Module_xs u11(.rdata(rdata[11]), .regOut_ADDRESS(address[11]), .addrRData_11(addr[11]));
  Pmpaddr12Module_xs u12(.rdata(rdata[12]), .regOut_ADDRESS(address[12]), .addrRData_12(addr[12]));
  Pmpaddr13Module_xs u13(.rdata(rdata[13]), .regOut_ADDRESS(address[13]), .addrRData_13(addr[13]));
  Pmpaddr14Module_xs u14(.rdata(rdata[14]), .regOut_ADDRESS(address[14]), .addrRData_14(addr[14]));
  Pmpaddr15Module_xs u15(.rdata(rdata[15]), .regOut_ADDRESS(address[15]), .addrRData_15(addr[15]));
  Pmpaddr16Module_xs u16(.rdata(rdata[16]), .regOut_ADDRESS(address[16]), .addrRData_16(addr[16]));

  task automatic check_all;
    begin
      #1;
      vectors++;
      for (slot = 0; slot <= 16; slot++) begin
        if (address[slot] !== addr[slot][45:0]) begin
          $display("ADDRESS mismatch slot=%0d in=%h got=%h", slot, addr[slot], address[slot]);
          errors++;
        end
        if (rdata[slot] !== {18'b0, addr[slot][45:0]}) begin
          $display("RDATA mismatch slot=%0d in=%h got=%h", slot, addr[slot], rdata[slot]);
          errors++;
        end
      end
    end
  endtask

  task automatic drive_random;
    begin
      for (slot = 0; slot <= 16; slot++)
        addr[slot] = {$urandom, $urandom};
    end
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", ncycles));
    void'($value$plusargs("seed=%d", seed));
    unused_random = $urandom(seed);

    for (slot = 0; slot <= 16; slot++) addr[slot] = 64'b0;
    check_all();
    for (slot = 0; slot <= 16; slot++) addr[slot] = 64'hFFFF_FFFF_FFFF_FFFF;
    check_all();
    for (slot = 0; slot <= 16; slot++) addr[slot] = 64'hAAAA_AAAA_AAAA_AAAA;
    check_all();
    for (slot = 0; slot <= 16; slot++) addr[slot] = 64'h5555_5555_5555_5555;
    check_all();

    repeat (ncycles) begin
      drive_random();
      check_all();
    end

    $display("PmpaddrLeaves0_16 UT: seed=%0d vectors=%0d module_checks=%0d errors=%0d",
             seed, vectors, vectors * 17, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
