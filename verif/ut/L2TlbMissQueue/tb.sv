`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic io_csr_hgatp_changed;
  logic io_in_valid;
  logic [37:0] io_in_bits_req_info_vpn;
  logic [1:0] io_in_bits_req_info_s2xlate;
  logic [1:0] io_in_bits_req_info_source;
  logic io_in_bits_isLLptw;
  logic io_out_ready;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [37:0] g_io_out_bits_req_info_vpn;
  wire [37:0] i_io_out_bits_req_info_vpn;
  wire [1:0] g_io_out_bits_req_info_s2xlate;
  wire [1:0] i_io_out_bits_req_info_s2xlate;
  wire [1:0] g_io_out_bits_req_info_source;
  wire [1:0] i_io_out_bits_req_info_source;
  wire g_io_out_bits_isHptwReq;
  wire i_io_out_bits_isHptwReq;
  wire g_io_out_bits_isLLptw;
  wire i_io_out_bits_isLLptw;
  wire [2:0] g_io_out_bits_hptwId;
  wire [2:0] i_io_out_bits_hptwId;
  integer cycle;
  integer errors;
  integer checks;
  integer probe_errors;

  L2TlbMissQueue u_g (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_in_ready(g_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_req_info_vpn(io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(io_in_bits_req_info_source),
    .io_in_bits_isLLptw(io_in_bits_isLLptw),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_req_info_vpn(g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(g_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(g_io_out_bits_req_info_source),
    .io_out_bits_isHptwReq(g_io_out_bits_isHptwReq),
    .io_out_bits_isLLptw(g_io_out_bits_isLLptw),
    .io_out_bits_hptwId(g_io_out_bits_hptwId)
  );
  L2TlbMissQueue_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_in_ready(i_io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_req_info_vpn(io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(io_in_bits_req_info_source),
    .io_in_bits_isLLptw(io_in_bits_isLLptw),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_req_info_vpn(i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(i_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(i_io_out_bits_req_info_source),
    .io_out_bits_isHptwReq(i_io_out_bits_isHptwReq),
    .io_out_bits_isLLptw(i_io_out_bits_isLLptw),
    .io_out_bits_hptwId(i_io_out_bits_hptwId)
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
    io_sfence_valid = $urandom;
    io_csr_satp_changed = $urandom;
    io_csr_vsatp_changed = $urandom;
    io_csr_hgatp_changed = $urandom;
    io_in_valid = $urandom;
    io_in_bits_req_info_vpn = $urandom;
    io_in_bits_req_info_s2xlate = $urandom;
    io_in_bits_req_info_source = $urandom;
    io_in_bits_isLLptw = $urandom;
    io_out_ready = $urandom;
    // 偏置入/出 valid，使队列在满/空/中间各状态都被覆盖。
    io_in_valid  = ($urandom_range(0, 1) == 0);
    io_out_ready = ($urandom_range(0, 1) == 0);
    io_sfence_valid      = ($urandom_range(0, 255) == 0);
    io_csr_satp_changed  = ($urandom_range(0, 511) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 511) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 511) == 0);
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    probe_errors = 0;
    reset = 1'b1;
    drive_random();
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (cycle = 0; cycle < 200000; cycle++) begin
      @(negedge clock);
      drive_random();
      @(posedge clock);
      #1;
      checks++;
      if (!$isunknown(g_io_in_ready) && i_io_in_ready !== g_io_in_ready) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_in_ready: g=%0h i=%0h cycle=%0d", g_io_in_ready, i_io_in_ready, cycle);
      end
      if (!$isunknown(g_io_out_valid) && i_io_out_valid !== g_io_out_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_valid: g=%0h i=%0h cycle=%0d", g_io_out_valid, i_io_out_valid, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_vpn) && i_io_out_bits_req_info_vpn !== g_io_out_bits_req_info_vpn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_req_info_vpn: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_vpn, i_io_out_bits_req_info_vpn, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_s2xlate) && i_io_out_bits_req_info_s2xlate !== g_io_out_bits_req_info_s2xlate) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_req_info_s2xlate: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_s2xlate, i_io_out_bits_req_info_s2xlate, cycle);
      end
      if (!$isunknown(g_io_out_bits_req_info_source) && i_io_out_bits_req_info_source !== g_io_out_bits_req_info_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_req_info_source: g=%0h i=%0h cycle=%0d", g_io_out_bits_req_info_source, i_io_out_bits_req_info_source, cycle);
      end
      if (!$isunknown(g_io_out_bits_isHptwReq) && i_io_out_bits_isHptwReq !== g_io_out_bits_isHptwReq) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_isHptwReq: g=%0h i=%0h cycle=%0d", g_io_out_bits_isHptwReq, i_io_out_bits_isHptwReq, cycle);
      end
      if (!$isunknown(g_io_out_bits_isLLptw) && i_io_out_bits_isLLptw !== g_io_out_bits_isLLptw) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_isLLptw: g=%0h i=%0h cycle=%0d", g_io_out_bits_isLLptw, i_io_out_bits_isLLptw, cycle);
      end
      if (!$isunknown(g_io_out_bits_hptwId) && i_io_out_bits_hptwId !== g_io_out_bits_hptwId) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_out_bits_hptwId: g=%0h i=%0h cycle=%0d", g_io_out_bits_hptwId, i_io_out_bits_hptwId, cycle);
      end
      // 内部层次探针：golden Queue40 的环形指针/满标志 vs 手写核心。
      // 用于在 FM 因 golden ram_40x47 的 OOB-index lint 无法 link 时，
      // 直接证明控制状态机逐拍等价。
      if (u_g.io_out_q.enq_ptr_value !== u_i.u_core.enq_ptr) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE enq_ptr g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.enq_ptr_value, u_i.u_core.enq_ptr, cycle);
      end
      if (u_g.io_out_q.deq_ptr_value !== u_i.u_core.deq_ptr) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE deq_ptr g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.deq_ptr_value, u_i.u_core.deq_ptr, cycle);
      end
      if (u_g.io_out_q.maybe_full !== u_i.u_core.maybe_full) begin
        probe_errors++;
        if (probe_errors < 20) $display("PROBE maybe_full g=%0h i=%0h cycle=%0d",
          u_g.io_out_q.maybe_full, u_i.u_core.maybe_full, cycle);
      end
    end
    $display("L2TlbMissQueue_UT checks=%0d errors=%0d probe_errors=%0d", checks, errors, probe_errors);
    if (errors == 0 && probe_errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "L2TlbMissQueue mismatch");
    $finish;
  end
endmodule
