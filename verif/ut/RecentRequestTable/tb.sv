// 自动生成：verif/ut/RecentRequestTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// RecentRequestTable / RecentRequestTable_1 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= RecentRequestTable =================
  int unsigned r0_mode = 0;
  logic [47:0] r0_pool [16];
  initial for (int i = 0; i < 16; i++) r0_pool[i] = 48'({$urandom, $urandom});
  function automatic logic [47:0] r0_line(input int unsigned k);
    return r0_pool[k] ^ 48'($urandom_range(0, 63));   // 同一行内随机字节偏移
  endfunction
  logic r0_reset;
  wire  r0_g_io_w_ready, r0_i_io_w_ready;
  logic r0_s0_io_w_ready = '0, r0_s1_io_w_ready = '0;
  logic r0_io_w_valid;
  logic [47:0] r0_io_w_bits;
  logic r0_io_r_req_valid;
  logic [47:0] r0_io_r_req_bits_addr;
  logic [6:0] r0_io_r_req_bits_testOffset;
  logic [5:0] r0_io_r_req_bits_ptr;
  wire  r0_g_io_r_resp_valid, r0_i_io_r_resp_valid;
  logic r0_s0_io_r_resp_valid = '0, r0_s1_io_r_resp_valid = '0;
  wire  [5:0] r0_g_io_r_resp_bits_ptr, r0_i_io_r_resp_bits_ptr;
  logic [5:0] r0_s0_io_r_resp_bits_ptr = '0, r0_s1_io_r_resp_bits_ptr = '0;
  wire  r0_g_io_r_resp_bits_hit, r0_i_io_r_resp_bits_hit;
  logic r0_s0_io_r_resp_bits_hit = '0, r0_s1_io_r_resp_bits_hit = '0;
  logic [8:0] r0_boreChildrenBd_bore_addr;
  logic [8:0] r0_boreChildrenBd_bore_addr_rd;
  logic [12:0] r0_boreChildrenBd_bore_wdata;
  logic r0_boreChildrenBd_bore_wmask;
  logic r0_boreChildrenBd_bore_re;
  logic r0_boreChildrenBd_bore_we;
  wire  [12:0] r0_g_boreChildrenBd_bore_rdata, r0_i_boreChildrenBd_bore_rdata;
  logic [12:0] r0_s0_boreChildrenBd_bore_rdata = '0, r0_s1_boreChildrenBd_bore_rdata = '0;
  logic r0_boreChildrenBd_bore_ack;
  logic r0_boreChildrenBd_bore_selectedOH;
  logic r0_boreChildrenBd_bore_array;
  logic r0_sigFromSrams_bore_ram_hold;
  logic r0_sigFromSrams_bore_ram_bypass;
  logic r0_sigFromSrams_bore_ram_bp_clken;
  logic r0_sigFromSrams_bore_ram_aux_clk;
  logic r0_sigFromSrams_bore_ram_aux_ckbp;
  logic r0_sigFromSrams_bore_ram_mcp_hold;
  logic r0_sigFromSrams_bore_cgen;
  int r0_cov_w_fire = 0;
  int r0_cov_w_blocked_by_r = 0;
  int r0_cov_resp = 0;
  int r0_cov_hit = 0;
  int r0_cov_miss = 0;
  int r0_cov_offset_nz = 0;
  int r0_cov_reset_mid = 0;
  logic [0:0] r0_armed = '0;
  int r0_armed_at = -1;
  RecentRequestTable r0_u_gold (
    .clock(clk),
    .reset(r0_reset),
    .io_w_ready(r0_g_io_w_ready),
    .io_w_valid(r0_io_w_valid),
    .io_w_bits(r0_io_w_bits),
    .io_r_req_valid(r0_io_r_req_valid),
    .io_r_req_bits_addr(r0_io_r_req_bits_addr),
    .io_r_req_bits_testOffset(r0_io_r_req_bits_testOffset),
    .io_r_req_bits_ptr(r0_io_r_req_bits_ptr),
    .io_r_resp_valid(r0_g_io_r_resp_valid),
    .io_r_resp_bits_ptr(r0_g_io_r_resp_bits_ptr),
    .io_r_resp_bits_hit(r0_g_io_r_resp_bits_hit),
    .boreChildrenBd_bore_addr(r0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(r0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(r0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(r0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(r0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(r0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(r0_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(r0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(r0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(r0_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(r0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(r0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(r0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(r0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(r0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(r0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(r0_sigFromSrams_bore_cgen)
  );
  RecentRequestTable_xs r0_u_impl (
    .clock(clk),
    .reset(r0_reset),
    .io_w_ready(r0_i_io_w_ready),
    .io_w_valid(r0_io_w_valid),
    .io_w_bits(r0_io_w_bits),
    .io_r_req_valid(r0_io_r_req_valid),
    .io_r_req_bits_addr(r0_io_r_req_bits_addr),
    .io_r_req_bits_testOffset(r0_io_r_req_bits_testOffset),
    .io_r_req_bits_ptr(r0_io_r_req_bits_ptr),
    .io_r_resp_valid(r0_i_io_r_resp_valid),
    .io_r_resp_bits_ptr(r0_i_io_r_resp_bits_ptr),
    .io_r_resp_bits_hit(r0_i_io_r_resp_bits_hit),
    .boreChildrenBd_bore_addr(r0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(r0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(r0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(r0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(r0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(r0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(r0_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(r0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(r0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(r0_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(r0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(r0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(r0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(r0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(r0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(r0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(r0_sigFromSrams_bore_cgen)
  );

  // ================= RecentRequestTable_1 =================
  int unsigned r1_mode = 0;
  logic [49:0] r1_pool [16];
  initial for (int i = 0; i < 16; i++) r1_pool[i] = 50'({$urandom, $urandom});
  function automatic logic [49:0] r1_line(input int unsigned k);
    return r1_pool[k] ^ 50'($urandom_range(0, 63));   // 同一行内随机字节偏移
  endfunction
  logic r1_reset;
  wire  r1_g_io_w_ready, r1_i_io_w_ready;
  logic r1_s0_io_w_ready = '0, r1_s1_io_w_ready = '0;
  logic r1_io_w_valid;
  logic [49:0] r1_io_w_bits;
  logic r1_io_r_req_valid;
  logic [49:0] r1_io_r_req_bits_addr;
  logic [9:0] r1_io_r_req_bits_testOffset;
  logic [6:0] r1_io_r_req_bits_ptr;
  wire  r1_g_io_r_resp_valid, r1_i_io_r_resp_valid;
  logic r1_s0_io_r_resp_valid = '0, r1_s1_io_r_resp_valid = '0;
  wire  [6:0] r1_g_io_r_resp_bits_ptr, r1_i_io_r_resp_bits_ptr;
  logic [6:0] r1_s0_io_r_resp_bits_ptr = '0, r1_s1_io_r_resp_bits_ptr = '0;
  wire  r1_g_io_r_resp_bits_hit, r1_i_io_r_resp_bits_hit;
  logic r1_s0_io_r_resp_bits_hit = '0, r1_s1_io_r_resp_bits_hit = '0;
  logic [8:0] r1_boreChildrenBd_bore_addr;
  logic [8:0] r1_boreChildrenBd_bore_addr_rd;
  logic [12:0] r1_boreChildrenBd_bore_wdata;
  logic r1_boreChildrenBd_bore_wmask;
  logic r1_boreChildrenBd_bore_re;
  logic r1_boreChildrenBd_bore_we;
  wire  [12:0] r1_g_boreChildrenBd_bore_rdata, r1_i_boreChildrenBd_bore_rdata;
  logic [12:0] r1_s0_boreChildrenBd_bore_rdata = '0, r1_s1_boreChildrenBd_bore_rdata = '0;
  logic r1_boreChildrenBd_bore_ack;
  logic r1_boreChildrenBd_bore_selectedOH;
  logic r1_boreChildrenBd_bore_array;
  logic r1_sigFromSrams_bore_ram_hold;
  logic r1_sigFromSrams_bore_ram_bypass;
  logic r1_sigFromSrams_bore_ram_bp_clken;
  logic r1_sigFromSrams_bore_ram_aux_clk;
  logic r1_sigFromSrams_bore_ram_aux_ckbp;
  logic r1_sigFromSrams_bore_ram_mcp_hold;
  logic r1_sigFromSrams_bore_cgen;
  int r1_cov_w_fire = 0;
  int r1_cov_w_blocked_by_r = 0;
  int r1_cov_resp = 0;
  int r1_cov_hit = 0;
  int r1_cov_miss = 0;
  int r1_cov_offset_nz = 0;
  int r1_cov_reset_mid = 0;
  logic [0:0] r1_armed = '0;
  int r1_armed_at = -1;
  RecentRequestTable_1 r1_u_gold (
    .clock(clk),
    .reset(r1_reset),
    .io_w_ready(r1_g_io_w_ready),
    .io_w_valid(r1_io_w_valid),
    .io_w_bits(r1_io_w_bits),
    .io_r_req_valid(r1_io_r_req_valid),
    .io_r_req_bits_addr(r1_io_r_req_bits_addr),
    .io_r_req_bits_testOffset(r1_io_r_req_bits_testOffset),
    .io_r_req_bits_ptr(r1_io_r_req_bits_ptr),
    .io_r_resp_valid(r1_g_io_r_resp_valid),
    .io_r_resp_bits_ptr(r1_g_io_r_resp_bits_ptr),
    .io_r_resp_bits_hit(r1_g_io_r_resp_bits_hit),
    .boreChildrenBd_bore_addr(r1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(r1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(r1_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(r1_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(r1_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(r1_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(r1_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(r1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(r1_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(r1_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(r1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(r1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(r1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(r1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(r1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(r1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(r1_sigFromSrams_bore_cgen)
  );
  RecentRequestTable_1_xs r1_u_impl (
    .clock(clk),
    .reset(r1_reset),
    .io_w_ready(r1_i_io_w_ready),
    .io_w_valid(r1_io_w_valid),
    .io_w_bits(r1_io_w_bits),
    .io_r_req_valid(r1_io_r_req_valid),
    .io_r_req_bits_addr(r1_io_r_req_bits_addr),
    .io_r_req_bits_testOffset(r1_io_r_req_bits_testOffset),
    .io_r_req_bits_ptr(r1_io_r_req_bits_ptr),
    .io_r_resp_valid(r1_i_io_r_resp_valid),
    .io_r_resp_bits_ptr(r1_i_io_r_resp_bits_ptr),
    .io_r_resp_bits_hit(r1_i_io_r_resp_bits_hit),
    .boreChildrenBd_bore_addr(r1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(r1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(r1_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(r1_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(r1_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(r1_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(r1_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(r1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(r1_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(r1_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(r1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(r1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(r1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(r1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(r1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(r1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(r1_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) r0_mode = $urandom_range(0, 15);
      r0_io_w_valid = 1'($urandom);
      r0_io_w_bits = 48'({$urandom, $urandom});
      r0_io_r_req_valid = 1'($urandom);
      r0_io_r_req_bits_addr = 48'({$urandom, $urandom});
      r0_io_r_req_bits_testOffset = 7'($urandom);
      r0_io_r_req_bits_ptr = 6'($urandom);
      r0_boreChildrenBd_bore_addr = 9'($urandom);
      r0_boreChildrenBd_bore_addr_rd = 9'($urandom);
      r0_boreChildrenBd_bore_wdata = 13'($urandom);
      r0_boreChildrenBd_bore_wmask = 1'($urandom);
      r0_boreChildrenBd_bore_re = 1'($urandom);
      r0_boreChildrenBd_bore_we = 1'($urandom);
      r0_boreChildrenBd_bore_ack = 1'($urandom);
      r0_boreChildrenBd_bore_selectedOH = 1'($urandom);
      r0_boreChildrenBd_bore_array = 1'($urandom);
      r0_sigFromSrams_bore_ram_hold = 1'($urandom);
      r0_sigFromSrams_bore_ram_bypass = 1'($urandom);
      r0_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      r0_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      r0_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      r0_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      r0_sigFromSrams_bore_cgen = 1'($urandom);
      r0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_r0
        r0_io_w_valid = ($urandom_range(0, 3) != 0);
        r0_io_w_bits = r0_line($urandom_range(0, 15));
        r0_io_r_req_bits_addr = r0_line($urandom_range(0, 15));
        if ($urandom_range(0, 3) != 0) r0_io_r_req_bits_testOffset = '0;
        else r0_io_r_req_bits_testOffset = 7'($signed(4'($urandom)));
        if (r0_mode != 0) begin
          r0_boreChildrenBd_bore_re = '0;
          r0_boreChildrenBd_bore_we = '0;
          r0_boreChildrenBd_bore_ack = '0;
          r0_boreChildrenBd_bore_selectedOH = '0;
          r0_boreChildrenBd_bore_array = '0;
          r0_boreChildrenBd_bore_wmask = '0;
          r0_sigFromSrams_bore_ram_hold = '0;
          r0_sigFromSrams_bore_ram_bypass = '0;
          r0_sigFromSrams_bore_ram_bp_clken = '0;
          r0_sigFromSrams_bore_ram_aux_clk = '0;
          r0_sigFromSrams_bore_ram_aux_ckbp = '0;
          r0_sigFromSrams_bore_ram_mcp_hold = '0;
          r0_sigFromSrams_bore_cgen = '0;
        end
      end
      if (cyc % 2000 == 0) r1_mode = $urandom_range(0, 15);
      r1_io_w_valid = 1'($urandom);
      r1_io_w_bits = 50'({$urandom, $urandom});
      r1_io_r_req_valid = 1'($urandom);
      r1_io_r_req_bits_addr = 50'({$urandom, $urandom});
      r1_io_r_req_bits_testOffset = 10'($urandom);
      r1_io_r_req_bits_ptr = 7'($urandom);
      r1_boreChildrenBd_bore_addr = 9'($urandom);
      r1_boreChildrenBd_bore_addr_rd = 9'($urandom);
      r1_boreChildrenBd_bore_wdata = 13'($urandom);
      r1_boreChildrenBd_bore_wmask = 1'($urandom);
      r1_boreChildrenBd_bore_re = 1'($urandom);
      r1_boreChildrenBd_bore_we = 1'($urandom);
      r1_boreChildrenBd_bore_ack = 1'($urandom);
      r1_boreChildrenBd_bore_selectedOH = 1'($urandom);
      r1_boreChildrenBd_bore_array = 1'($urandom);
      r1_sigFromSrams_bore_ram_hold = 1'($urandom);
      r1_sigFromSrams_bore_ram_bypass = 1'($urandom);
      r1_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      r1_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      r1_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      r1_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      r1_sigFromSrams_bore_cgen = 1'($urandom);
      r1_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_r1
        r1_io_w_valid = ($urandom_range(0, 3) != 0);
        r1_io_w_bits = r1_line($urandom_range(0, 15));
        r1_io_r_req_bits_addr = r1_line($urandom_range(0, 15));
        if ($urandom_range(0, 3) != 0) r1_io_r_req_bits_testOffset = '0;
        else r1_io_r_req_bits_testOffset = 10'($signed(4'($urandom)));
        if (r1_mode != 0) begin
          r1_boreChildrenBd_bore_re = '0;
          r1_boreChildrenBd_bore_we = '0;
          r1_boreChildrenBd_bore_ack = '0;
          r1_boreChildrenBd_bore_selectedOH = '0;
          r1_boreChildrenBd_bore_array = '0;
          r1_boreChildrenBd_bore_wmask = '0;
          r1_sigFromSrams_bore_ram_hold = '0;
          r1_sigFromSrams_bore_ram_bypass = '0;
          r1_sigFromSrams_bore_ram_bp_clken = '0;
          r1_sigFromSrams_bore_ram_aux_clk = '0;
          r1_sigFromSrams_bore_ram_aux_ckbp = '0;
          r1_sigFromSrams_bore_ram_mcp_hold = '0;
          r1_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&r0_armed)) begin
        checks++;
        if (r0_g_io_w_ready !== r0_i_io_w_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable.io_w_ready g=%h i=%h", cyc, r0_g_io_w_ready, r0_i_io_w_ready);
        end
        r0_s1_io_w_ready |= r0_g_io_w_ready;
        r0_s0_io_w_ready |= ~r0_g_io_w_ready;
        checks++;
        if (r0_g_io_r_resp_valid !== r0_i_io_r_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable.io_r_resp_valid g=%h i=%h", cyc, r0_g_io_r_resp_valid, r0_i_io_r_resp_valid);
        end
        r0_s1_io_r_resp_valid |= r0_g_io_r_resp_valid;
        r0_s0_io_r_resp_valid |= ~r0_g_io_r_resp_valid;
        checks++;
        if (r0_g_io_r_resp_bits_ptr !== r0_i_io_r_resp_bits_ptr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable.io_r_resp_bits_ptr g=%h i=%h", cyc, r0_g_io_r_resp_bits_ptr, r0_i_io_r_resp_bits_ptr);
        end
        r0_s1_io_r_resp_bits_ptr |= r0_g_io_r_resp_bits_ptr;
        r0_s0_io_r_resp_bits_ptr |= ~r0_g_io_r_resp_bits_ptr;
        checks++;
        if (r0_g_io_r_resp_bits_hit !== r0_i_io_r_resp_bits_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable.io_r_resp_bits_hit g=%h i=%h", cyc, r0_g_io_r_resp_bits_hit, r0_i_io_r_resp_bits_hit);
        end
        r0_s1_io_r_resp_bits_hit |= r0_g_io_r_resp_bits_hit;
        r0_s0_io_r_resp_bits_hit |= ~r0_g_io_r_resp_bits_hit;
        checks++;
        if (r0_g_boreChildrenBd_bore_rdata !== r0_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable.boreChildrenBd_bore_rdata g=%h i=%h", cyc, r0_g_boreChildrenBd_bore_rdata, r0_i_boreChildrenBd_bore_rdata);
        end
        r0_s1_boreChildrenBd_bore_rdata |= r0_g_boreChildrenBd_bore_rdata;
        r0_s0_boreChildrenBd_bore_rdata |= ~r0_g_boreChildrenBd_bore_rdata;
        if (r0_io_w_valid && r0_g_io_w_ready) r0_cov_w_fire++;
        if (r0_io_w_valid && r0_io_r_req_valid) r0_cov_w_blocked_by_r++;
        if (r0_g_io_r_resp_valid) r0_cov_resp++;
        if (r0_g_io_r_resp_valid && r0_g_io_r_resp_bits_hit) r0_cov_hit++;
        if (r0_g_io_r_resp_valid && !r0_g_io_r_resp_bits_hit) r0_cov_miss++;
        if (r0_io_r_req_valid && r0_io_r_req_bits_testOffset != 0) r0_cov_offset_nz++;
        if (r0_reset && cyc > 100) r0_cov_reset_mid++;
      end
      if (r0_g_io_r_resp_valid) r0_armed[0] = 1'b1;
      if (r0_armed_at < 0 && (&r0_armed)) r0_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && (&r1_armed)) begin
        checks++;
        if (r1_g_io_w_ready !== r1_i_io_w_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable_1.io_w_ready g=%h i=%h", cyc, r1_g_io_w_ready, r1_i_io_w_ready);
        end
        r1_s1_io_w_ready |= r1_g_io_w_ready;
        r1_s0_io_w_ready |= ~r1_g_io_w_ready;
        checks++;
        if (r1_g_io_r_resp_valid !== r1_i_io_r_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable_1.io_r_resp_valid g=%h i=%h", cyc, r1_g_io_r_resp_valid, r1_i_io_r_resp_valid);
        end
        r1_s1_io_r_resp_valid |= r1_g_io_r_resp_valid;
        r1_s0_io_r_resp_valid |= ~r1_g_io_r_resp_valid;
        checks++;
        if (r1_g_io_r_resp_bits_ptr !== r1_i_io_r_resp_bits_ptr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable_1.io_r_resp_bits_ptr g=%h i=%h", cyc, r1_g_io_r_resp_bits_ptr, r1_i_io_r_resp_bits_ptr);
        end
        r1_s1_io_r_resp_bits_ptr |= r1_g_io_r_resp_bits_ptr;
        r1_s0_io_r_resp_bits_ptr |= ~r1_g_io_r_resp_bits_ptr;
        checks++;
        if (r1_g_io_r_resp_bits_hit !== r1_i_io_r_resp_bits_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable_1.io_r_resp_bits_hit g=%h i=%h", cyc, r1_g_io_r_resp_bits_hit, r1_i_io_r_resp_bits_hit);
        end
        r1_s1_io_r_resp_bits_hit |= r1_g_io_r_resp_bits_hit;
        r1_s0_io_r_resp_bits_hit |= ~r1_g_io_r_resp_bits_hit;
        checks++;
        if (r1_g_boreChildrenBd_bore_rdata !== r1_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RecentRequestTable_1.boreChildrenBd_bore_rdata g=%h i=%h", cyc, r1_g_boreChildrenBd_bore_rdata, r1_i_boreChildrenBd_bore_rdata);
        end
        r1_s1_boreChildrenBd_bore_rdata |= r1_g_boreChildrenBd_bore_rdata;
        r1_s0_boreChildrenBd_bore_rdata |= ~r1_g_boreChildrenBd_bore_rdata;
        if (r1_io_w_valid && r1_g_io_w_ready) r1_cov_w_fire++;
        if (r1_io_w_valid && r1_io_r_req_valid) r1_cov_w_blocked_by_r++;
        if (r1_g_io_r_resp_valid) r1_cov_resp++;
        if (r1_g_io_r_resp_valid && r1_g_io_r_resp_bits_hit) r1_cov_hit++;
        if (r1_g_io_r_resp_valid && !r1_g_io_r_resp_bits_hit) r1_cov_miss++;
        if (r1_io_r_req_valid && r1_io_r_req_bits_testOffset != 0) r1_cov_offset_nz++;
        if (r1_reset && cyc > 100) r1_cov_reset_mid++;
      end
      if (r1_g_io_r_resp_valid) r1_armed[0] = 1'b1;
      if (r1_armed_at < 0 && (&r1_armed)) r1_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(r0_s0_io_w_ready && r0_s1_io_w_ready)) begin cov_fail++; $display("[COV] RecentRequestTable.io_w_ready 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_valid && r0_s1_io_r_resp_valid)) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_valid 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[0] && r0_s1_io_r_resp_bits_ptr[0])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[0] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[1] && r0_s1_io_r_resp_bits_ptr[1])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[1] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[2] && r0_s1_io_r_resp_bits_ptr[2])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[2] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[3] && r0_s1_io_r_resp_bits_ptr[3])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[3] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[4] && r0_s1_io_r_resp_bits_ptr[4])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[4] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_ptr[5] && r0_s1_io_r_resp_bits_ptr[5])) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_ptr[5] 未见过 0 和 1"); end
    if (!(r0_s0_io_r_resp_bits_hit && r0_s1_io_r_resp_bits_hit)) begin cov_fail++; $display("[COV] RecentRequestTable.io_r_resp_bits_hit 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[0] && r0_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[1] && r0_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[2] && r0_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[3] && r0_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[4] && r0_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[5] && r0_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[6] && r0_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[7] && r0_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[8] && r0_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[9] && r0_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[10] && r0_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[11] && r0_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(r0_s0_boreChildrenBd_bore_rdata[12] && r0_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] RecentRequestTable.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    $display("[ARM] RecentRequestTable armed_at=%0d", r0_armed_at);
    if (r0_armed_at < 0) begin cov_fail++; $display("[ARM] RecentRequestTable 从未 arm"); end
    $display("[COV] RecentRequestTable.w_fire = %0d", r0_cov_w_fire);
    if (r0_cov_w_fire < 5) begin cov_fail++; $display("[COV] RecentRequestTable.w_fire < 5"); end
    $display("[COV] RecentRequestTable.w_blocked_by_r = %0d", r0_cov_w_blocked_by_r);
    if (r0_cov_w_blocked_by_r < 5) begin cov_fail++; $display("[COV] RecentRequestTable.w_blocked_by_r < 5"); end
    $display("[COV] RecentRequestTable.resp = %0d", r0_cov_resp);
    if (r0_cov_resp < 5) begin cov_fail++; $display("[COV] RecentRequestTable.resp < 5"); end
    $display("[COV] RecentRequestTable.hit = %0d", r0_cov_hit);
    if (r0_cov_hit < 5) begin cov_fail++; $display("[COV] RecentRequestTable.hit < 5"); end
    $display("[COV] RecentRequestTable.miss = %0d", r0_cov_miss);
    if (r0_cov_miss < 5) begin cov_fail++; $display("[COV] RecentRequestTable.miss < 5"); end
    $display("[COV] RecentRequestTable.offset_nz = %0d", r0_cov_offset_nz);
    if (r0_cov_offset_nz < 5) begin cov_fail++; $display("[COV] RecentRequestTable.offset_nz < 5"); end
    $display("[COV] RecentRequestTable.reset_mid = %0d", r0_cov_reset_mid);
    if (r0_cov_reset_mid < 5) begin cov_fail++; $display("[COV] RecentRequestTable.reset_mid < 5"); end
    if (!(r1_s0_io_w_ready && r1_s1_io_w_ready)) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_w_ready 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_valid && r1_s1_io_r_resp_valid)) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_valid 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[0] && r1_s1_io_r_resp_bits_ptr[0])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[0] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[1] && r1_s1_io_r_resp_bits_ptr[1])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[1] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[2] && r1_s1_io_r_resp_bits_ptr[2])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[2] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[3] && r1_s1_io_r_resp_bits_ptr[3])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[3] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[4] && r1_s1_io_r_resp_bits_ptr[4])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[4] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[5] && r1_s1_io_r_resp_bits_ptr[5])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[5] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_ptr[6] && r1_s1_io_r_resp_bits_ptr[6])) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_ptr[6] 未见过 0 和 1"); end
    if (!(r1_s0_io_r_resp_bits_hit && r1_s1_io_r_resp_bits_hit)) begin cov_fail++; $display("[COV] RecentRequestTable_1.io_r_resp_bits_hit 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[0] && r1_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[1] && r1_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[2] && r1_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[3] && r1_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[4] && r1_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[5] && r1_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[6] && r1_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[7] && r1_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[8] && r1_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[9] && r1_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[10] && r1_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[11] && r1_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(r1_s0_boreChildrenBd_bore_rdata[12] && r1_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] RecentRequestTable_1.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    $display("[ARM] RecentRequestTable_1 armed_at=%0d", r1_armed_at);
    if (r1_armed_at < 0) begin cov_fail++; $display("[ARM] RecentRequestTable_1 从未 arm"); end
    $display("[COV] RecentRequestTable_1.w_fire = %0d", r1_cov_w_fire);
    if (r1_cov_w_fire < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.w_fire < 5"); end
    $display("[COV] RecentRequestTable_1.w_blocked_by_r = %0d", r1_cov_w_blocked_by_r);
    if (r1_cov_w_blocked_by_r < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.w_blocked_by_r < 5"); end
    $display("[COV] RecentRequestTable_1.resp = %0d", r1_cov_resp);
    if (r1_cov_resp < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.resp < 5"); end
    $display("[COV] RecentRequestTable_1.hit = %0d", r1_cov_hit);
    if (r1_cov_hit < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.hit < 5"); end
    $display("[COV] RecentRequestTable_1.miss = %0d", r1_cov_miss);
    if (r1_cov_miss < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.miss < 5"); end
    $display("[COV] RecentRequestTable_1.offset_nz = %0d", r1_cov_offset_nz);
    if (r1_cov_offset_nz < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.offset_nz < 5"); end
    $display("[COV] RecentRequestTable_1.reset_mid = %0d", r1_cov_reset_mid);
    if (r1_cov_reset_mid < 5) begin cov_fail++; $display("[COV] RecentRequestTable_1.reset_mid < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
