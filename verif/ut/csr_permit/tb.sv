`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [11:0] csr_addr;
  logic [1:0]  prvm;
  logic        virt;
  logic [63:0] miselect;
  logic [63:0] siselect;
  logic [63:0] vsiselect;
  logic        mvien_seie;
  logic        mstateen_aia;
  logic        mstateen_imsic;
  logic        hstateen_imsic;
  wire         dut_ii;
  wire         dut_vi;
  wire         golden_ii;
  wire         golden_vi;

  IndirectCSRPermitModule_xs dut (
    .io_in_csrAccess_addr(csr_addr),
    .io_in_privState_PRVM(prvm),
    .io_in_privState_V(virt),
    .io_in_aia_miselect(miselect),
    .io_in_aia_siselect(siselect),
    .io_in_aia_vsiselect(vsiselect),
    .io_in_aia_mvienSEIE(mvien_seie),
    .io_in_xstateen_mstateen0_AIA(mstateen_aia),
    .io_in_xstateen_mstateen0_IMSIC(mstateen_imsic),
    .io_in_xstateen_hstateen0_IMSIC(hstateen_imsic),
    .io_out_indirectCSR_EX_II(dut_ii),
    .io_out_indirectCSR_EX_VI(dut_vi)
  );

  IndirectCSRPermitModule golden (
    .io_in_csrAccess_addr(csr_addr),
    .io_in_privState_PRVM(prvm),
    .io_in_privState_V(virt),
    .io_in_aia_miselect(miselect),
    .io_in_aia_siselect(siselect),
    .io_in_aia_vsiselect(vsiselect),
    .io_in_aia_mvienSEIE(mvien_seie),
    .io_in_xstateen_mstateen0_AIA(mstateen_aia),
    .io_in_xstateen_mstateen0_IMSIC(mstateen_imsic),
    .io_in_xstateen_hstateen0_IMSIC(hstateen_imsic),
    .io_out_indirectCSR_EX_II(golden_ii),
    .io_out_indirectCSR_EX_VI(golden_vi)
  );
  task automatic compare_now;
    #1;
    vectors++;
    if (dut_ii !== golden_ii || dut_vi !== golden_vi) begin
      errors++;
      if (errors <= 10)
        $display("mismatch v=%0d addr=%h prvm=%b V=%b msel=%h ssel=%h vssel=%h mvien=%b maia=%b mimsic=%b himsic=%b dut=%b%b golden=%b%b",
          vectors, csr_addr, prvm, virt, miselect, siselect, vsiselect,
          mvien_seie, mstateen_aia, mstateen_imsic, hstateen_imsic,
          dut_ii, dut_vi, golden_ii, golden_vi);
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    csr_addr = '0;
    prvm = '0;
    virt = 1'b0;
    miselect = '0;
    siselect = '0;
    vsiselect = '0;
    mvien_seie = 1'b0;
    mstateen_aia = 1'b0;
    mstateen_imsic = 1'b0;
    hstateen_imsic = 1'b0;
    compare_now();

    csr_addr = 12'h351;
    prvm = 2'b11;
    miselect = 64'h31;
    compare_now();
    csr_addr = 12'h151;
    prvm = 2'b01;
    virt = 1'b0;
    siselect = 64'h30;
    compare_now();
    csr_addr = 12'h151;
    virt = 1'b1;
    vsiselect = 64'h70;
    hstateen_imsic = 1'b0;
    compare_now();
    csr_addr = 12'h256;
    vsiselect = 64'h31;
    compare_now();

    repeat (NCYCLES) begin
      csr_addr = $urandom;
      prvm = $urandom;
      virt = $urandom;
      miselect = {$urandom, $urandom};
      siselect = {$urandom, $urandom};
      vsiselect = {$urandom, $urandom};
      mvien_seie = $urandom;
      mstateen_aia = $urandom;
      mstateen_imsic = $urandom;
      hstateen_imsic = $urandom;
      compare_now();
    end

    $display("csr_permit UT: vectors=%0d module_checks=%0d errors=%0d", vectors, vectors * 2, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
