`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic [3:0] io_csr_vsatp_mode;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_virt;
  logic io_csr_priv_virt_changed;
  logic io_in_valid;
  logic [37:0] io_in_bits_vpn;
  logic io_out_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [37:0] g_io_out_bits_req_info_vpn;
  wire [37:0] i_io_out_bits_req_info_vpn;
  wire [1:0] g_io_out_bits_req_info_s2xlate;
  wire [1:0] i_io_out_bits_req_info_s2xlate;
  integer cycle;
  integer errors;
  integer checks;

  L2TlbPrefetch u_g (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_mode(io_csr_vsatp_mode),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_virt(io_csr_priv_virt),
    .io_csr_priv_virt_changed(io_csr_priv_virt_changed),
    .io_in_valid(io_in_valid),
    .io_in_bits_vpn(io_in_bits_vpn),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_req_info_vpn(g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(g_io_out_bits_req_info_s2xlate)
  );
  L2TlbPrefetch_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_mode(io_csr_vsatp_mode),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_priv_virt(io_csr_priv_virt),
    .io_csr_priv_virt_changed(io_csr_priv_virt_changed),
    .io_in_valid(io_in_valid),
    .io_in_bits_vpn(io_in_bits_vpn),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_req_info_vpn(i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(i_io_out_bits_req_info_s2xlate)
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
    io_sfence_valid = $urandom;
    io_csr_satp_changed = $urandom;
    io_csr_vsatp_mode = $urandom;
    io_csr_vsatp_changed = $urandom;
    io_csr_hgatp_mode = $urandom;
    io_csr_hgatp_changed = $urandom;
    io_csr_priv_virt = $urandom;
    io_csr_priv_virt_changed = $urandom;
    io_in_valid = $urandom;
    io_in_bits_vpn = $urandom;
    io_out_ready = $urandom;
    // 偏置使去重窗口与 out.fire 路径都被频繁激发。
    io_in_valid   = ($urandom_range(0, 1) == 0);
    io_out_ready  = ($urandom_range(0, 3) != 0);
    io_csr_priv_virt = ($urandom_range(0, 1) == 0);
    io_csr_vsatp_mode = ($urandom_range(0, 2) == 0) ? 4'h0 : 4'h8;
    io_csr_hgatp_mode = ($urandom_range(0, 2) == 0) ? 4'h0 : 4'h8;
    // 把 in_vpn 限制在小范围，使 next_line 经常命中去重窗口。
    io_in_bits_vpn = $urandom_range(0, 255);
    io_sfence_valid    = ($urandom_range(0, 63) == 0);
    io_csr_satp_changed  = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
    // V 位（priv.virt）变化同样是 flush 源（golden L2TlbPrefetch.sv:117 五项 OR）。
    io_csr_priv_virt_changed = ($urandom_range(0, 255) == 0);
  end
  endtask

  // ---------------------------------------------------------------------------
  // 定向激励：**只**用 io_csr_priv_virt_changed 触发 flush（其余四根 flush 源全 0），
  // 分别验证它清 v（在途预取请求作废）与清 old_v（去重窗口作废）两个效果。
  // 漏掉这一 OR 项的核在这两处都会与 golden 分道扬镳。
  // ---------------------------------------------------------------------------
  task automatic quiet_flush_sources;
  begin
    io_sfence_valid          = 1'b0;
    io_csr_satp_changed      = 1'b0;
    io_csr_vsatp_changed     = 1'b0;
    io_csr_hgatp_changed     = 1'b0;
    io_csr_priv_virt_changed = 1'b0;
  end
  endtask

  task automatic directed_priv_virt_flush;
    int unsigned d_errs;
  begin
    d_errs = 0;
    quiet_flush_sources();
    io_csr_priv_virt  = 1'b0;
    io_csr_vsatp_mode = 4'h0;
    io_csr_hgatp_mode = 4'h0;
    io_in_valid       = 1'b0;
    io_out_ready      = 1'b0;

    // --- 用例 A：产生一个在途预取请求(v=1)，只脉冲 priv_virt_changed，应被清掉。
    @(negedge clock); io_in_valid = 1'b1; io_in_bits_vpn = 38'h1000;
    @(posedge clock);
    @(negedge clock); io_in_valid = 1'b0;
    @(posedge clock); #1;
    if (g_io_out_valid !== 1'b1) begin
      d_errs++; $display("DIRECTED setup FAILED: golden v 未拉起 (g=%0h)", g_io_out_valid);
    end
    @(negedge clock); io_csr_priv_virt_changed = 1'b1;
    @(posedge clock);
    @(negedge clock); io_csr_priv_virt_changed = 1'b0;
    #1;
    if (g_io_out_valid !== i_io_out_valid) begin
      d_errs++;
      $display("DIRECTED A (priv_virt_changed 清在途 v) MISMATCH: g=%0h i=%0h",
               g_io_out_valid, i_io_out_valid);
    end
    @(posedge clock);

    // --- 用例 B：让一个预取请求 fire 进去重窗口，只脉冲 priv_virt_changed 清窗口，
    //     再送同一个 vpn —— golden 窗口已清应再次产生请求，漏 OR 项的核会当成重复丢弃。
    @(negedge clock); quiet_flush_sources(); io_in_valid = 1'b1; io_in_bits_vpn = 38'h2000;
    @(posedge clock);
    @(negedge clock); io_in_valid = 1'b0; io_out_ready = 1'b1;   // 让 out.fire 写入窗口
    @(posedge clock);
    @(negedge clock); io_out_ready = 1'b0; io_csr_priv_virt_changed = 1'b1;
    @(posedge clock);
    @(negedge clock); io_csr_priv_virt_changed = 1'b0;
    @(posedge clock);
    @(negedge clock); io_in_valid = 1'b1; io_in_bits_vpn = 38'h2000;  // 同一行，再来一次
    @(posedge clock);
    @(negedge clock); io_in_valid = 1'b0;
    @(posedge clock); #1;
    if (g_io_out_valid !== i_io_out_valid) begin
      d_errs++;
      $display("DIRECTED B (priv_virt_changed 清去重窗口 old_v) MISMATCH: g=%0h i=%0h",
               g_io_out_valid, i_io_out_valid);
    end
    errors += d_errs;
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
    reset = 1'b1;
    drive_random();
    repeat (5) @(posedge clock);
    reset = 1'b0;
    directed_priv_virt_flush();
    for (cycle = 0; cycle < 200000; cycle++) begin
      @(negedge clock);
      drive_random();
      @(posedge clock);
      #1;
      checks++;
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
    end
    $display("L2TlbPrefetch_UT checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "L2TlbPrefetch mismatch");
    $finish;
  end
endmodule
