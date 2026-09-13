`timescale 1ns/1ps
module tb;
  logic clock;
  logic reset;
  logic io_sfence_valid;
  logic io_csr_satp_changed;
  logic io_csr_vsatp_changed;
  logic io_csr_hgatp_changed;
  logic io_csr_priv_virt_changed;
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
    .io_csr_priv_virt_changed(io_csr_priv_virt_changed),
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
    .io_csr_priv_virt_changed(io_csr_priv_virt_changed),
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
    io_csr_priv_virt_changed = $urandom;
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
    // priv.virt（V 位）变化同样要求整队作废。golden Queue40 的 io_flush 是五项 OR，
    // 这一项曾在重写核里漏掉（见 rtl/memblock/L2TlbMissQueue.sv 的 flush 注释），
    // 必须单独激励：**只**拉这一根、其余四根为 0，才能把它从 OR 里区分出来。
    io_csr_priv_virt_changed = ($urandom_range(0, 511) == 0);
  end
  endtask

  // 定向激励：把队列灌到非空，然后**只**脉冲 io_csr_priv_virt_changed（其余四根
  // flush 源全 0），观察指针/满标志是否归零。漏掉该 OR 项的核在这里必失配。
  task automatic directed_priv_virt_flush(input int unsigned fill_n);
  begin
    // 阶段 1：安静地灌 fill_n 拍入队（不出队、无任何 flush）。
    io_sfence_valid          = 1'b0;
    io_csr_satp_changed      = 1'b0;
    io_csr_vsatp_changed     = 1'b0;
    io_csr_hgatp_changed     = 1'b0;
    io_csr_priv_virt_changed = 1'b0;
    io_out_ready             = 1'b0;
    io_in_valid              = 1'b1;
    repeat (fill_n) begin
      @(negedge clock);
      io_in_bits_req_info_vpn     = 38'($urandom);
      io_in_bits_req_info_s2xlate = 2'($urandom);
      io_in_bits_req_info_source  = 2'($urandom);
      io_in_bits_isLLptw          = 1'($urandom);
      @(posedge clock);
    end
    // 阶段 2：单拍只拉 priv_virt_changed。
    @(negedge clock);
    io_in_valid              = 1'b0;
    io_csr_priv_virt_changed = 1'b1;
    @(posedge clock);
    @(negedge clock);
    io_csr_priv_virt_changed = 1'b0;
    @(posedge clock);
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
    // 先跑定向 flush 用例（灌 3/17/40 条后单脉冲 priv_virt_changed），再进随机拍。
    // 每个定向序列结束后立刻核对内部指针，缺 OR 项的核在这里就会被抓住。
    for (int unsigned f = 0; f < 3; f++) begin
      directed_priv_virt_flush((f == 0) ? 3 : (f == 1) ? 17 : 40);
      #1;
      if (u_g.io_out_q.enq_ptr_value !== u_i.u_core.enq_ptr
          || u_g.io_out_q.deq_ptr_value !== u_i.u_core.deq_ptr
          || u_g.io_out_q.maybe_full !== u_i.u_core.maybe_full) begin
        probe_errors++;
        $display("DIRECTED priv_virt_changed flush MISMATCH: enq g=%0h i=%0h  deq g=%0h i=%0h  full g=%0h i=%0h",
                 u_g.io_out_q.enq_ptr_value, u_i.u_core.enq_ptr,
                 u_g.io_out_q.deq_ptr_value, u_i.u_core.deq_ptr,
                 u_g.io_out_q.maybe_full,    u_i.u_core.maybe_full);
      end
    end
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
