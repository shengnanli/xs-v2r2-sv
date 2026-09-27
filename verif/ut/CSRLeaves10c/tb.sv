`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  logic [63:0] data;
  logic [10:0] iid, iprio;
  logic wen;
  logic [11:0] csr_addr;
  logic [1:0] prvm;
  logic virt;
  logic [31:0] scounteren;
  logic sstateen_c;
  logic [28:0] of_vec, mcounteren, hcounteren;

  wire [63:0] pcfg_r, pcfg_m, mtopei_r, stopei_r, vstopei_r, tdata_r;
  wire [10:0] m_iid, m_prio, s_iid, s_prio, vs_iid, vs_prio;
  wire [3:0] t_type;
  wire t_dmode;
  wire [58:0] t_payload;
  wire [13:0] h_r, h_m, h_wdata;
  wire h_valid, denied;
  wire [31:0] sovf;
  wire [63:0] pma_r, pma_m, pmp32_r, pmp32_m;

  Pmpcfg6Module_xs u0(.rdata(pcfg_r), .regOut_ALL(pcfg_m), .cfgRData(data));
  MtopeiModule_xs u1(.rdata(mtopei_r), .regOut_IID(m_iid), .regOut_IPRIO(m_prio), .aiaToCSR_mtopei_IID(iid), .aiaToCSR_mtopei_IPRIO(iprio));
  StopeiModule_xs u2(.rdata(stopei_r), .regOut_IID(s_iid), .regOut_IPRIO(s_prio), .aiaToCSR_stopei_IID(iid), .aiaToCSR_stopei_IPRIO(iprio));
  VStopeiModule_xs u3(.rdata(vstopei_r), .regOut_IID(vs_iid), .regOut_IPRIO(vs_prio), .aiaToCSR_vstopei_IID(iid), .aiaToCSR_vstopei_IPRIO(iprio));
  Tdata1Module_xs u4(.rdata(tdata_r), .regOut_TYPE(t_type), .regOut_DMODE(t_dmode), .regOut_DATA(t_payload), .tdataRead_tdata1(data));
  HcontextModule_xs u5(.w_wen(wen), .w_wdata(data), .rdata(h_r), .regOut_HCONTEXT(h_m), .fromMcontext_HCONTEXT(data[27:14]), .toMcontext_valid(h_valid), .toMcontext_bits_HCONTEXT(h_wdata));
  SLevelPermitModule_xs u6(.io_in_csrAccess_addr(csr_addr), .io_in_privState_PRVM(prvm), .io_in_privState_V(virt), .io_in_xcounteren_scounteren(scounteren), .io_in_xstateen_sstateen0_C(sstateen_c), .io_out_sLevelPermit_EX_II(denied));
  ScountovfModule_xs u7(.rdata(sovf), .ofVec(of_vec), .privState_PRVM(prvm), .privState_V(virt), .mcounteren_HPM(mcounteren), .hcounteren_HPM(hcounteren));
  Pmaaddr0Module_xs u8(.rdata(pma_r), .regOut_ALL(pma_m), .addrRData_0(data));
  Pmpaddr32Module_xs u9(.rdata(pmp32_r), .regOut_ALL(pmp32_m));

  function automatic logic expected_denied;
    logic host_user;
    begin
      host_user = (prvm == 2'b00) && !virt;
      expected_denied = (((csr_addr > 12'hBFF) && (csr_addr < 12'hC20)) && host_user && !scounteren[csr_addr[4:0]]) ||
                        (((csr_addr[11:8] == 4'h8) || (csr_addr[11:6] == 6'h33)) && host_user && !sstateen_c);
    end
  endfunction

  function automatic [28:0] expected_overflows;
    begin
      if (&prvm) expected_overflows = of_vec;
      else if ((prvm == 2'b01) && !virt) expected_overflows = mcounteren & of_vec;
      else if ((prvm == 2'b01) && virt) expected_overflows = mcounteren & hcounteren & of_vec;
      else expected_overflows = '0;
    end
  endfunction

  task automatic compare_now;
    #1;
    vectors++;
    if ({pcfg_r, pcfg_m} !== {2{data}}) errors++;
    if ({mtopei_r, stopei_r, vstopei_r} !== {3{{37'b0, iid, 5'b0, iprio}}}) errors++;
    if ({m_iid, s_iid, vs_iid} !== {3{iid}} || {m_prio, s_prio, vs_prio} !== {3{iprio}}) errors++;
    if (tdata_r !== data || t_type !== data[63:60] || t_dmode !== data[59] || t_payload !== data[58:0]) errors++;
    if (h_r !== data[27:14] || h_m !== data[27:14] || h_valid !== wen || h_wdata !== data[13:0]) errors++;
    if (denied !== expected_denied()) errors++;
    if (sovf !== {expected_overflows(), 3'b0}) errors++;
    if ({pma_r, pma_m} !== {2{data}} || {pmp32_r, pmp32_m} !== '0) errors++;
  endtask

  initial begin
    data='0; iid='0; iprio='0; wen=0; csr_addr='0; prvm='0; virt=0;
    scounteren='0; sstateen_c=0; of_vec='0; mcounteren='0; hcounteren='0;
    compare_now();
    data='1; iid='1; iprio='1; wen=1; csr_addr='1; prvm='1; virt=1;
    scounteren='1; sstateen_c=1; of_vec='1; mcounteren='1; hcounteren='1;
    compare_now();
    repeat (NCYCLES) begin
      data={$urandom,$urandom}; iid=$urandom; iprio=$urandom; wen=$urandom;
      csr_addr=$urandom; prvm=$urandom; virt=$urandom; scounteren=$urandom;
      sstateen_c=$urandom; of_vec=$urandom; mcounteren=$urandom; hcounteren=$urandom;
      compare_now();
    end
    $display("CSRLeaves10c UT: vectors=%0d module_checks=%0d errors=%0d", vectors, vectors*10, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
