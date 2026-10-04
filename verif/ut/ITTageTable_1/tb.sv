// 生成 ITTageTable / _1.._4 与 TageBTable 六个 UT 目录的双例化 testbench（各自的 tb.sv）。
//
// 替换原先 scripts/gen_zj_ut.py 的"全随机端口"tb（2026-10-03 agent/bpu-tables）：那份 tb 从复位后第一拍就比，
// 而这几张表的读出数据来自 SRAM 读出保持寄存器与表项 SRAM（都不复位），只在 +vcs+initreg+0 下两侧碰巧同为 0；
// random 初值档开比第 5 拍就分叉（seed 7 实测）—— tb 违反"先写后读"契约，不是 RTL 差异。
// 本生成器（scripts/dual_tb_lib.py，端口表读 G1 golden，逐拍比全部输出）：
//   · 读 PC / 更新 PC 从 16 项小池子取；ghist 与折叠历史在大部分阶段同时为 0（两者天然一致，写进表的项能被
//     同样的 PC 查中），其余阶段全随机；更新字段全随机（ITTageTable：alloc/correct/uValid/reset_u 各路径都走到）；
//   · MBIST 测试口与 SRAM 广播控制位平时钉 0，mode>=14 阶段全随机；
//   · 比较窗口：golden 发生过一次读请求握手（req.valid && req.ready）后再过 3 拍开比；
//   · 覆盖（golden 端口语义）：读命中 / 更新写入 / 分配（ITTageTable）/ reset_u（ITTageTable）/ 基础表更新（TageBTable）。
//
// 本文件：ITTageTable_1
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= ITTageTable_1 =================
  int unsigned p_mode = 0;
  logic [49:0] p_pool [16];
  initial for (int k = 0; k < 16; k++) p_pool[k] = {$urandom, $urandom} & ~50'h1;
  logic p_reset;
  wire  p_g_io_req_ready, p_i_io_req_ready;
  logic p_s0_io_req_ready = '0, p_s1_io_req_ready = '0;
  logic p_io_req_valid;
  logic [49:0] p_io_req_bits_pc;
  logic [7:0] p_io_req_bits_folded_hist_hist_14_folded_hist;
  wire  p_g_io_resp_valid, p_i_io_resp_valid;
  logic p_s0_io_resp_valid = '0, p_s1_io_resp_valid = '0;
  wire  [1:0] p_g_io_resp_bits_ctr, p_i_io_resp_bits_ctr;
  logic [1:0] p_s0_io_resp_bits_ctr = '0, p_s1_io_resp_bits_ctr = '0;
  wire  p_g_io_resp_bits_u, p_i_io_resp_bits_u;
  logic p_s0_io_resp_bits_u = '0, p_s1_io_resp_bits_u = '0;
  wire  [19:0] p_g_io_resp_bits_target_offset_offset, p_i_io_resp_bits_target_offset_offset;
  logic [19:0] p_s0_io_resp_bits_target_offset_offset = '0, p_s1_io_resp_bits_target_offset_offset = '0;
  wire  [3:0] p_g_io_resp_bits_target_offset_pointer, p_i_io_resp_bits_target_offset_pointer;
  logic [3:0] p_s0_io_resp_bits_target_offset_pointer = '0, p_s1_io_resp_bits_target_offset_pointer = '0;
  wire  p_g_io_resp_bits_target_offset_usePCRegion, p_i_io_resp_bits_target_offset_usePCRegion;
  logic p_s0_io_resp_bits_target_offset_usePCRegion = '0, p_s1_io_resp_bits_target_offset_usePCRegion = '0;
  logic [49:0] p_io_update_pc;
  logic [255:0] p_io_update_ghist;
  logic p_io_update_valid;
  logic p_io_update_correct;
  logic p_io_update_alloc;
  logic [1:0] p_io_update_oldCtr;
  logic p_io_update_uValid;
  logic p_io_update_u;
  logic p_io_update_reset_u;
  logic [19:0] p_io_update_target_offset_offset;
  logic [3:0] p_io_update_target_offset_pointer;
  logic p_io_update_target_offset_usePCRegion;
  logic [19:0] p_io_update_old_target_offset_offset;
  logic [3:0] p_io_update_old_target_offset_pointer;
  logic p_io_update_old_target_offset_usePCRegion;
  logic [6:0] p_boreChildrenBd_bore_array;
  logic p_boreChildrenBd_bore_all;
  logic p_boreChildrenBd_bore_req;
  wire  p_g_boreChildrenBd_bore_ack, p_i_boreChildrenBd_bore_ack;
  logic p_s0_boreChildrenBd_bore_ack = '0, p_s1_boreChildrenBd_bore_ack = '0;
  logic p_boreChildrenBd_bore_writeen;
  logic [75:0] p_boreChildrenBd_bore_be;
  logic [7:0] p_boreChildrenBd_bore_addr;
  logic [75:0] p_boreChildrenBd_bore_indata;
  logic p_boreChildrenBd_bore_readen;
  logic [7:0] p_boreChildrenBd_bore_addr_rd;
  wire  [75:0] p_g_boreChildrenBd_bore_outdata, p_i_boreChildrenBd_bore_outdata;
  logic [75:0] p_s0_boreChildrenBd_bore_outdata = '0, p_s1_boreChildrenBd_bore_outdata = '0;
  logic p_sigFromSrams_bore_ram_hold;
  logic p_sigFromSrams_bore_ram_bypass;
  logic p_sigFromSrams_bore_ram_bp_clken;
  logic p_sigFromSrams_bore_ram_aux_clk;
  logic p_sigFromSrams_bore_ram_aux_ckbp;
  logic p_sigFromSrams_bore_ram_mcp_hold;
  logic p_sigFromSrams_bore_cgen;
  int p_cov_read_fire = 0;
  int p_cov_resp_hit = 0;
  int p_cov_update_alloc = 0;
  int p_cov_update_correct = 0;
  int p_cov_reset_u = 0;
  logic [0:0] p_armed = '0;
  int p_armed_at = -1;
  ITTageTable_1 p_u_gold (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_g_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits_pc(p_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist(p_io_req_bits_folded_hist_hist_14_folded_hist),
    .io_resp_valid(p_g_io_resp_valid),
    .io_resp_bits_ctr(p_g_io_resp_bits_ctr),
    .io_resp_bits_u(p_g_io_resp_bits_u),
    .io_resp_bits_target_offset_offset(p_g_io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(p_g_io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(p_g_io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(p_io_update_pc),
    .io_update_ghist(p_io_update_ghist),
    .io_update_valid(p_io_update_valid),
    .io_update_correct(p_io_update_correct),
    .io_update_alloc(p_io_update_alloc),
    .io_update_oldCtr(p_io_update_oldCtr),
    .io_update_uValid(p_io_update_uValid),
    .io_update_u(p_io_update_u),
    .io_update_reset_u(p_io_update_reset_u),
    .io_update_target_offset_offset(p_io_update_target_offset_offset),
    .io_update_target_offset_pointer(p_io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(p_io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(p_io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(p_io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(p_io_update_old_target_offset_usePCRegion),
    .boreChildrenBd_bore_array(p_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(p_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(p_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(p_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(p_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(p_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(p_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(p_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(p_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(p_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(p_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(p_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(p_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(p_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(p_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(p_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(p_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(p_sigFromSrams_bore_cgen)
  );
  ITTageTable_1_xs p_u_impl (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_i_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits_pc(p_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist(p_io_req_bits_folded_hist_hist_14_folded_hist),
    .io_resp_valid(p_i_io_resp_valid),
    .io_resp_bits_ctr(p_i_io_resp_bits_ctr),
    .io_resp_bits_u(p_i_io_resp_bits_u),
    .io_resp_bits_target_offset_offset(p_i_io_resp_bits_target_offset_offset),
    .io_resp_bits_target_offset_pointer(p_i_io_resp_bits_target_offset_pointer),
    .io_resp_bits_target_offset_usePCRegion(p_i_io_resp_bits_target_offset_usePCRegion),
    .io_update_pc(p_io_update_pc),
    .io_update_ghist(p_io_update_ghist),
    .io_update_valid(p_io_update_valid),
    .io_update_correct(p_io_update_correct),
    .io_update_alloc(p_io_update_alloc),
    .io_update_oldCtr(p_io_update_oldCtr),
    .io_update_uValid(p_io_update_uValid),
    .io_update_u(p_io_update_u),
    .io_update_reset_u(p_io_update_reset_u),
    .io_update_target_offset_offset(p_io_update_target_offset_offset),
    .io_update_target_offset_pointer(p_io_update_target_offset_pointer),
    .io_update_target_offset_usePCRegion(p_io_update_target_offset_usePCRegion),
    .io_update_old_target_offset_offset(p_io_update_old_target_offset_offset),
    .io_update_old_target_offset_pointer(p_io_update_old_target_offset_pointer),
    .io_update_old_target_offset_usePCRegion(p_io_update_old_target_offset_usePCRegion),
    .boreChildrenBd_bore_array(p_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(p_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(p_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(p_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(p_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(p_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(p_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(p_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(p_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(p_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(p_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(p_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(p_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(p_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(p_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(p_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(p_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(p_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) p_mode = $urandom_range(0, 15);
      p_io_req_valid = 1'($urandom);
      p_io_req_bits_pc = 50'({$urandom, $urandom});
      p_io_req_bits_folded_hist_hist_14_folded_hist = 8'($urandom);
      p_io_update_pc = 50'({$urandom, $urandom});
      p_io_update_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      p_io_update_valid = 1'($urandom);
      p_io_update_correct = 1'($urandom);
      p_io_update_alloc = 1'($urandom);
      p_io_update_oldCtr = 2'($urandom);
      p_io_update_uValid = 1'($urandom);
      p_io_update_u = 1'($urandom);
      p_io_update_reset_u = 1'($urandom);
      p_io_update_target_offset_offset = 20'($urandom);
      p_io_update_target_offset_pointer = 4'($urandom);
      p_io_update_target_offset_usePCRegion = 1'($urandom);
      p_io_update_old_target_offset_offset = 20'($urandom);
      p_io_update_old_target_offset_pointer = 4'($urandom);
      p_io_update_old_target_offset_usePCRegion = 1'($urandom);
      p_boreChildrenBd_bore_array = 7'($urandom);
      p_boreChildrenBd_bore_all = 1'($urandom);
      p_boreChildrenBd_bore_req = 1'($urandom);
      p_boreChildrenBd_bore_writeen = 1'($urandom);
      p_boreChildrenBd_bore_be = 76'({$urandom, $urandom, $urandom});
      p_boreChildrenBd_bore_addr = 8'($urandom);
      p_boreChildrenBd_bore_indata = 76'({$urandom, $urandom, $urandom});
      p_boreChildrenBd_bore_readen = 1'($urandom);
      p_boreChildrenBd_bore_addr_rd = 8'($urandom);
      p_sigFromSrams_bore_ram_hold = 1'($urandom);
      p_sigFromSrams_bore_ram_bypass = 1'($urandom);
      p_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      p_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      p_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      p_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      p_sigFromSrams_bore_cgen = 1'($urandom);
      p_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p
        p_io_req_bits_pc = p_pool[$urandom_range(0, 15)];
        p_io_update_pc = p_pool[$urandom_range(0, 15)];
        p_io_update_reset_u = ($urandom_range(0, 255) == 0);
        if (p_mode < 12) begin
          p_io_update_ghist = '0;
          p_io_req_bits_folded_hist_hist_14_folded_hist = '0;
        end
        if (p_mode < 14) begin
          p_boreChildrenBd_bore_all = '0;
          p_boreChildrenBd_bore_req = '0;
          p_sigFromSrams_bore_ram_hold = '0;
          p_sigFromSrams_bore_ram_bypass = '0;
          p_sigFromSrams_bore_ram_bp_clken = '0;
          p_sigFromSrams_bore_ram_aux_clk = '0;
          p_sigFromSrams_bore_ram_aux_ckbp = '0;
          p_sigFromSrams_bore_ram_mcp_hold = '0;
          p_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && p_armed_at >= 0 && cyc >= p_armed_at) begin
        checks++;
        if (p_g_io_req_ready !== p_i_io_req_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_req_ready g=%h i=%h", cyc, p_g_io_req_ready, p_i_io_req_ready);
        end
        p_s1_io_req_ready |= p_g_io_req_ready;
        p_s0_io_req_ready |= ~p_g_io_req_ready;
        checks++;
        if (p_g_io_resp_valid !== p_i_io_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_valid g=%h i=%h", cyc, p_g_io_resp_valid, p_i_io_resp_valid);
        end
        p_s1_io_resp_valid |= p_g_io_resp_valid;
        p_s0_io_resp_valid |= ~p_g_io_resp_valid;
        checks++;
        if (p_g_io_resp_bits_ctr !== p_i_io_resp_bits_ctr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_bits_ctr g=%h i=%h", cyc, p_g_io_resp_bits_ctr, p_i_io_resp_bits_ctr);
        end
        p_s1_io_resp_bits_ctr |= p_g_io_resp_bits_ctr;
        p_s0_io_resp_bits_ctr |= ~p_g_io_resp_bits_ctr;
        checks++;
        if (p_g_io_resp_bits_u !== p_i_io_resp_bits_u) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_bits_u g=%h i=%h", cyc, p_g_io_resp_bits_u, p_i_io_resp_bits_u);
        end
        p_s1_io_resp_bits_u |= p_g_io_resp_bits_u;
        p_s0_io_resp_bits_u |= ~p_g_io_resp_bits_u;
        checks++;
        if (p_g_io_resp_bits_target_offset_offset !== p_i_io_resp_bits_target_offset_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_bits_target_offset_offset g=%h i=%h", cyc, p_g_io_resp_bits_target_offset_offset, p_i_io_resp_bits_target_offset_offset);
        end
        p_s1_io_resp_bits_target_offset_offset |= p_g_io_resp_bits_target_offset_offset;
        p_s0_io_resp_bits_target_offset_offset |= ~p_g_io_resp_bits_target_offset_offset;
        checks++;
        if (p_g_io_resp_bits_target_offset_pointer !== p_i_io_resp_bits_target_offset_pointer) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_bits_target_offset_pointer g=%h i=%h", cyc, p_g_io_resp_bits_target_offset_pointer, p_i_io_resp_bits_target_offset_pointer);
        end
        p_s1_io_resp_bits_target_offset_pointer |= p_g_io_resp_bits_target_offset_pointer;
        p_s0_io_resp_bits_target_offset_pointer |= ~p_g_io_resp_bits_target_offset_pointer;
        checks++;
        if (p_g_io_resp_bits_target_offset_usePCRegion !== p_i_io_resp_bits_target_offset_usePCRegion) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.io_resp_bits_target_offset_usePCRegion g=%h i=%h", cyc, p_g_io_resp_bits_target_offset_usePCRegion, p_i_io_resp_bits_target_offset_usePCRegion);
        end
        p_s1_io_resp_bits_target_offset_usePCRegion |= p_g_io_resp_bits_target_offset_usePCRegion;
        p_s0_io_resp_bits_target_offset_usePCRegion |= ~p_g_io_resp_bits_target_offset_usePCRegion;
        checks++;
        if (p_g_boreChildrenBd_bore_ack !== p_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.boreChildrenBd_bore_ack g=%h i=%h", cyc, p_g_boreChildrenBd_bore_ack, p_i_boreChildrenBd_bore_ack);
        end
        p_s1_boreChildrenBd_bore_ack |= p_g_boreChildrenBd_bore_ack;
        p_s0_boreChildrenBd_bore_ack |= ~p_g_boreChildrenBd_bore_ack;
        checks++;
        if (p_g_boreChildrenBd_bore_outdata !== p_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ITTageTable_1.boreChildrenBd_bore_outdata g=%h i=%h", cyc, p_g_boreChildrenBd_bore_outdata, p_i_boreChildrenBd_bore_outdata);
        end
        p_s1_boreChildrenBd_bore_outdata |= p_g_boreChildrenBd_bore_outdata;
        p_s0_boreChildrenBd_bore_outdata |= ~p_g_boreChildrenBd_bore_outdata;
        if (p_io_req_valid && p_g_io_req_ready) p_cov_read_fire++;
        if (p_g_io_resp_valid) p_cov_resp_hit++;
        if (p_io_update_valid && p_io_update_alloc) p_cov_update_alloc++;
        if (p_io_update_valid && !p_io_update_alloc && p_io_update_correct) p_cov_update_correct++;
        if (p_io_update_reset_u) p_cov_reset_u++;
      end
      if (p_io_req_valid && p_g_io_req_ready) p_armed[0] = 1'b1;
      if (p_armed_at < 0 && (&p_armed)) p_armed_at = cyc + 1 + 3;
    end

    // ---- 覆盖闸 ----
    if (!(p_s0_io_req_ready && p_s1_io_req_ready)) begin cov_fail++; $display("[COV] ITTageTable_1.io_req_ready 未见过 0 和 1"); end
    if (!(p_s0_io_resp_valid && p_s1_io_resp_valid)) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_valid 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_ctr[0] && p_s1_io_resp_bits_ctr[0])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_ctr[0] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_ctr[1] && p_s1_io_resp_bits_ctr[1])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_ctr[1] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_u && p_s1_io_resp_bits_u)) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_u 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[0] && p_s1_io_resp_bits_target_offset_offset[0])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[0] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[1] && p_s1_io_resp_bits_target_offset_offset[1])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[1] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[2] && p_s1_io_resp_bits_target_offset_offset[2])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[2] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[3] && p_s1_io_resp_bits_target_offset_offset[3])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[3] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[4] && p_s1_io_resp_bits_target_offset_offset[4])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[4] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[5] && p_s1_io_resp_bits_target_offset_offset[5])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[5] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[6] && p_s1_io_resp_bits_target_offset_offset[6])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[6] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[7] && p_s1_io_resp_bits_target_offset_offset[7])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[7] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[8] && p_s1_io_resp_bits_target_offset_offset[8])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[8] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[9] && p_s1_io_resp_bits_target_offset_offset[9])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[9] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[10] && p_s1_io_resp_bits_target_offset_offset[10])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[10] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[11] && p_s1_io_resp_bits_target_offset_offset[11])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[11] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[12] && p_s1_io_resp_bits_target_offset_offset[12])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[12] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[13] && p_s1_io_resp_bits_target_offset_offset[13])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[13] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[14] && p_s1_io_resp_bits_target_offset_offset[14])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[14] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[15] && p_s1_io_resp_bits_target_offset_offset[15])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[15] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[16] && p_s1_io_resp_bits_target_offset_offset[16])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[16] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[17] && p_s1_io_resp_bits_target_offset_offset[17])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[17] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[18] && p_s1_io_resp_bits_target_offset_offset[18])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[18] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_offset[19] && p_s1_io_resp_bits_target_offset_offset[19])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_offset[19] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_pointer[0] && p_s1_io_resp_bits_target_offset_pointer[0])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_pointer[0] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_pointer[1] && p_s1_io_resp_bits_target_offset_pointer[1])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_pointer[1] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_pointer[2] && p_s1_io_resp_bits_target_offset_pointer[2])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_pointer[2] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_pointer[3] && p_s1_io_resp_bits_target_offset_pointer[3])) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_pointer[3] 未见过 0 和 1"); end
    if (!(p_s0_io_resp_bits_target_offset_usePCRegion && p_s1_io_resp_bits_target_offset_usePCRegion)) begin cov_fail++; $display("[COV] ITTageTable_1.io_resp_bits_target_offset_usePCRegion 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_ack && p_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[0] && p_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[1] && p_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[2] && p_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[3] && p_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[4] && p_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[5] && p_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[6] && p_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[7] && p_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[8] && p_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[9] && p_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[10] && p_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[11] && p_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[12] && p_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[13] && p_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[14] && p_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[15] && p_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[16] && p_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[17] && p_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[18] && p_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[19] && p_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[20] && p_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[21] && p_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[22] && p_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[23] && p_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[24] && p_s1_boreChildrenBd_bore_outdata[24])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[24] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[25] && p_s1_boreChildrenBd_bore_outdata[25])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[25] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[26] && p_s1_boreChildrenBd_bore_outdata[26])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[26] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[27] && p_s1_boreChildrenBd_bore_outdata[27])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[27] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[28] && p_s1_boreChildrenBd_bore_outdata[28])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[28] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[29] && p_s1_boreChildrenBd_bore_outdata[29])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[29] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[30] && p_s1_boreChildrenBd_bore_outdata[30])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[30] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[31] && p_s1_boreChildrenBd_bore_outdata[31])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[31] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[32] && p_s1_boreChildrenBd_bore_outdata[32])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[32] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[33] && p_s1_boreChildrenBd_bore_outdata[33])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[33] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[34] && p_s1_boreChildrenBd_bore_outdata[34])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[34] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[35] && p_s1_boreChildrenBd_bore_outdata[35])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[35] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[36] && p_s1_boreChildrenBd_bore_outdata[36])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[36] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[37] && p_s1_boreChildrenBd_bore_outdata[37])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[37] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[38] && p_s1_boreChildrenBd_bore_outdata[38])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[38] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[39] && p_s1_boreChildrenBd_bore_outdata[39])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[39] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[40] && p_s1_boreChildrenBd_bore_outdata[40])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[40] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[41] && p_s1_boreChildrenBd_bore_outdata[41])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[41] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[42] && p_s1_boreChildrenBd_bore_outdata[42])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[42] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[43] && p_s1_boreChildrenBd_bore_outdata[43])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[43] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[44] && p_s1_boreChildrenBd_bore_outdata[44])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[44] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[45] && p_s1_boreChildrenBd_bore_outdata[45])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[45] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[46] && p_s1_boreChildrenBd_bore_outdata[46])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[46] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[47] && p_s1_boreChildrenBd_bore_outdata[47])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[47] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[48] && p_s1_boreChildrenBd_bore_outdata[48])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[48] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[49] && p_s1_boreChildrenBd_bore_outdata[49])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[49] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[50] && p_s1_boreChildrenBd_bore_outdata[50])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[50] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[51] && p_s1_boreChildrenBd_bore_outdata[51])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[51] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[52] && p_s1_boreChildrenBd_bore_outdata[52])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[52] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[53] && p_s1_boreChildrenBd_bore_outdata[53])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[53] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[54] && p_s1_boreChildrenBd_bore_outdata[54])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[54] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[55] && p_s1_boreChildrenBd_bore_outdata[55])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[55] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[56] && p_s1_boreChildrenBd_bore_outdata[56])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[56] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[57] && p_s1_boreChildrenBd_bore_outdata[57])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[57] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[58] && p_s1_boreChildrenBd_bore_outdata[58])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[58] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[59] && p_s1_boreChildrenBd_bore_outdata[59])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[59] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[60] && p_s1_boreChildrenBd_bore_outdata[60])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[60] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[61] && p_s1_boreChildrenBd_bore_outdata[61])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[61] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[62] && p_s1_boreChildrenBd_bore_outdata[62])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[62] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[63] && p_s1_boreChildrenBd_bore_outdata[63])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[63] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[64] && p_s1_boreChildrenBd_bore_outdata[64])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[64] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[65] && p_s1_boreChildrenBd_bore_outdata[65])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[65] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[66] && p_s1_boreChildrenBd_bore_outdata[66])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[66] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[67] && p_s1_boreChildrenBd_bore_outdata[67])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[67] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[68] && p_s1_boreChildrenBd_bore_outdata[68])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[68] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[69] && p_s1_boreChildrenBd_bore_outdata[69])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[69] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[70] && p_s1_boreChildrenBd_bore_outdata[70])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[70] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[71] && p_s1_boreChildrenBd_bore_outdata[71])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[71] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[72] && p_s1_boreChildrenBd_bore_outdata[72])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[72] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[73] && p_s1_boreChildrenBd_bore_outdata[73])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[73] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[74] && p_s1_boreChildrenBd_bore_outdata[74])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[74] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_outdata[75] && p_s1_boreChildrenBd_bore_outdata[75])) begin cov_fail++; $display("[COV] ITTageTable_1.boreChildrenBd_bore_outdata[75] 未见过 0 和 1"); end
    $display("[ARM] ITTageTable_1 armed_at=%0d", p_armed_at);
    if (p_armed_at < 0) begin cov_fail++; $display("[ARM] ITTageTable_1 从未 arm"); end
    $display("[COV] ITTageTable_1.read_fire = %0d", p_cov_read_fire);
    if (p_cov_read_fire < 20) begin cov_fail++; $display("[COV] ITTageTable_1.read_fire < 20"); end
    $display("[COV] ITTageTable_1.resp_hit = %0d", p_cov_resp_hit);
    if (p_cov_resp_hit < 20) begin cov_fail++; $display("[COV] ITTageTable_1.resp_hit < 20"); end
    $display("[COV] ITTageTable_1.update_alloc = %0d", p_cov_update_alloc);
    if (p_cov_update_alloc < 20) begin cov_fail++; $display("[COV] ITTageTable_1.update_alloc < 20"); end
    $display("[COV] ITTageTable_1.update_correct = %0d", p_cov_update_correct);
    if (p_cov_update_correct < 20) begin cov_fail++; $display("[COV] ITTageTable_1.update_correct < 20"); end
    $display("[COV] ITTageTable_1.reset_u = %0d", p_cov_reset_u);
    if (p_cov_reset_u < 20) begin cov_fail++; $display("[COV] ITTageTable_1.reset_u < 20"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
