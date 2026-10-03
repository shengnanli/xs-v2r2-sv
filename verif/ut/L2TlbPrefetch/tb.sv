// L2TlbPrefetch 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= L2TlbPrefetch =================
  int unsigned p_mode = 0;
  logic [37:0] p_base = '0;
  logic p_reset;
  logic p_io_sfence_valid;
  logic p_io_csr_satp_changed;
  logic [3:0] p_io_csr_vsatp_mode;
  logic p_io_csr_vsatp_changed;
  logic [3:0] p_io_csr_hgatp_mode;
  logic p_io_csr_hgatp_changed;
  logic p_io_csr_priv_virt;
  logic p_io_csr_priv_virt_changed;
  logic p_io_in_valid;
  logic [37:0] p_io_in_bits_vpn;
  logic p_io_out_ready;
  wire  p_g_io_out_valid, p_i_io_out_valid;
  logic p_s0_io_out_valid = '0, p_s1_io_out_valid = '0;
  wire  [37:0] p_g_io_out_bits_req_info_vpn, p_i_io_out_bits_req_info_vpn;
  logic [37:0] p_s0_io_out_bits_req_info_vpn = '0, p_s1_io_out_bits_req_info_vpn = '0;
  wire  [1:0] p_g_io_out_bits_req_info_s2xlate, p_i_io_out_bits_req_info_s2xlate;
  logic [1:0] p_s0_io_out_bits_req_info_s2xlate = '0, p_s1_io_out_bits_req_info_s2xlate = '0;
  int p_cov_fire = 0;
  int p_cov_held = 0;
  int p_cov_dedup_hit = 0;
  int p_cov_flush_while_valid = 0;
  int p_cov_window_full = 0;
  int p_cov_s2x_all = 0;
  int p_cov_s2x_s1 = 0;
  int p_cov_s2x_s2 = 0;
  int p_cov_s2x_none = 0;
  logic [0:0] p_armed = '0;
  int p_armed_at = -1;
  L2TlbPrefetch p_u_gold (
    .clock(clk),
    .reset(p_reset),
    .io_sfence_valid(p_io_sfence_valid),
    .io_csr_satp_changed(p_io_csr_satp_changed),
    .io_csr_vsatp_mode(p_io_csr_vsatp_mode),
    .io_csr_vsatp_changed(p_io_csr_vsatp_changed),
    .io_csr_hgatp_mode(p_io_csr_hgatp_mode),
    .io_csr_hgatp_changed(p_io_csr_hgatp_changed),
    .io_csr_priv_virt(p_io_csr_priv_virt),
    .io_csr_priv_virt_changed(p_io_csr_priv_virt_changed),
    .io_in_valid(p_io_in_valid),
    .io_in_bits_vpn(p_io_in_bits_vpn),
    .io_out_ready(p_io_out_ready),
    .io_out_valid(p_g_io_out_valid),
    .io_out_bits_req_info_vpn(p_g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(p_g_io_out_bits_req_info_s2xlate)
  );
  L2TlbPrefetch_xs p_u_impl (
    .clock(clk),
    .reset(p_reset),
    .io_sfence_valid(p_io_sfence_valid),
    .io_csr_satp_changed(p_io_csr_satp_changed),
    .io_csr_vsatp_mode(p_io_csr_vsatp_mode),
    .io_csr_vsatp_changed(p_io_csr_vsatp_changed),
    .io_csr_hgatp_mode(p_io_csr_hgatp_mode),
    .io_csr_hgatp_changed(p_io_csr_hgatp_changed),
    .io_csr_priv_virt(p_io_csr_priv_virt),
    .io_csr_priv_virt_changed(p_io_csr_priv_virt_changed),
    .io_in_valid(p_io_in_valid),
    .io_in_bits_vpn(p_io_in_bits_vpn),
    .io_out_ready(p_io_out_ready),
    .io_out_valid(p_i_io_out_valid),
    .io_out_bits_req_info_vpn(p_i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(p_i_io_out_bits_req_info_s2xlate)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) p_mode = $urandom_range(0, 15);
      p_io_sfence_valid = 1'($urandom);
      p_io_csr_satp_changed = 1'($urandom);
      p_io_csr_vsatp_mode = 4'($urandom);
      p_io_csr_vsatp_changed = 1'($urandom);
      p_io_csr_hgatp_mode = 4'($urandom);
      p_io_csr_hgatp_changed = 1'($urandom);
      p_io_csr_priv_virt = 1'($urandom);
      p_io_csr_priv_virt_changed = 1'($urandom);
      p_io_in_valid = 1'($urandom);
      p_io_in_bits_vpn = 38'({$urandom, $urandom});
      p_io_out_ready = 1'($urandom);
      p_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p
        p_io_sfence_valid          = ($urandom_range(0, 255) == 0);
        p_io_csr_satp_changed      = ($urandom_range(0, 255) == 0);
        p_io_csr_vsatp_changed     = ($urandom_range(0, 255) == 0);
        p_io_csr_hgatp_changed     = ($urandom_range(0, 255) == 0);
        p_io_csr_priv_virt_changed = ($urandom_range(0, 255) == 0);
        if (cyc % 4000 == 0) p_base = {$urandom, $urandom};
        p_io_in_bits_vpn = {p_base[37:9], 6'($urandom_range(0, 63)), 3'($urandom)};
        case (p_mode[1:0])
          2'd0: begin p_io_in_valid = ($urandom_range(0, 3) == 0); p_io_out_ready = ($urandom_range(0, 7) == 0); end
          2'd1: begin p_io_in_valid = ($urandom_range(0, 1) == 0); p_io_out_ready = 1'b1; end
          2'd2: begin p_io_in_valid = 1'b1;                      p_io_out_ready = ($urandom_range(0, 1) == 0); end
          default: ;
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&p_armed)) begin
        checks++;
        if (p_g_io_out_valid !== p_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbPrefetch.io_out_valid g=%h i=%h", cyc, p_g_io_out_valid, p_i_io_out_valid);
        end
        p_s1_io_out_valid |= p_g_io_out_valid;
        p_s0_io_out_valid |= ~p_g_io_out_valid;
        checks++;
        if (p_g_io_out_bits_req_info_vpn !== p_i_io_out_bits_req_info_vpn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbPrefetch.io_out_bits_req_info_vpn g=%h i=%h", cyc, p_g_io_out_bits_req_info_vpn, p_i_io_out_bits_req_info_vpn);
        end
        p_s1_io_out_bits_req_info_vpn |= p_g_io_out_bits_req_info_vpn;
        p_s0_io_out_bits_req_info_vpn |= ~p_g_io_out_bits_req_info_vpn;
        checks++;
        if (p_g_io_out_bits_req_info_s2xlate !== p_i_io_out_bits_req_info_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbPrefetch.io_out_bits_req_info_s2xlate g=%h i=%h", cyc, p_g_io_out_bits_req_info_s2xlate, p_i_io_out_bits_req_info_s2xlate);
        end
        p_s1_io_out_bits_req_info_s2xlate |= p_g_io_out_bits_req_info_s2xlate;
        p_s0_io_out_bits_req_info_s2xlate |= ~p_g_io_out_bits_req_info_s2xlate;
        if (p_g_io_out_valid && p_io_out_ready) p_cov_fire++;
        if (p_g_io_out_valid && !p_io_out_ready) p_cov_held++;
        if (p_io_in_valid && p_u_gold.input_valid_probe == 1'b0 && !p_u_gold.flush) p_cov_dedup_hit++;
        if (p_g_io_out_valid && p_u_gold.flush) p_cov_flush_while_valid++;
        if (&{p_u_gold.old_v_0, p_u_gold.old_v_1, p_u_gold.old_v_2, p_u_gold.old_v_3}) p_cov_window_full++;
        if (p_g_io_out_bits_req_info_s2xlate == 2'd3) p_cov_s2x_all++;
        if (p_g_io_out_bits_req_info_s2xlate == 2'd1) p_cov_s2x_s1++;
        if (p_g_io_out_bits_req_info_s2xlate == 2'd2) p_cov_s2x_s2++;
        if (p_g_io_out_bits_req_info_s2xlate == 2'd0) p_cov_s2x_none++;
      end
      if (p_io_in_valid) p_armed[0] = 1'b1;
      if (p_armed_at < 0 && (&p_armed)) p_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(p_s0_io_out_valid && p_s1_io_out_valid)) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_valid 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[3] && p_s1_io_out_bits_req_info_vpn[3])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[4] && p_s1_io_out_bits_req_info_vpn[4])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[4] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[5] && p_s1_io_out_bits_req_info_vpn[5])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[5] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[6] && p_s1_io_out_bits_req_info_vpn[6])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[6] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[7] && p_s1_io_out_bits_req_info_vpn[7])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[7] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[8] && p_s1_io_out_bits_req_info_vpn[8])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[8] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[9] && p_s1_io_out_bits_req_info_vpn[9])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[9] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[10] && p_s1_io_out_bits_req_info_vpn[10])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[10] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[11] && p_s1_io_out_bits_req_info_vpn[11])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[11] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[12] && p_s1_io_out_bits_req_info_vpn[12])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[12] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[13] && p_s1_io_out_bits_req_info_vpn[13])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[13] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[14] && p_s1_io_out_bits_req_info_vpn[14])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[14] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[15] && p_s1_io_out_bits_req_info_vpn[15])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[15] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[16] && p_s1_io_out_bits_req_info_vpn[16])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[16] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[17] && p_s1_io_out_bits_req_info_vpn[17])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[17] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[18] && p_s1_io_out_bits_req_info_vpn[18])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[18] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[19] && p_s1_io_out_bits_req_info_vpn[19])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[19] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[20] && p_s1_io_out_bits_req_info_vpn[20])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[20] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[21] && p_s1_io_out_bits_req_info_vpn[21])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[21] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[22] && p_s1_io_out_bits_req_info_vpn[22])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[22] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[23] && p_s1_io_out_bits_req_info_vpn[23])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[23] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[24] && p_s1_io_out_bits_req_info_vpn[24])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[24] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[25] && p_s1_io_out_bits_req_info_vpn[25])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[25] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[26] && p_s1_io_out_bits_req_info_vpn[26])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[26] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[27] && p_s1_io_out_bits_req_info_vpn[27])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[27] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[28] && p_s1_io_out_bits_req_info_vpn[28])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[28] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[29] && p_s1_io_out_bits_req_info_vpn[29])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[29] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[30] && p_s1_io_out_bits_req_info_vpn[30])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[30] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[31] && p_s1_io_out_bits_req_info_vpn[31])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[31] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[32] && p_s1_io_out_bits_req_info_vpn[32])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[32] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[33] && p_s1_io_out_bits_req_info_vpn[33])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[33] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[34] && p_s1_io_out_bits_req_info_vpn[34])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[34] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[35] && p_s1_io_out_bits_req_info_vpn[35])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[35] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[36] && p_s1_io_out_bits_req_info_vpn[36])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[36] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_vpn[37] && p_s1_io_out_bits_req_info_vpn[37])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_vpn[37] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_s2xlate[0] && p_s1_io_out_bits_req_info_s2xlate[0])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_s2xlate[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_req_info_s2xlate[1] && p_s1_io_out_bits_req_info_s2xlate[1])) begin cov_fail++; $display("[COV] L2TlbPrefetch.io_out_bits_req_info_s2xlate[1] 未见过 0 和 1"); end
    $display("[ARM] L2TlbPrefetch armed_at=%0d", p_armed_at);
    if (p_armed_at < 0) begin cov_fail++; $display("[ARM] L2TlbPrefetch 从未 arm"); end
    $display("[COV] L2TlbPrefetch.fire = %0d", p_cov_fire);
    if (p_cov_fire < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.fire < 200"); end
    $display("[COV] L2TlbPrefetch.held = %0d", p_cov_held);
    if (p_cov_held < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.held < 200"); end
    $display("[COV] L2TlbPrefetch.dedup_hit = %0d", p_cov_dedup_hit);
    if (p_cov_dedup_hit < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.dedup_hit < 200"); end
    $display("[COV] L2TlbPrefetch.flush_while_valid = %0d", p_cov_flush_while_valid);
    if (p_cov_flush_while_valid < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.flush_while_valid < 200"); end
    $display("[COV] L2TlbPrefetch.window_full = %0d", p_cov_window_full);
    if (p_cov_window_full < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.window_full < 200"); end
    $display("[COV] L2TlbPrefetch.s2x_all = %0d", p_cov_s2x_all);
    if (p_cov_s2x_all < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.s2x_all < 200"); end
    $display("[COV] L2TlbPrefetch.s2x_s1 = %0d", p_cov_s2x_s1);
    if (p_cov_s2x_s1 < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.s2x_s1 < 200"); end
    $display("[COV] L2TlbPrefetch.s2x_s2 = %0d", p_cov_s2x_s2);
    if (p_cov_s2x_s2 < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.s2x_s2 < 200"); end
    $display("[COV] L2TlbPrefetch.s2x_none = %0d", p_cov_s2x_none);
    if (p_cov_s2x_none < 200) begin cov_fail++; $display("[COV] L2TlbPrefetch.s2x_none < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
