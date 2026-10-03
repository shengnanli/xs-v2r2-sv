// L2TlbMissQueue 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= L2TlbMissQueue =================
  int unsigned m_mode = 0;
  logic [39:0] m_written = '0;
  always @(posedge clk) if (m_u_gold.io_out_q.do_enq) m_written[m_u_gold.io_out_q.enq_ptr_value] <= 1'b1;
  always @(negedge clk) begin
    if (m_u_gold.io_out_q.ram_ext.R0_addr > 6'd39 || m_u_gold.io_out_q.ram_ext.W0_addr > 6'd39 ||
        m_u_impl.u_core.ram_ext.R0_addr > 6'd39 || m_u_impl.u_core.ram_ext.W0_addr > 6'd39) begin
      errors++;
      $display("[ADDR] cyc=%0d ram_40x47 地址越界 g=%0d/%0d i=%0d/%0d", cyc,
               m_u_gold.io_out_q.ram_ext.R0_addr, m_u_gold.io_out_q.ram_ext.W0_addr, m_u_impl.u_core.ram_ext.R0_addr, m_u_impl.u_core.ram_ext.W0_addr);
    end
  end
  logic m_reset;
  logic m_io_sfence_valid;
  logic m_io_csr_satp_changed;
  logic m_io_csr_vsatp_changed;
  logic m_io_csr_hgatp_changed;
  logic m_io_csr_priv_virt_changed;
  wire  m_g_io_in_ready, m_i_io_in_ready;
  logic m_s0_io_in_ready = '0, m_s1_io_in_ready = '0;
  logic m_io_in_valid;
  logic [37:0] m_io_in_bits_req_info_vpn;
  logic [1:0] m_io_in_bits_req_info_s2xlate;
  logic [1:0] m_io_in_bits_req_info_source;
  logic m_io_in_bits_isLLptw;
  logic m_io_out_ready;
  wire  m_g_io_out_valid, m_i_io_out_valid;
  logic m_s0_io_out_valid = '0, m_s1_io_out_valid = '0;
  wire  [37:0] m_g_io_out_bits_req_info_vpn, m_i_io_out_bits_req_info_vpn;
  logic [37:0] m_s0_io_out_bits_req_info_vpn = '0, m_s1_io_out_bits_req_info_vpn = '0;
  wire  [1:0] m_g_io_out_bits_req_info_s2xlate, m_i_io_out_bits_req_info_s2xlate;
  logic [1:0] m_s0_io_out_bits_req_info_s2xlate = '0, m_s1_io_out_bits_req_info_s2xlate = '0;
  wire  [1:0] m_g_io_out_bits_req_info_source, m_i_io_out_bits_req_info_source;
  logic [1:0] m_s0_io_out_bits_req_info_source = '0, m_s1_io_out_bits_req_info_source = '0;
  wire  m_g_io_out_bits_isHptwReq, m_i_io_out_bits_isHptwReq;
  logic m_s0_io_out_bits_isHptwReq = '0, m_s1_io_out_bits_isHptwReq = '0;
  wire  m_g_io_out_bits_isLLptw, m_i_io_out_bits_isLLptw;
  logic m_s0_io_out_bits_isLLptw = '0, m_s1_io_out_bits_isLLptw = '0;
  wire  [2:0] m_g_io_out_bits_hptwId, m_i_io_out_bits_hptwId;
  logic [2:0] m_s0_io_out_bits_hptwId = '0, m_s1_io_out_bits_hptwId = '0;
  int m_cov_full = 0;
  int m_cov_empty = 0;
  int m_cov_enq_deq_same_cycle = 0;
  int m_cov_enq_wrap = 0;
  int m_cov_deq_wrap = 0;
  int m_cov_flush_nonempty = 0;
  int m_cov_flush_with_enq = 0;
  logic [0:0] m_armed = '0;
  int m_armed_at = -1;
  L2TlbMissQueue m_u_gold (
    .clock(clk),
    .reset(m_reset),
    .io_sfence_valid(m_io_sfence_valid),
    .io_csr_satp_changed(m_io_csr_satp_changed),
    .io_csr_vsatp_changed(m_io_csr_vsatp_changed),
    .io_csr_hgatp_changed(m_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(m_io_csr_priv_virt_changed),
    .io_in_ready(m_g_io_in_ready),
    .io_in_valid(m_io_in_valid),
    .io_in_bits_req_info_vpn(m_io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(m_io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(m_io_in_bits_req_info_source),
    .io_in_bits_isLLptw(m_io_in_bits_isLLptw),
    .io_out_ready(m_io_out_ready),
    .io_out_valid(m_g_io_out_valid),
    .io_out_bits_req_info_vpn(m_g_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(m_g_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(m_g_io_out_bits_req_info_source),
    .io_out_bits_isHptwReq(m_g_io_out_bits_isHptwReq),
    .io_out_bits_isLLptw(m_g_io_out_bits_isLLptw),
    .io_out_bits_hptwId(m_g_io_out_bits_hptwId)
  );
  L2TlbMissQueue_xs m_u_impl (
    .clock(clk),
    .reset(m_reset),
    .io_sfence_valid(m_io_sfence_valid),
    .io_csr_satp_changed(m_io_csr_satp_changed),
    .io_csr_vsatp_changed(m_io_csr_vsatp_changed),
    .io_csr_hgatp_changed(m_io_csr_hgatp_changed),
    .io_csr_priv_virt_changed(m_io_csr_priv_virt_changed),
    .io_in_ready(m_i_io_in_ready),
    .io_in_valid(m_io_in_valid),
    .io_in_bits_req_info_vpn(m_io_in_bits_req_info_vpn),
    .io_in_bits_req_info_s2xlate(m_io_in_bits_req_info_s2xlate),
    .io_in_bits_req_info_source(m_io_in_bits_req_info_source),
    .io_in_bits_isLLptw(m_io_in_bits_isLLptw),
    .io_out_ready(m_io_out_ready),
    .io_out_valid(m_i_io_out_valid),
    .io_out_bits_req_info_vpn(m_i_io_out_bits_req_info_vpn),
    .io_out_bits_req_info_s2xlate(m_i_io_out_bits_req_info_s2xlate),
    .io_out_bits_req_info_source(m_i_io_out_bits_req_info_source),
    .io_out_bits_isHptwReq(m_i_io_out_bits_isHptwReq),
    .io_out_bits_isLLptw(m_i_io_out_bits_isLLptw),
    .io_out_bits_hptwId(m_i_io_out_bits_hptwId)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 1000 == 0) m_mode = $urandom_range(0, 15);
      m_io_sfence_valid = 1'($urandom);
      m_io_csr_satp_changed = 1'($urandom);
      m_io_csr_vsatp_changed = 1'($urandom);
      m_io_csr_hgatp_changed = 1'($urandom);
      m_io_csr_priv_virt_changed = 1'($urandom);
      m_io_in_valid = 1'($urandom);
      m_io_in_bits_req_info_vpn = 38'({$urandom, $urandom});
      m_io_in_bits_req_info_s2xlate = 2'($urandom);
      m_io_in_bits_req_info_source = 2'($urandom);
      m_io_in_bits_isLLptw = 1'($urandom);
      m_io_out_ready = 1'($urandom);
      m_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_m
        m_io_sfence_valid          = ($urandom_range(0, 2047) == 0);
        m_io_csr_satp_changed      = ($urandom_range(0, 2047) == 0);
        m_io_csr_vsatp_changed     = ($urandom_range(0, 2047) == 0);
        m_io_csr_hgatp_changed     = ($urandom_range(0, 2047) == 0);
        m_io_csr_priv_virt_changed = ($urandom_range(0, 2047) == 0);
        case (m_mode[1:0])
          2'd0: begin m_io_in_valid = ($urandom_range(0, 3) != 0); m_io_out_ready = ($urandom_range(0, 15) == 0); end
          2'd1: begin m_io_in_valid = ($urandom_range(0, 7) == 0); m_io_out_ready = ($urandom_range(0, 3) != 0); end
          default: ;
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&m_armed)) begin
        checks++;
        if (m_g_io_in_ready !== m_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_in_ready g=%h i=%h", cyc, m_g_io_in_ready, m_i_io_in_ready);
        end
        m_s1_io_in_ready |= m_g_io_in_ready;
        m_s0_io_in_ready |= ~m_g_io_in_ready;
        checks++;
        if (m_g_io_out_valid !== m_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_valid g=%h i=%h", cyc, m_g_io_out_valid, m_i_io_out_valid);
        end
        m_s1_io_out_valid |= m_g_io_out_valid;
        m_s0_io_out_valid |= ~m_g_io_out_valid;
        checks++;
        if (m_g_io_out_bits_req_info_vpn !== m_i_io_out_bits_req_info_vpn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_req_info_vpn g=%h i=%h", cyc, m_g_io_out_bits_req_info_vpn, m_i_io_out_bits_req_info_vpn);
        end
        m_s1_io_out_bits_req_info_vpn |= m_g_io_out_bits_req_info_vpn;
        m_s0_io_out_bits_req_info_vpn |= ~m_g_io_out_bits_req_info_vpn;
        checks++;
        if (m_g_io_out_bits_req_info_s2xlate !== m_i_io_out_bits_req_info_s2xlate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_req_info_s2xlate g=%h i=%h", cyc, m_g_io_out_bits_req_info_s2xlate, m_i_io_out_bits_req_info_s2xlate);
        end
        m_s1_io_out_bits_req_info_s2xlate |= m_g_io_out_bits_req_info_s2xlate;
        m_s0_io_out_bits_req_info_s2xlate |= ~m_g_io_out_bits_req_info_s2xlate;
        checks++;
        if (m_g_io_out_bits_req_info_source !== m_i_io_out_bits_req_info_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_req_info_source g=%h i=%h", cyc, m_g_io_out_bits_req_info_source, m_i_io_out_bits_req_info_source);
        end
        m_s1_io_out_bits_req_info_source |= m_g_io_out_bits_req_info_source;
        m_s0_io_out_bits_req_info_source |= ~m_g_io_out_bits_req_info_source;
        checks++;
        if (m_g_io_out_bits_isHptwReq !== m_i_io_out_bits_isHptwReq) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_isHptwReq g=%h i=%h", cyc, m_g_io_out_bits_isHptwReq, m_i_io_out_bits_isHptwReq);
        end
        m_s1_io_out_bits_isHptwReq |= m_g_io_out_bits_isHptwReq;
        m_s0_io_out_bits_isHptwReq |= ~m_g_io_out_bits_isHptwReq;
        checks++;
        if (m_g_io_out_bits_isLLptw !== m_i_io_out_bits_isLLptw) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_isLLptw g=%h i=%h", cyc, m_g_io_out_bits_isLLptw, m_i_io_out_bits_isLLptw);
        end
        m_s1_io_out_bits_isLLptw |= m_g_io_out_bits_isLLptw;
        m_s0_io_out_bits_isLLptw |= ~m_g_io_out_bits_isLLptw;
        checks++;
        if (m_g_io_out_bits_hptwId !== m_i_io_out_bits_hptwId) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d L2TlbMissQueue.io_out_bits_hptwId g=%h i=%h", cyc, m_g_io_out_bits_hptwId, m_i_io_out_bits_hptwId);
        end
        m_s1_io_out_bits_hptwId |= m_g_io_out_bits_hptwId;
        m_s0_io_out_bits_hptwId |= ~m_g_io_out_bits_hptwId;
        if (!m_g_io_in_ready) m_cov_full++;
        if (!m_g_io_out_valid) m_cov_empty++;
        if (m_io_in_valid && m_g_io_in_ready && m_g_io_out_valid && m_io_out_ready) m_cov_enq_deq_same_cycle++;
        if (m_u_gold.io_out_q.do_enq && m_u_gold.io_out_q.enq_ptr_value == 6'd39) m_cov_enq_wrap++;
        if (m_u_gold.io_out_q.do_deq && m_u_gold.io_out_q.deq_ptr_value == 6'd39) m_cov_deq_wrap++;
        if (m_u_gold.io_out_q.io_flush && m_g_io_out_valid) m_cov_flush_nonempty++;
        if (m_u_gold.io_out_q.io_flush && m_u_gold.io_out_q.do_enq) m_cov_flush_with_enq++;
      end
      if (&m_written) m_armed[0] = 1'b1;
      if (m_armed_at < 0 && (&m_armed)) m_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(m_s0_io_in_ready && m_s1_io_in_ready)) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_in_ready 未见过 0 和 1"); end
    if (!(m_s0_io_out_valid && m_s1_io_out_valid)) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_valid 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[0] && m_s1_io_out_bits_req_info_vpn[0])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[0] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[1] && m_s1_io_out_bits_req_info_vpn[1])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[1] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[2] && m_s1_io_out_bits_req_info_vpn[2])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[2] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[3] && m_s1_io_out_bits_req_info_vpn[3])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[3] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[4] && m_s1_io_out_bits_req_info_vpn[4])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[4] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[5] && m_s1_io_out_bits_req_info_vpn[5])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[5] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[6] && m_s1_io_out_bits_req_info_vpn[6])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[6] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[7] && m_s1_io_out_bits_req_info_vpn[7])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[7] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[8] && m_s1_io_out_bits_req_info_vpn[8])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[8] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[9] && m_s1_io_out_bits_req_info_vpn[9])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[9] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[10] && m_s1_io_out_bits_req_info_vpn[10])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[10] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[11] && m_s1_io_out_bits_req_info_vpn[11])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[11] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[12] && m_s1_io_out_bits_req_info_vpn[12])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[12] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[13] && m_s1_io_out_bits_req_info_vpn[13])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[13] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[14] && m_s1_io_out_bits_req_info_vpn[14])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[14] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[15] && m_s1_io_out_bits_req_info_vpn[15])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[15] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[16] && m_s1_io_out_bits_req_info_vpn[16])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[16] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[17] && m_s1_io_out_bits_req_info_vpn[17])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[17] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[18] && m_s1_io_out_bits_req_info_vpn[18])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[18] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[19] && m_s1_io_out_bits_req_info_vpn[19])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[19] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[20] && m_s1_io_out_bits_req_info_vpn[20])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[20] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[21] && m_s1_io_out_bits_req_info_vpn[21])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[21] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[22] && m_s1_io_out_bits_req_info_vpn[22])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[22] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[23] && m_s1_io_out_bits_req_info_vpn[23])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[23] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[24] && m_s1_io_out_bits_req_info_vpn[24])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[24] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[25] && m_s1_io_out_bits_req_info_vpn[25])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[25] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[26] && m_s1_io_out_bits_req_info_vpn[26])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[26] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[27] && m_s1_io_out_bits_req_info_vpn[27])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[27] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[28] && m_s1_io_out_bits_req_info_vpn[28])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[28] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[29] && m_s1_io_out_bits_req_info_vpn[29])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[29] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[30] && m_s1_io_out_bits_req_info_vpn[30])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[30] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[31] && m_s1_io_out_bits_req_info_vpn[31])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[31] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[32] && m_s1_io_out_bits_req_info_vpn[32])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[32] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[33] && m_s1_io_out_bits_req_info_vpn[33])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[33] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[34] && m_s1_io_out_bits_req_info_vpn[34])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[34] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[35] && m_s1_io_out_bits_req_info_vpn[35])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[35] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[36] && m_s1_io_out_bits_req_info_vpn[36])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[36] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_vpn[37] && m_s1_io_out_bits_req_info_vpn[37])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_vpn[37] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_s2xlate[0] && m_s1_io_out_bits_req_info_s2xlate[0])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_s2xlate[0] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_s2xlate[1] && m_s1_io_out_bits_req_info_s2xlate[1])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_s2xlate[1] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_source[0] && m_s1_io_out_bits_req_info_source[0])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_source[0] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_req_info_source[1] && m_s1_io_out_bits_req_info_source[1])) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_req_info_source[1] 未见过 0 和 1"); end
    if (!(m_s0_io_out_bits_isLLptw && m_s1_io_out_bits_isLLptw)) begin cov_fail++; $display("[COV] L2TlbMissQueue.io_out_bits_isLLptw 未见过 0 和 1"); end
    $display("[ARM] L2TlbMissQueue armed_at=%0d", m_armed_at);
    if (m_armed_at < 0) begin cov_fail++; $display("[ARM] L2TlbMissQueue 从未 arm"); end
    $display("[COV] L2TlbMissQueue.full = %0d", m_cov_full);
    if (m_cov_full < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.full < 50"); end
    $display("[COV] L2TlbMissQueue.empty = %0d", m_cov_empty);
    if (m_cov_empty < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.empty < 50"); end
    $display("[COV] L2TlbMissQueue.enq_deq_same_cycle = %0d", m_cov_enq_deq_same_cycle);
    if (m_cov_enq_deq_same_cycle < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.enq_deq_same_cycle < 50"); end
    $display("[COV] L2TlbMissQueue.enq_wrap = %0d", m_cov_enq_wrap);
    if (m_cov_enq_wrap < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.enq_wrap < 50"); end
    $display("[COV] L2TlbMissQueue.deq_wrap = %0d", m_cov_deq_wrap);
    if (m_cov_deq_wrap < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.deq_wrap < 50"); end
    $display("[COV] L2TlbMissQueue.flush_nonempty = %0d", m_cov_flush_nonempty);
    if (m_cov_flush_nonempty < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.flush_nonempty < 50"); end
    $display("[COV] L2TlbMissQueue.flush_with_enq = %0d", m_cov_flush_with_enq);
    if (m_cov_flush_with_enq < 50) begin cov_fail++; $display("[COV] L2TlbMissQueue.flush_with_enq < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
