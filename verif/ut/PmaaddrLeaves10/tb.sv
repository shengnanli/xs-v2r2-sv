`timescale 1ns/1ps
module tb;
  int unsigned ncycles = 200000;
  int errors = 0;
  int vectors = 0;

  logic [63:0] addr [1:10];
  wire  [63:0] rdata [1:10];
  wire  [63:0] mirror [1:10];

  Pmaaddr1Module_xs u1 (
    .rdata(rdata[1]),
    .regOut_ALL(mirror[1]),
    .addrRData_1(addr[1])
  );
  Pmaaddr2Module_xs u2 (
    .rdata(rdata[2]),
    .regOut_ALL(mirror[2]),
    .addrRData_2(addr[2])
  );
  Pmaaddr3Module_xs u3 (
    .rdata(rdata[3]),
    .regOut_ALL(mirror[3]),
    .addrRData_3(addr[3])
  );
  Pmaaddr4Module_xs u4 (
    .rdata(rdata[4]),
    .regOut_ALL(mirror[4]),
    .addrRData_4(addr[4])
  );
  Pmaaddr5Module_xs u5 (
    .rdata(rdata[5]),
    .regOut_ALL(mirror[5]),
    .addrRData_5(addr[5])
  );
  Pmaaddr6Module_xs u6 (
    .rdata(rdata[6]),
    .regOut_ALL(mirror[6]),
    .addrRData_6(addr[6])
  );
  Pmaaddr7Module_xs u7 (
    .rdata(rdata[7]),
    .regOut_ALL(mirror[7]),
    .addrRData_7(addr[7])
  );
  Pmaaddr8Module_xs u8 (
    .rdata(rdata[8]),
    .regOut_ALL(mirror[8]),
    .addrRData_8(addr[8])
  );
  Pmaaddr9Module_xs u9 (
    .rdata(rdata[9]),
    .regOut_ALL(mirror[9]),
    .addrRData_9(addr[9])
  );
  Pmaaddr10Module_xs u10 (
    .rdata(rdata[10]),
    .regOut_ALL(mirror[10]),
    .addrRData_10(addr[10])
  );

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 1; slot <= 10; slot++) begin
        if (rdata[slot] !== addr[slot])
          errors++;
        if (mirror[slot] !== addr[slot])
          errors++;
      end
    end
  endtask

  task automatic randomize_inputs;
    integer slot;
    begin
      for (slot = 1; slot <= 10; slot++)
        addr[slot] = {$urandom, $urandom};
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles))
      ncycles = 200000;

    for (int slot = 1; slot <= 10; slot++)
      addr[slot] = 64'b0;
    compare_now();

    for (int slot = 1; slot <= 10; slot++)
      addr[slot] = 64'hFFFF_FFFF_FFFF_FFFF;
    compare_now();

    repeat (ncycles) begin
      randomize_inputs();
      compare_now();
    end

    $display("PmaaddrLeaves10 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 10, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
