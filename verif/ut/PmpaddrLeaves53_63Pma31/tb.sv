`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  wire [63:0] pmp_rdata [53:63];
  wire [63:0] pmp_mirror [53:63];
  logic [63:0] pma_value;
  wire [63:0] pma_golden_rdata;
  wire [63:0] pma_golden_mirror;
  wire [63:0] pma_impl_rdata;
  wire [63:0] pma_impl_mirror;

  Pmpaddr53Module_xs u53(.rdata(pmp_rdata[53]), .regOut_ALL(pmp_mirror[53]));
  Pmpaddr54Module_xs u54(.rdata(pmp_rdata[54]), .regOut_ALL(pmp_mirror[54]));
  Pmpaddr55Module_xs u55(.rdata(pmp_rdata[55]), .regOut_ALL(pmp_mirror[55]));
  Pmpaddr56Module_xs u56(.rdata(pmp_rdata[56]), .regOut_ALL(pmp_mirror[56]));
  Pmpaddr57Module_xs u57(.rdata(pmp_rdata[57]), .regOut_ALL(pmp_mirror[57]));
  Pmpaddr58Module_xs u58(.rdata(pmp_rdata[58]), .regOut_ALL(pmp_mirror[58]));
  Pmpaddr59Module_xs u59(.rdata(pmp_rdata[59]), .regOut_ALL(pmp_mirror[59]));
  Pmpaddr60Module_xs u60(.rdata(pmp_rdata[60]), .regOut_ALL(pmp_mirror[60]));
  Pmpaddr61Module_xs u61(.rdata(pmp_rdata[61]), .regOut_ALL(pmp_mirror[61]));
  Pmpaddr62Module_xs u62(.rdata(pmp_rdata[62]), .regOut_ALL(pmp_mirror[62]));
  Pmpaddr63Module_xs u63(.rdata(pmp_rdata[63]), .regOut_ALL(pmp_mirror[63]));

  Pmaaddr31Module g_pma(
    .rdata(pma_golden_rdata),
    .regOut_ALL(pma_golden_mirror),
    .addrRData_31(pma_value)
  );
  Pmaaddr31Module_xs i_pma(
    .rdata(pma_impl_rdata),
    .regOut_ALL(pma_impl_mirror),
    .addrRData_31(pma_value)
  );

  task automatic compare_now;
    integer slot;
    begin
      #1;
      vectors++;
      for (slot = 53; slot <= 63; slot++) begin
        if (pmp_rdata[slot] !== 64'b0 || pmp_mirror[slot] !== 64'b0)
          errors++;
      end
      if (pma_golden_rdata !== pma_value || pma_golden_mirror !== pma_value ||
          pma_impl_rdata !== pma_value || pma_impl_mirror !== pma_value)
        errors++;
    end
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) begin end
    pma_value = 64'b0;
    compare_now();
    pma_value = 64'hFFFF_FFFF_FFFF_FFFF;
    compare_now();
    repeat (NCYCLES) begin
      pma_value = {$urandom, $urandom};
      compare_now();
    end
    $display("PmpaddrLeaves53_63Pma31 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 12, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
