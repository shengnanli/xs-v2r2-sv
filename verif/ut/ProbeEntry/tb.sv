// 自动生成：verif/ut/ProbeEntry/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// ProbeEntry 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= ProbeEntry =================
  int unsigned p_mode = 0;
  logic [2:0] p_id_q = 3'd0;
  function automatic logic [47:0] pick_line(input int unsigned r);
    return {40'h80_0000_00, 2'b00, 2'(r), 6'(r >> 2)};
  endfunction
  logic p_reset;
  wire  p_g_io_req_ready, p_i_io_req_ready;
  logic p_s0_io_req_ready = '0, p_s1_io_req_ready = '0;
  logic p_io_req_valid;
  logic [47:0] p_io_req_bits_addr;
  logic [49:0] p_io_req_bits_vaddr;
  logic [1:0] p_io_req_bits_param;
  logic p_io_req_bits_needData;
  logic p_io_pipe_req_ready;
  wire  p_g_io_pipe_req_valid, p_i_io_pipe_req_valid;
  logic p_s0_io_pipe_req_valid = '0, p_s1_io_pipe_req_valid = '0;
  wire  [1:0] p_g_io_pipe_req_bits_probe_param, p_i_io_pipe_req_bits_probe_param;
  logic [1:0] p_s0_io_pipe_req_bits_probe_param = '0, p_s1_io_pipe_req_bits_probe_param = '0;
  wire  p_g_io_pipe_req_bits_probe_need_data, p_i_io_pipe_req_bits_probe_need_data;
  logic p_s0_io_pipe_req_bits_probe_need_data = '0, p_s1_io_pipe_req_bits_probe_need_data = '0;
  wire  [49:0] p_g_io_pipe_req_bits_vaddr, p_i_io_pipe_req_bits_vaddr;
  logic [49:0] p_s0_io_pipe_req_bits_vaddr = '0, p_s1_io_pipe_req_bits_vaddr = '0;
  wire  [47:0] p_g_io_pipe_req_bits_addr, p_i_io_pipe_req_bits_addr;
  logic [47:0] p_s0_io_pipe_req_bits_addr = '0, p_s1_io_pipe_req_bits_addr = '0;
  wire  [5:0] p_g_io_pipe_req_bits_id, p_i_io_pipe_req_bits_id;
  logic [5:0] p_s0_io_pipe_req_bits_id = '0, p_s1_io_pipe_req_bits_id = '0;
  logic p_io_pipe_resp_valid;
  logic [2:0] p_io_pipe_resp_bits_id;
  logic p_io_lrsc_locked_block_valid;
  logic [47:0] p_io_lrsc_locked_block_bits;
  logic [2:0] p_io_id;
  wire  p_g_io_block_addr_valid, p_i_io_block_addr_valid;
  logic p_s0_io_block_addr_valid = '0, p_s1_io_block_addr_valid = '0;
  wire  [47:0] p_g_io_block_addr_bits, p_i_io_block_addr_bits;
  logic [47:0] p_s0_io_block_addr_bits = '0, p_s1_io_block_addr_bits = '0;
  int p_cov_req_fire = 0;
  int p_cov_pipe_fire = 0;
  int p_cov_pipe_stall = 0;
  int p_cov_lrsc_blocked = 0;
  int p_cov_resp_release = 0;
  int p_cov_resp_other_id = 0;
  int p_cov_reset_mid = 0;
  logic [0:0] p_armed = '0;
  int p_armed_at = -1;
  ProbeEntry p_u_gold (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_g_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits_addr(p_io_req_bits_addr),
    .io_req_bits_vaddr(p_io_req_bits_vaddr),
    .io_req_bits_param(p_io_req_bits_param),
    .io_req_bits_needData(p_io_req_bits_needData),
    .io_pipe_req_ready(p_io_pipe_req_ready),
    .io_pipe_req_valid(p_g_io_pipe_req_valid),
    .io_pipe_req_bits_probe_param(p_g_io_pipe_req_bits_probe_param),
    .io_pipe_req_bits_probe_need_data(p_g_io_pipe_req_bits_probe_need_data),
    .io_pipe_req_bits_vaddr(p_g_io_pipe_req_bits_vaddr),
    .io_pipe_req_bits_addr(p_g_io_pipe_req_bits_addr),
    .io_pipe_req_bits_id(p_g_io_pipe_req_bits_id),
    .io_pipe_resp_valid(p_io_pipe_resp_valid),
    .io_pipe_resp_bits_id(p_io_pipe_resp_bits_id),
    .io_lrsc_locked_block_valid(p_io_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits(p_io_lrsc_locked_block_bits),
    .io_id(p_io_id),
    .io_block_addr_valid(p_g_io_block_addr_valid),
    .io_block_addr_bits(p_g_io_block_addr_bits)
  );
  ProbeEntry_xs p_u_impl (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_i_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits_addr(p_io_req_bits_addr),
    .io_req_bits_vaddr(p_io_req_bits_vaddr),
    .io_req_bits_param(p_io_req_bits_param),
    .io_req_bits_needData(p_io_req_bits_needData),
    .io_pipe_req_ready(p_io_pipe_req_ready),
    .io_pipe_req_valid(p_i_io_pipe_req_valid),
    .io_pipe_req_bits_probe_param(p_i_io_pipe_req_bits_probe_param),
    .io_pipe_req_bits_probe_need_data(p_i_io_pipe_req_bits_probe_need_data),
    .io_pipe_req_bits_vaddr(p_i_io_pipe_req_bits_vaddr),
    .io_pipe_req_bits_addr(p_i_io_pipe_req_bits_addr),
    .io_pipe_req_bits_id(p_i_io_pipe_req_bits_id),
    .io_pipe_resp_valid(p_io_pipe_resp_valid),
    .io_pipe_resp_bits_id(p_io_pipe_resp_bits_id),
    .io_lrsc_locked_block_valid(p_io_lrsc_locked_block_valid),
    .io_lrsc_locked_block_bits(p_io_lrsc_locked_block_bits),
    .io_id(p_io_id),
    .io_block_addr_valid(p_i_io_block_addr_valid),
    .io_block_addr_bits(p_i_io_block_addr_bits)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) p_mode = $urandom_range(0, 15);
      p_io_req_valid = 1'($urandom);
      p_io_req_bits_addr = 48'({$urandom, $urandom});
      p_io_req_bits_vaddr = 50'({$urandom, $urandom});
      p_io_req_bits_param = 2'($urandom);
      p_io_req_bits_needData = 1'($urandom);
      p_io_pipe_req_ready = 1'($urandom);
      p_io_pipe_resp_valid = 1'($urandom);
      p_io_pipe_resp_bits_id = 3'($urandom);
      p_io_lrsc_locked_block_valid = 1'($urandom);
      p_io_lrsc_locked_block_bits = 48'({$urandom, $urandom});
      p_io_id = 3'($urandom);
      p_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_p
        if (cyc % 2000 == 0) p_id_q = 3'($urandom);
        p_io_id = p_id_q;
        if (p_mode < 12) begin   // 3/4 时间地址挤在 4 条行里；其余时间全随机（覆盖每个地址位）
          p_io_req_bits_addr = pick_line($urandom);
          p_io_lrsc_locked_block_bits = pick_line($urandom);
        end
        p_io_lrsc_locked_block_valid = ($urandom_range(0, 3) != 0);
        if ($urandom_range(0, 1)) p_io_pipe_resp_bits_id = p_id_q;
      end
      #4;
      if (cyc >= RESET_CYC + 0 && p_armed_at >= 0 && cyc >= p_armed_at) begin
        checks++;
        if (p_g_io_req_ready !== p_i_io_req_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_req_ready g=%h i=%h", cyc, p_g_io_req_ready, p_i_io_req_ready);
        end
        p_s1_io_req_ready |= p_g_io_req_ready;
        p_s0_io_req_ready |= ~p_g_io_req_ready;
        checks++;
        if (p_g_io_pipe_req_valid !== p_i_io_pipe_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_valid g=%h i=%h", cyc, p_g_io_pipe_req_valid, p_i_io_pipe_req_valid);
        end
        p_s1_io_pipe_req_valid |= p_g_io_pipe_req_valid;
        p_s0_io_pipe_req_valid |= ~p_g_io_pipe_req_valid;
        checks++;
        if (p_g_io_pipe_req_bits_probe_param !== p_i_io_pipe_req_bits_probe_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_bits_probe_param g=%h i=%h", cyc, p_g_io_pipe_req_bits_probe_param, p_i_io_pipe_req_bits_probe_param);
        end
        p_s1_io_pipe_req_bits_probe_param |= p_g_io_pipe_req_bits_probe_param;
        p_s0_io_pipe_req_bits_probe_param |= ~p_g_io_pipe_req_bits_probe_param;
        checks++;
        if (p_g_io_pipe_req_bits_probe_need_data !== p_i_io_pipe_req_bits_probe_need_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_bits_probe_need_data g=%h i=%h", cyc, p_g_io_pipe_req_bits_probe_need_data, p_i_io_pipe_req_bits_probe_need_data);
        end
        p_s1_io_pipe_req_bits_probe_need_data |= p_g_io_pipe_req_bits_probe_need_data;
        p_s0_io_pipe_req_bits_probe_need_data |= ~p_g_io_pipe_req_bits_probe_need_data;
        checks++;
        if (p_g_io_pipe_req_bits_vaddr !== p_i_io_pipe_req_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_bits_vaddr g=%h i=%h", cyc, p_g_io_pipe_req_bits_vaddr, p_i_io_pipe_req_bits_vaddr);
        end
        p_s1_io_pipe_req_bits_vaddr |= p_g_io_pipe_req_bits_vaddr;
        p_s0_io_pipe_req_bits_vaddr |= ~p_g_io_pipe_req_bits_vaddr;
        checks++;
        if (p_g_io_pipe_req_bits_addr !== p_i_io_pipe_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_bits_addr g=%h i=%h", cyc, p_g_io_pipe_req_bits_addr, p_i_io_pipe_req_bits_addr);
        end
        p_s1_io_pipe_req_bits_addr |= p_g_io_pipe_req_bits_addr;
        p_s0_io_pipe_req_bits_addr |= ~p_g_io_pipe_req_bits_addr;
        checks++;
        if (p_g_io_pipe_req_bits_id !== p_i_io_pipe_req_bits_id) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_pipe_req_bits_id g=%h i=%h", cyc, p_g_io_pipe_req_bits_id, p_i_io_pipe_req_bits_id);
        end
        p_s1_io_pipe_req_bits_id |= p_g_io_pipe_req_bits_id;
        p_s0_io_pipe_req_bits_id |= ~p_g_io_pipe_req_bits_id;
        checks++;
        if (p_g_io_block_addr_valid !== p_i_io_block_addr_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_block_addr_valid g=%h i=%h", cyc, p_g_io_block_addr_valid, p_i_io_block_addr_valid);
        end
        p_s1_io_block_addr_valid |= p_g_io_block_addr_valid;
        p_s0_io_block_addr_valid |= ~p_g_io_block_addr_valid;
        checks++;
        if (p_g_io_block_addr_bits !== p_i_io_block_addr_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ProbeEntry.io_block_addr_bits g=%h i=%h", cyc, p_g_io_block_addr_bits, p_i_io_block_addr_bits);
        end
        p_s1_io_block_addr_bits |= p_g_io_block_addr_bits;
        p_s0_io_block_addr_bits |= ~p_g_io_block_addr_bits;
        if (p_io_req_valid && p_g_io_req_ready) p_cov_req_fire++;
        if (p_g_io_pipe_req_valid && p_io_pipe_req_ready) p_cov_pipe_fire++;
        if (p_g_io_pipe_req_valid && !p_io_pipe_req_ready) p_cov_pipe_stall++;
        if (p_u_gold.state == 2'd1 && !p_g_io_pipe_req_valid) p_cov_lrsc_blocked++;
        if (p_u_gold.state == 2'd2 && p_io_pipe_resp_valid && p_io_pipe_resp_bits_id == p_io_id) p_cov_resp_release++;
        if (p_u_gold.state == 2'd2 && p_io_pipe_resp_valid && p_io_pipe_resp_bits_id != p_io_id) p_cov_resp_other_id++;
        if (p_reset && cyc > 100) p_cov_reset_mid++;
      end
      if (p_io_req_valid && p_g_io_req_ready) p_armed[0] = 1'b1;
      if (p_armed_at < 0 && (&p_armed)) p_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(p_s0_io_req_ready && p_s1_io_req_ready)) begin cov_fail++; $display("[COV] ProbeEntry.io_req_ready 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_valid && p_s1_io_pipe_req_valid)) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_valid 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_probe_param[0] && p_s1_io_pipe_req_bits_probe_param[0])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_probe_param[0] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_probe_param[1] && p_s1_io_pipe_req_bits_probe_param[1])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_probe_param[1] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_probe_need_data && p_s1_io_pipe_req_bits_probe_need_data)) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_probe_need_data 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[0] && p_s1_io_pipe_req_bits_vaddr[0])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[1] && p_s1_io_pipe_req_bits_vaddr[1])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[2] && p_s1_io_pipe_req_bits_vaddr[2])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[3] && p_s1_io_pipe_req_bits_vaddr[3])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[4] && p_s1_io_pipe_req_bits_vaddr[4])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[5] && p_s1_io_pipe_req_bits_vaddr[5])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[6] && p_s1_io_pipe_req_bits_vaddr[6])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[7] && p_s1_io_pipe_req_bits_vaddr[7])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[8] && p_s1_io_pipe_req_bits_vaddr[8])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[9] && p_s1_io_pipe_req_bits_vaddr[9])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[10] && p_s1_io_pipe_req_bits_vaddr[10])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[11] && p_s1_io_pipe_req_bits_vaddr[11])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[12] && p_s1_io_pipe_req_bits_vaddr[12])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[13] && p_s1_io_pipe_req_bits_vaddr[13])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[14] && p_s1_io_pipe_req_bits_vaddr[14])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[15] && p_s1_io_pipe_req_bits_vaddr[15])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[16] && p_s1_io_pipe_req_bits_vaddr[16])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[17] && p_s1_io_pipe_req_bits_vaddr[17])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[18] && p_s1_io_pipe_req_bits_vaddr[18])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[19] && p_s1_io_pipe_req_bits_vaddr[19])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[20] && p_s1_io_pipe_req_bits_vaddr[20])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[21] && p_s1_io_pipe_req_bits_vaddr[21])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[22] && p_s1_io_pipe_req_bits_vaddr[22])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[23] && p_s1_io_pipe_req_bits_vaddr[23])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[24] && p_s1_io_pipe_req_bits_vaddr[24])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[25] && p_s1_io_pipe_req_bits_vaddr[25])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[26] && p_s1_io_pipe_req_bits_vaddr[26])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[27] && p_s1_io_pipe_req_bits_vaddr[27])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[28] && p_s1_io_pipe_req_bits_vaddr[28])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[29] && p_s1_io_pipe_req_bits_vaddr[29])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[30] && p_s1_io_pipe_req_bits_vaddr[30])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[31] && p_s1_io_pipe_req_bits_vaddr[31])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[32] && p_s1_io_pipe_req_bits_vaddr[32])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[33] && p_s1_io_pipe_req_bits_vaddr[33])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[34] && p_s1_io_pipe_req_bits_vaddr[34])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[35] && p_s1_io_pipe_req_bits_vaddr[35])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[36] && p_s1_io_pipe_req_bits_vaddr[36])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[37] && p_s1_io_pipe_req_bits_vaddr[37])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[38] && p_s1_io_pipe_req_bits_vaddr[38])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[39] && p_s1_io_pipe_req_bits_vaddr[39])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[40] && p_s1_io_pipe_req_bits_vaddr[40])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[41] && p_s1_io_pipe_req_bits_vaddr[41])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[42] && p_s1_io_pipe_req_bits_vaddr[42])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[43] && p_s1_io_pipe_req_bits_vaddr[43])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[44] && p_s1_io_pipe_req_bits_vaddr[44])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[44] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[45] && p_s1_io_pipe_req_bits_vaddr[45])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[45] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[46] && p_s1_io_pipe_req_bits_vaddr[46])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[46] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[47] && p_s1_io_pipe_req_bits_vaddr[47])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[47] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[48] && p_s1_io_pipe_req_bits_vaddr[48])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[48] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_vaddr[49] && p_s1_io_pipe_req_bits_vaddr[49])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_vaddr[49] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[0] && p_s1_io_pipe_req_bits_addr[0])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[1] && p_s1_io_pipe_req_bits_addr[1])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[2] && p_s1_io_pipe_req_bits_addr[2])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[3] && p_s1_io_pipe_req_bits_addr[3])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[4] && p_s1_io_pipe_req_bits_addr[4])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[5] && p_s1_io_pipe_req_bits_addr[5])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[6] && p_s1_io_pipe_req_bits_addr[6])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[7] && p_s1_io_pipe_req_bits_addr[7])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[8] && p_s1_io_pipe_req_bits_addr[8])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[9] && p_s1_io_pipe_req_bits_addr[9])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[10] && p_s1_io_pipe_req_bits_addr[10])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[11] && p_s1_io_pipe_req_bits_addr[11])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[12] && p_s1_io_pipe_req_bits_addr[12])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[13] && p_s1_io_pipe_req_bits_addr[13])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[14] && p_s1_io_pipe_req_bits_addr[14])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[15] && p_s1_io_pipe_req_bits_addr[15])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[16] && p_s1_io_pipe_req_bits_addr[16])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[17] && p_s1_io_pipe_req_bits_addr[17])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[18] && p_s1_io_pipe_req_bits_addr[18])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[19] && p_s1_io_pipe_req_bits_addr[19])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[20] && p_s1_io_pipe_req_bits_addr[20])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[21] && p_s1_io_pipe_req_bits_addr[21])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[22] && p_s1_io_pipe_req_bits_addr[22])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[23] && p_s1_io_pipe_req_bits_addr[23])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[24] && p_s1_io_pipe_req_bits_addr[24])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[25] && p_s1_io_pipe_req_bits_addr[25])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[26] && p_s1_io_pipe_req_bits_addr[26])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[27] && p_s1_io_pipe_req_bits_addr[27])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[28] && p_s1_io_pipe_req_bits_addr[28])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[29] && p_s1_io_pipe_req_bits_addr[29])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[30] && p_s1_io_pipe_req_bits_addr[30])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[31] && p_s1_io_pipe_req_bits_addr[31])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[32] && p_s1_io_pipe_req_bits_addr[32])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[33] && p_s1_io_pipe_req_bits_addr[33])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[34] && p_s1_io_pipe_req_bits_addr[34])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[35] && p_s1_io_pipe_req_bits_addr[35])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[36] && p_s1_io_pipe_req_bits_addr[36])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[37] && p_s1_io_pipe_req_bits_addr[37])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[38] && p_s1_io_pipe_req_bits_addr[38])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[39] && p_s1_io_pipe_req_bits_addr[39])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[40] && p_s1_io_pipe_req_bits_addr[40])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[41] && p_s1_io_pipe_req_bits_addr[41])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[42] && p_s1_io_pipe_req_bits_addr[42])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[43] && p_s1_io_pipe_req_bits_addr[43])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[44] && p_s1_io_pipe_req_bits_addr[44])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[45] && p_s1_io_pipe_req_bits_addr[45])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[46] && p_s1_io_pipe_req_bits_addr[46])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_addr[47] && p_s1_io_pipe_req_bits_addr[47])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_id[0] && p_s1_io_pipe_req_bits_id[0])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_id[0] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_id[1] && p_s1_io_pipe_req_bits_id[1])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_id[1] 未见过 0 和 1"); end
    if (!(p_s0_io_pipe_req_bits_id[2] && p_s1_io_pipe_req_bits_id[2])) begin cov_fail++; $display("[COV] ProbeEntry.io_pipe_req_bits_id[2] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_valid && p_s1_io_block_addr_valid)) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_valid 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[0] && p_s1_io_block_addr_bits[0])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[0] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[1] && p_s1_io_block_addr_bits[1])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[1] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[2] && p_s1_io_block_addr_bits[2])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[2] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[3] && p_s1_io_block_addr_bits[3])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[3] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[4] && p_s1_io_block_addr_bits[4])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[4] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[5] && p_s1_io_block_addr_bits[5])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[5] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[6] && p_s1_io_block_addr_bits[6])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[6] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[7] && p_s1_io_block_addr_bits[7])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[7] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[8] && p_s1_io_block_addr_bits[8])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[8] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[9] && p_s1_io_block_addr_bits[9])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[9] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[10] && p_s1_io_block_addr_bits[10])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[10] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[11] && p_s1_io_block_addr_bits[11])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[11] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[12] && p_s1_io_block_addr_bits[12])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[12] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[13] && p_s1_io_block_addr_bits[13])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[13] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[14] && p_s1_io_block_addr_bits[14])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[14] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[15] && p_s1_io_block_addr_bits[15])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[15] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[16] && p_s1_io_block_addr_bits[16])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[16] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[17] && p_s1_io_block_addr_bits[17])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[17] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[18] && p_s1_io_block_addr_bits[18])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[18] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[19] && p_s1_io_block_addr_bits[19])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[19] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[20] && p_s1_io_block_addr_bits[20])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[20] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[21] && p_s1_io_block_addr_bits[21])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[21] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[22] && p_s1_io_block_addr_bits[22])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[22] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[23] && p_s1_io_block_addr_bits[23])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[23] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[24] && p_s1_io_block_addr_bits[24])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[24] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[25] && p_s1_io_block_addr_bits[25])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[25] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[26] && p_s1_io_block_addr_bits[26])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[26] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[27] && p_s1_io_block_addr_bits[27])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[27] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[28] && p_s1_io_block_addr_bits[28])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[28] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[29] && p_s1_io_block_addr_bits[29])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[29] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[30] && p_s1_io_block_addr_bits[30])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[30] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[31] && p_s1_io_block_addr_bits[31])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[31] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[32] && p_s1_io_block_addr_bits[32])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[32] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[33] && p_s1_io_block_addr_bits[33])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[33] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[34] && p_s1_io_block_addr_bits[34])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[34] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[35] && p_s1_io_block_addr_bits[35])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[35] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[36] && p_s1_io_block_addr_bits[36])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[36] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[37] && p_s1_io_block_addr_bits[37])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[37] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[38] && p_s1_io_block_addr_bits[38])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[38] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[39] && p_s1_io_block_addr_bits[39])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[39] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[40] && p_s1_io_block_addr_bits[40])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[40] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[41] && p_s1_io_block_addr_bits[41])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[41] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[42] && p_s1_io_block_addr_bits[42])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[42] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[43] && p_s1_io_block_addr_bits[43])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[43] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[44] && p_s1_io_block_addr_bits[44])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[44] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[45] && p_s1_io_block_addr_bits[45])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[45] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[46] && p_s1_io_block_addr_bits[46])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[46] 未见过 0 和 1"); end
    if (!(p_s0_io_block_addr_bits[47] && p_s1_io_block_addr_bits[47])) begin cov_fail++; $display("[COV] ProbeEntry.io_block_addr_bits[47] 未见过 0 和 1"); end
    $display("[ARM] ProbeEntry armed_at=%0d", p_armed_at);
    if (p_armed_at < 0) begin cov_fail++; $display("[ARM] ProbeEntry 从未 arm"); end
    $display("[COV] ProbeEntry.req_fire = %0d", p_cov_req_fire);
    if (p_cov_req_fire < 50) begin cov_fail++; $display("[COV] ProbeEntry.req_fire < 50"); end
    $display("[COV] ProbeEntry.pipe_fire = %0d", p_cov_pipe_fire);
    if (p_cov_pipe_fire < 50) begin cov_fail++; $display("[COV] ProbeEntry.pipe_fire < 50"); end
    $display("[COV] ProbeEntry.pipe_stall = %0d", p_cov_pipe_stall);
    if (p_cov_pipe_stall < 50) begin cov_fail++; $display("[COV] ProbeEntry.pipe_stall < 50"); end
    $display("[COV] ProbeEntry.lrsc_blocked = %0d", p_cov_lrsc_blocked);
    if (p_cov_lrsc_blocked < 50) begin cov_fail++; $display("[COV] ProbeEntry.lrsc_blocked < 50"); end
    $display("[COV] ProbeEntry.resp_release = %0d", p_cov_resp_release);
    if (p_cov_resp_release < 50) begin cov_fail++; $display("[COV] ProbeEntry.resp_release < 50"); end
    $display("[COV] ProbeEntry.resp_other_id = %0d", p_cov_resp_other_id);
    if (p_cov_resp_other_id < 50) begin cov_fail++; $display("[COV] ProbeEntry.resp_other_id < 50"); end
    $display("[COV] ProbeEntry.reset_mid = %0d", p_cov_reset_mid);
    if (p_cov_reset_mid < 50) begin cov_fail++; $display("[COV] ProbeEntry.reset_mid < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
