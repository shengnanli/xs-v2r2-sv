`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic [3:0] io_csr_hgatp_mode;
  logic [15:0] io_csr_hgatp_vmid;
  logic [43:0] io_csr_hgatp_ppn;
  logic io_csr_hgatp_changed;
  logic io_csr_mPBMTE;
  logic io_req_valid;
  logic [1:0] io_req_bits_source;
  logic [2:0] io_req_bits_id;
  logic [37:0] io_req_bits_gvpn;
  logic [35:0] io_req_bits_ppn;
  logic io_req_bits_l3Hit;
  logic io_req_bits_l2Hit;
  logic io_req_bits_l1Hit;
  logic io_req_bits_bypassed;
  logic io_resp_ready;
  logic io_mem_req_ready;
  logic io_mem_resp_valid;
  logic [63:0] io_mem_resp_bits;
  logic io_mem_mask;
  logic io_pmp_resp_ld;
  logic io_pmp_resp_mmio;
  wire g_io_req_ready;
  wire i_io_req_ready;
  wire g_io_resp_valid;
  wire i_io_resp_valid;
  wire [37:0] g_io_resp_bits_resp_entry_tag;
  wire [37:0] i_io_resp_bits_resp_entry_tag;
  wire [13:0] g_io_resp_bits_resp_entry_vmid;
  wire [13:0] i_io_resp_bits_resp_entry_vmid;
  wire g_io_resp_bits_resp_entry_n;
  wire i_io_resp_bits_resp_entry_n;
  wire [1:0] g_io_resp_bits_resp_entry_pbmt;
  wire [1:0] i_io_resp_bits_resp_entry_pbmt;
  wire [37:0] g_io_resp_bits_resp_entry_ppn;
  wire [37:0] i_io_resp_bits_resp_entry_ppn;
  wire g_io_resp_bits_resp_entry_perm_d;
  wire i_io_resp_bits_resp_entry_perm_d;
  wire g_io_resp_bits_resp_entry_perm_a;
  wire i_io_resp_bits_resp_entry_perm_a;
  wire g_io_resp_bits_resp_entry_perm_g;
  wire i_io_resp_bits_resp_entry_perm_g;
  wire g_io_resp_bits_resp_entry_perm_u;
  wire i_io_resp_bits_resp_entry_perm_u;
  wire g_io_resp_bits_resp_entry_perm_x;
  wire i_io_resp_bits_resp_entry_perm_x;
  wire g_io_resp_bits_resp_entry_perm_w;
  wire i_io_resp_bits_resp_entry_perm_w;
  wire g_io_resp_bits_resp_entry_perm_r;
  wire i_io_resp_bits_resp_entry_perm_r;
  wire [1:0] g_io_resp_bits_resp_entry_level;
  wire [1:0] i_io_resp_bits_resp_entry_level;
  wire g_io_resp_bits_resp_gpf;
  wire i_io_resp_bits_resp_gpf;
  wire g_io_resp_bits_resp_gaf;
  wire i_io_resp_bits_resp_gaf;
  wire [2:0] g_io_resp_bits_id;
  wire [2:0] i_io_resp_bits_id;
  wire g_io_mem_req_valid;
  wire i_io_mem_req_valid;
  wire [47:0] g_io_mem_req_bits_addr;
  wire [47:0] i_io_mem_req_bits_addr;
  wire g_io_mem_req_bits_hptw_bypassed;
  wire i_io_mem_req_bits_hptw_bypassed;
  wire [37:0] g_io_refill_req_info_vpn;
  wire [37:0] i_io_refill_req_info_vpn;
  wire [1:0] g_io_refill_req_info_source;
  wire [1:0] i_io_refill_req_info_source;
  wire [1:0] g_io_refill_level;
  wire [1:0] i_io_refill_level;
  wire [47:0] g_io_pmp_req_bits_addr;
  wire [47:0] i_io_pmp_req_bits_addr;
  integer cycle;
  integer errors;
  integer checks;

  HPTW u_g (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn(io_csr_hgatp_ppn),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_req_ready(g_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_id(io_req_bits_id),
    .io_req_bits_gvpn(io_req_bits_gvpn),
    .io_req_bits_ppn(io_req_bits_ppn),
    .io_req_bits_l3Hit(io_req_bits_l3Hit),
    .io_req_bits_l2Hit(io_req_bits_l2Hit),
    .io_req_bits_l1Hit(io_req_bits_l1Hit),
    .io_req_bits_bypassed(io_req_bits_bypassed),
    .io_resp_ready(io_resp_ready),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_resp_entry_tag(g_io_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid(g_io_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n(g_io_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt(g_io_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn(g_io_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d(g_io_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a(g_io_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g(g_io_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u(g_io_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x(g_io_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w(g_io_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r(g_io_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level(g_io_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf(g_io_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf(g_io_resp_bits_resp_gaf),
    .io_resp_bits_id(g_io_resp_bits_id),
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(g_io_mem_req_valid),
    .io_mem_req_bits_addr(g_io_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed(g_io_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits(io_mem_resp_bits),
    .io_mem_mask(io_mem_mask),
    .io_refill_req_info_vpn(g_io_refill_req_info_vpn),
    .io_refill_req_info_source(g_io_refill_req_info_source),
    .io_refill_level(g_io_refill_level),
    .io_pmp_req_bits_addr(g_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio)
  );
  HPTW_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_sfence_valid(io_sfence_valid),
    .io_csr_satp_changed(io_csr_satp_changed),
    .io_csr_vsatp_changed(io_csr_vsatp_changed),
    .io_csr_hgatp_mode(io_csr_hgatp_mode),
    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),
    .io_csr_hgatp_ppn(io_csr_hgatp_ppn),
    .io_csr_hgatp_changed(io_csr_hgatp_changed),
    .io_csr_mPBMTE(io_csr_mPBMTE),
    .io_req_ready(i_io_req_ready),
    .io_req_valid(io_req_valid),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_id(io_req_bits_id),
    .io_req_bits_gvpn(io_req_bits_gvpn),
    .io_req_bits_ppn(io_req_bits_ppn),
    .io_req_bits_l3Hit(io_req_bits_l3Hit),
    .io_req_bits_l2Hit(io_req_bits_l2Hit),
    .io_req_bits_l1Hit(io_req_bits_l1Hit),
    .io_req_bits_bypassed(io_req_bits_bypassed),
    .io_resp_ready(io_resp_ready),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_resp_entry_tag(i_io_resp_bits_resp_entry_tag),
    .io_resp_bits_resp_entry_vmid(i_io_resp_bits_resp_entry_vmid),
    .io_resp_bits_resp_entry_n(i_io_resp_bits_resp_entry_n),
    .io_resp_bits_resp_entry_pbmt(i_io_resp_bits_resp_entry_pbmt),
    .io_resp_bits_resp_entry_ppn(i_io_resp_bits_resp_entry_ppn),
    .io_resp_bits_resp_entry_perm_d(i_io_resp_bits_resp_entry_perm_d),
    .io_resp_bits_resp_entry_perm_a(i_io_resp_bits_resp_entry_perm_a),
    .io_resp_bits_resp_entry_perm_g(i_io_resp_bits_resp_entry_perm_g),
    .io_resp_bits_resp_entry_perm_u(i_io_resp_bits_resp_entry_perm_u),
    .io_resp_bits_resp_entry_perm_x(i_io_resp_bits_resp_entry_perm_x),
    .io_resp_bits_resp_entry_perm_w(i_io_resp_bits_resp_entry_perm_w),
    .io_resp_bits_resp_entry_perm_r(i_io_resp_bits_resp_entry_perm_r),
    .io_resp_bits_resp_entry_level(i_io_resp_bits_resp_entry_level),
    .io_resp_bits_resp_gpf(i_io_resp_bits_resp_gpf),
    .io_resp_bits_resp_gaf(i_io_resp_bits_resp_gaf),
    .io_resp_bits_id(i_io_resp_bits_id),
    .io_mem_req_ready(io_mem_req_ready),
    .io_mem_req_valid(i_io_mem_req_valid),
    .io_mem_req_bits_addr(i_io_mem_req_bits_addr),
    .io_mem_req_bits_hptw_bypassed(i_io_mem_req_bits_hptw_bypassed),
    .io_mem_resp_valid(io_mem_resp_valid),
    .io_mem_resp_bits(io_mem_resp_bits),
    .io_mem_mask(io_mem_mask),
    .io_refill_req_info_vpn(i_io_refill_req_info_vpn),
    .io_refill_req_info_source(i_io_refill_req_info_source),
    .io_refill_level(i_io_refill_level),
    .io_pmp_req_bits_addr(i_io_pmp_req_bits_addr),
    .io_pmp_resp_ld(io_pmp_resp_ld),
    .io_pmp_resp_mmio(io_pmp_resp_mmio)
  );

  initial clock = 1'b0;
  always #5 clock = ~clock;

  task automatic drive_random;
  begin
    io_sfence_valid = $urandom;
    io_csr_satp_changed = $urandom;
    io_csr_vsatp_changed = $urandom;
    io_csr_hgatp_mode = $urandom;
    io_csr_hgatp_vmid = $urandom;
    io_csr_hgatp_ppn = $urandom;
    io_csr_hgatp_changed = $urandom;
    io_csr_mPBMTE = $urandom;
    io_req_valid = $urandom;
    io_req_bits_source = $urandom;
    io_req_bits_id = $urandom;
    io_req_bits_gvpn = $urandom;
    io_req_bits_ppn = $urandom;
    io_req_bits_l3Hit = $urandom;
    io_req_bits_l2Hit = $urandom;
    io_req_bits_l1Hit = $urandom;
    io_req_bits_bypassed = $urandom;
    io_resp_ready = $urandom;
    io_mem_req_ready = $urandom;
    io_mem_resp_valid = $urandom;
    io_mem_resp_bits = $urandom;
    io_mem_mask = $urandom;
    io_pmp_resp_ld = $urandom;
    io_pmp_resp_mmio = $urandom;
    // 约束握手环境，避免无界 backpressure 干扰随机 UT 收敛。
    io_resp_ready    = ($urandom_range(0, 7) != 0);
    io_mem_req_ready = ($urandom_range(0, 3) != 0);
    io_mem_mask      = ($urandom_range(0, 31) == 0);
    // hgatp 至少要是 Sv39x4/Sv48x4 才会真正走表（Bare 不会发请求）。
    io_csr_hgatp_mode = ($urandom_range(0, 3) == 0) ? 4'h0 : (($urandom_range(0, 1) == 0) ? 4'h8 : 4'h9);
    io_req_valid       = ($urandom_range(0, 3) == 0);
    io_req_bits_l1Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_l2Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_l3Hit  = ($urandom_range(0, 7) == 0);
    io_req_bits_bypassed = ($urandom_range(0, 1) == 0);
    io_mem_resp_valid  = ($urandom_range(0, 3) == 0);
    io_sfence_valid    = ($urandom_range(0, 127) == 0);
    io_csr_satp_changed  = ($urandom_range(0, 255) == 0);
    io_csr_vsatp_changed = ($urandom_range(0, 255) == 0);
    io_csr_hgatp_changed = ($urandom_range(0, 255) == 0);
  end
  endtask

  initial begin
    errors = 0;
    checks = 0;
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
      if (!$isunknown(g_io_req_ready) && i_io_req_ready !== g_io_req_ready) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_req_ready: g=%0h i=%0h cycle=%0d", g_io_req_ready, i_io_req_ready, cycle);
      end
      if (!$isunknown(g_io_resp_valid) && i_io_resp_valid !== g_io_resp_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_valid: g=%0h i=%0h cycle=%0d", g_io_resp_valid, i_io_resp_valid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_tag) && i_io_resp_bits_resp_entry_tag !== g_io_resp_bits_resp_entry_tag) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_tag: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_tag, i_io_resp_bits_resp_entry_tag, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_vmid) && i_io_resp_bits_resp_entry_vmid !== g_io_resp_bits_resp_entry_vmid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_vmid: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_vmid, i_io_resp_bits_resp_entry_vmid, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_n) && i_io_resp_bits_resp_entry_n !== g_io_resp_bits_resp_entry_n) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_n: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_n, i_io_resp_bits_resp_entry_n, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_pbmt) && i_io_resp_bits_resp_entry_pbmt !== g_io_resp_bits_resp_entry_pbmt) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_pbmt: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_pbmt, i_io_resp_bits_resp_entry_pbmt, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_ppn) && i_io_resp_bits_resp_entry_ppn !== g_io_resp_bits_resp_entry_ppn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_ppn: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_ppn, i_io_resp_bits_resp_entry_ppn, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_d) && i_io_resp_bits_resp_entry_perm_d !== g_io_resp_bits_resp_entry_perm_d) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_d: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_d, i_io_resp_bits_resp_entry_perm_d, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_a) && i_io_resp_bits_resp_entry_perm_a !== g_io_resp_bits_resp_entry_perm_a) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_a: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_a, i_io_resp_bits_resp_entry_perm_a, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_g) && i_io_resp_bits_resp_entry_perm_g !== g_io_resp_bits_resp_entry_perm_g) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_g: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_g, i_io_resp_bits_resp_entry_perm_g, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_u) && i_io_resp_bits_resp_entry_perm_u !== g_io_resp_bits_resp_entry_perm_u) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_u: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_u, i_io_resp_bits_resp_entry_perm_u, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_x) && i_io_resp_bits_resp_entry_perm_x !== g_io_resp_bits_resp_entry_perm_x) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_x: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_x, i_io_resp_bits_resp_entry_perm_x, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_w) && i_io_resp_bits_resp_entry_perm_w !== g_io_resp_bits_resp_entry_perm_w) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_w: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_w, i_io_resp_bits_resp_entry_perm_w, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_perm_r) && i_io_resp_bits_resp_entry_perm_r !== g_io_resp_bits_resp_entry_perm_r) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_perm_r: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_perm_r, i_io_resp_bits_resp_entry_perm_r, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_entry_level) && i_io_resp_bits_resp_entry_level !== g_io_resp_bits_resp_entry_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_entry_level: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_entry_level, i_io_resp_bits_resp_entry_level, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_gpf) && i_io_resp_bits_resp_gpf !== g_io_resp_bits_resp_gpf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_gpf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_gpf, i_io_resp_bits_resp_gpf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_resp_gaf) && i_io_resp_bits_resp_gaf !== g_io_resp_bits_resp_gaf) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_resp_gaf: g=%0h i=%0h cycle=%0d", g_io_resp_bits_resp_gaf, i_io_resp_bits_resp_gaf, cycle);
      end
      if (!$isunknown(g_io_resp_bits_id) && i_io_resp_bits_id !== g_io_resp_bits_id) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_resp_bits_id: g=%0h i=%0h cycle=%0d", g_io_resp_bits_id, i_io_resp_bits_id, cycle);
      end
      if (!$isunknown(g_io_mem_req_valid) && i_io_mem_req_valid !== g_io_mem_req_valid) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_mem_req_valid: g=%0h i=%0h cycle=%0d", g_io_mem_req_valid, i_io_mem_req_valid, cycle);
      end
      if (!$isunknown(g_io_mem_req_bits_addr) && i_io_mem_req_bits_addr !== g_io_mem_req_bits_addr) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_mem_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_mem_req_bits_addr, i_io_mem_req_bits_addr, cycle);
      end
      if (!$isunknown(g_io_mem_req_bits_hptw_bypassed) && i_io_mem_req_bits_hptw_bypassed !== g_io_mem_req_bits_hptw_bypassed) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_mem_req_bits_hptw_bypassed: g=%0h i=%0h cycle=%0d", g_io_mem_req_bits_hptw_bypassed, i_io_mem_req_bits_hptw_bypassed, cycle);
      end
      if (!$isunknown(g_io_refill_req_info_vpn) && i_io_refill_req_info_vpn !== g_io_refill_req_info_vpn) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_req_info_vpn: g=%0h i=%0h cycle=%0d", g_io_refill_req_info_vpn, i_io_refill_req_info_vpn, cycle);
      end
      if (!$isunknown(g_io_refill_req_info_source) && i_io_refill_req_info_source !== g_io_refill_req_info_source) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_req_info_source: g=%0h i=%0h cycle=%0d", g_io_refill_req_info_source, i_io_refill_req_info_source, cycle);
      end
      if (!$isunknown(g_io_refill_level) && i_io_refill_level !== g_io_refill_level) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_refill_level: g=%0h i=%0h cycle=%0d", g_io_refill_level, i_io_refill_level, cycle);
      end
      if (!$isunknown(g_io_pmp_req_bits_addr) && i_io_pmp_req_bits_addr !== g_io_pmp_req_bits_addr) begin
        errors++;
        if (errors < 20) $display("MISMATCH io_pmp_req_bits_addr: g=%0h i=%0h cycle=%0d", g_io_pmp_req_bits_addr, i_io_pmp_req_bits_addr, cycle);
      end
    end
    $display("HPTW_UT checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $fatal(1, "HPTW mismatch");
    $finish;
  end
endmodule
