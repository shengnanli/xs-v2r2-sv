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
// 本文件：TageBTable
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= TageBTable =================
  int unsigned p_mode = 0;
  logic [49:0] p_pool [16];
  initial for (int k = 0; k < 16; k++) p_pool[k] = {$urandom, $urandom} & ~50'h1;
  logic p_reset;
  wire  p_g_io_req_ready, p_i_io_req_ready;
  logic p_s0_io_req_ready = '0, p_s1_io_req_ready = '0;
  logic p_io_req_valid;
  logic [49:0] p_io_req_bits;
  wire  [1:0] p_g_io_s1_cnt_0, p_i_io_s1_cnt_0;
  logic [1:0] p_s0_io_s1_cnt_0 = '0, p_s1_io_s1_cnt_0 = '0;
  wire  [1:0] p_g_io_s1_cnt_1, p_i_io_s1_cnt_1;
  logic [1:0] p_s0_io_s1_cnt_1 = '0, p_s1_io_s1_cnt_1 = '0;
  wire  p_g_io_s1_resp_valid, p_i_io_s1_resp_valid;
  logic p_s0_io_s1_resp_valid = '0, p_s1_io_s1_resp_valid = '0;
  logic p_io_update_mask_0;
  logic p_io_update_mask_1;
  logic [49:0] p_io_update_pc;
  logic [1:0] p_io_update_cnt_0;
  logic [1:0] p_io_update_cnt_1;
  logic p_io_update_takens_0;
  logic p_io_update_takens_1;
  logic [8:0] p_boreChildrenBd_bore_addr;
  logic [8:0] p_boreChildrenBd_bore_addr_rd;
  logic [7:0] p_boreChildrenBd_bore_wdata;
  logic [3:0] p_boreChildrenBd_bore_wmask;
  logic p_boreChildrenBd_bore_re;
  logic p_boreChildrenBd_bore_we;
  wire  [7:0] p_g_boreChildrenBd_bore_rdata, p_i_boreChildrenBd_bore_rdata;
  logic [7:0] p_s0_boreChildrenBd_bore_rdata = '0, p_s1_boreChildrenBd_bore_rdata = '0;
  logic p_boreChildrenBd_bore_ack;
  logic p_boreChildrenBd_bore_selectedOH;
  logic [6:0] p_boreChildrenBd_bore_array;
  logic [8:0] p_boreChildrenBd_bore_1_addr;
  logic [8:0] p_boreChildrenBd_bore_1_addr_rd;
  logic [7:0] p_boreChildrenBd_bore_1_wdata;
  logic [3:0] p_boreChildrenBd_bore_1_wmask;
  logic p_boreChildrenBd_bore_1_re;
  logic p_boreChildrenBd_bore_1_we;
  wire  [7:0] p_g_boreChildrenBd_bore_1_rdata, p_i_boreChildrenBd_bore_1_rdata;
  logic [7:0] p_s0_boreChildrenBd_bore_1_rdata = '0, p_s1_boreChildrenBd_bore_1_rdata = '0;
  logic p_boreChildrenBd_bore_1_ack;
  logic p_boreChildrenBd_bore_1_selectedOH;
  logic [6:0] p_boreChildrenBd_bore_1_array;
  logic [8:0] p_boreChildrenBd_bore_2_addr;
  logic [8:0] p_boreChildrenBd_bore_2_addr_rd;
  logic [7:0] p_boreChildrenBd_bore_2_wdata;
  logic [3:0] p_boreChildrenBd_bore_2_wmask;
  logic p_boreChildrenBd_bore_2_re;
  logic p_boreChildrenBd_bore_2_we;
  wire  [7:0] p_g_boreChildrenBd_bore_2_rdata, p_i_boreChildrenBd_bore_2_rdata;
  logic [7:0] p_s0_boreChildrenBd_bore_2_rdata = '0, p_s1_boreChildrenBd_bore_2_rdata = '0;
  logic p_boreChildrenBd_bore_2_ack;
  logic p_boreChildrenBd_bore_2_selectedOH;
  logic [6:0] p_boreChildrenBd_bore_2_array;
  logic [8:0] p_boreChildrenBd_bore_3_addr;
  logic [8:0] p_boreChildrenBd_bore_3_addr_rd;
  logic [7:0] p_boreChildrenBd_bore_3_wdata;
  logic [3:0] p_boreChildrenBd_bore_3_wmask;
  logic p_boreChildrenBd_bore_3_re;
  logic p_boreChildrenBd_bore_3_we;
  wire  [7:0] p_g_boreChildrenBd_bore_3_rdata, p_i_boreChildrenBd_bore_3_rdata;
  logic [7:0] p_s0_boreChildrenBd_bore_3_rdata = '0, p_s1_boreChildrenBd_bore_3_rdata = '0;
  logic p_boreChildrenBd_bore_3_ack;
  logic p_boreChildrenBd_bore_3_selectedOH;
  logic [6:0] p_boreChildrenBd_bore_3_array;
  logic p_sigFromSrams_bore_ram_hold;
  logic p_sigFromSrams_bore_ram_bypass;
  logic p_sigFromSrams_bore_ram_bp_clken;
  logic p_sigFromSrams_bore_ram_aux_clk;
  logic p_sigFromSrams_bore_ram_aux_ckbp;
  logic p_sigFromSrams_bore_ram_mcp_hold;
  logic p_sigFromSrams_bore_cgen;
  logic p_sigFromSrams_bore_1_ram_hold;
  logic p_sigFromSrams_bore_1_ram_bypass;
  logic p_sigFromSrams_bore_1_ram_bp_clken;
  logic p_sigFromSrams_bore_1_ram_aux_clk;
  logic p_sigFromSrams_bore_1_ram_aux_ckbp;
  logic p_sigFromSrams_bore_1_ram_mcp_hold;
  logic p_sigFromSrams_bore_1_cgen;
  logic p_sigFromSrams_bore_2_ram_hold;
  logic p_sigFromSrams_bore_2_ram_bypass;
  logic p_sigFromSrams_bore_2_ram_bp_clken;
  logic p_sigFromSrams_bore_2_ram_aux_clk;
  logic p_sigFromSrams_bore_2_ram_aux_ckbp;
  logic p_sigFromSrams_bore_2_ram_mcp_hold;
  logic p_sigFromSrams_bore_2_cgen;
  logic p_sigFromSrams_bore_3_ram_hold;
  logic p_sigFromSrams_bore_3_ram_bypass;
  logic p_sigFromSrams_bore_3_ram_bp_clken;
  logic p_sigFromSrams_bore_3_ram_aux_clk;
  logic p_sigFromSrams_bore_3_ram_aux_ckbp;
  logic p_sigFromSrams_bore_3_ram_mcp_hold;
  logic p_sigFromSrams_bore_3_cgen;
  int p_cov_read_fire = 0;
  int p_cov_resp_valid = 0;
  int p_cov_update_any = 0;
  logic [0:0] p_armed = '0;
  int p_armed_at = -1;
  TageBTable p_u_gold (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_g_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits(p_io_req_bits),
    .io_s1_cnt_0(p_g_io_s1_cnt_0),
    .io_s1_cnt_1(p_g_io_s1_cnt_1),
    .io_s1_resp_valid(p_g_io_s1_resp_valid),
    .io_update_mask_0(p_io_update_mask_0),
    .io_update_mask_1(p_io_update_mask_1),
    .io_update_pc(p_io_update_pc),
    .io_update_cnt_0(p_io_update_cnt_0),
    .io_update_cnt_1(p_io_update_cnt_1),
    .io_update_takens_0(p_io_update_takens_0),
    .io_update_takens_1(p_io_update_takens_1),
    .boreChildrenBd_bore_addr(p_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(p_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(p_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(p_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(p_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(p_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(p_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(p_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(p_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(p_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(p_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(p_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(p_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(p_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(p_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(p_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(p_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(p_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(p_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(p_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(p_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(p_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(p_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(p_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(p_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(p_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(p_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(p_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(p_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(p_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(p_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(p_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(p_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(p_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(p_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(p_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(p_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(p_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(p_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(p_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(p_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(p_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(p_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(p_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(p_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(p_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(p_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(p_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(p_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(p_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(p_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(p_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(p_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(p_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(p_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(p_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(p_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(p_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(p_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(p_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(p_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(p_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(p_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(p_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(p_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(p_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(p_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(p_sigFromSrams_bore_3_cgen)
  );
  TageBTable_xs p_u_impl (
    .clock(clk),
    .reset(p_reset),
    .io_req_ready(p_i_io_req_ready),
    .io_req_valid(p_io_req_valid),
    .io_req_bits(p_io_req_bits),
    .io_s1_cnt_0(p_i_io_s1_cnt_0),
    .io_s1_cnt_1(p_i_io_s1_cnt_1),
    .io_s1_resp_valid(p_i_io_s1_resp_valid),
    .io_update_mask_0(p_io_update_mask_0),
    .io_update_mask_1(p_io_update_mask_1),
    .io_update_pc(p_io_update_pc),
    .io_update_cnt_0(p_io_update_cnt_0),
    .io_update_cnt_1(p_io_update_cnt_1),
    .io_update_takens_0(p_io_update_takens_0),
    .io_update_takens_1(p_io_update_takens_1),
    .boreChildrenBd_bore_addr(p_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(p_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(p_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(p_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(p_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(p_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(p_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(p_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(p_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(p_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(p_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(p_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(p_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(p_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(p_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(p_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(p_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(p_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(p_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(p_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(p_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(p_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(p_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(p_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(p_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(p_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(p_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(p_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(p_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(p_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(p_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(p_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(p_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(p_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(p_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(p_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(p_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(p_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(p_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(p_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(p_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(p_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(p_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(p_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(p_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(p_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(p_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(p_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(p_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(p_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(p_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(p_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(p_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(p_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(p_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(p_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(p_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(p_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(p_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(p_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(p_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(p_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(p_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(p_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(p_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(p_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(p_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(p_sigFromSrams_bore_3_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) p_mode = $urandom_range(0, 15);
      p_io_req_valid = 1'($urandom);
      p_io_req_bits = 50'({$urandom, $urandom});
      p_io_update_mask_0 = 1'($urandom);
      p_io_update_mask_1 = 1'($urandom);
      p_io_update_pc = 50'({$urandom, $urandom});
      p_io_update_cnt_0 = 2'($urandom);
      p_io_update_cnt_1 = 2'($urandom);
      p_io_update_takens_0 = 1'($urandom);
      p_io_update_takens_1 = 1'($urandom);
      p_boreChildrenBd_bore_addr = 9'($urandom);
      p_boreChildrenBd_bore_addr_rd = 9'($urandom);
      p_boreChildrenBd_bore_wdata = 8'($urandom);
      p_boreChildrenBd_bore_wmask = 4'($urandom);
      p_boreChildrenBd_bore_re = 1'($urandom);
      p_boreChildrenBd_bore_we = 1'($urandom);
      p_boreChildrenBd_bore_ack = 1'($urandom);
      p_boreChildrenBd_bore_selectedOH = 1'($urandom);
      p_boreChildrenBd_bore_array = 7'($urandom);
      p_boreChildrenBd_bore_1_addr = 9'($urandom);
      p_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      p_boreChildrenBd_bore_1_wdata = 8'($urandom);
      p_boreChildrenBd_bore_1_wmask = 4'($urandom);
      p_boreChildrenBd_bore_1_re = 1'($urandom);
      p_boreChildrenBd_bore_1_we = 1'($urandom);
      p_boreChildrenBd_bore_1_ack = 1'($urandom);
      p_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      p_boreChildrenBd_bore_1_array = 7'($urandom);
      p_boreChildrenBd_bore_2_addr = 9'($urandom);
      p_boreChildrenBd_bore_2_addr_rd = 9'($urandom);
      p_boreChildrenBd_bore_2_wdata = 8'($urandom);
      p_boreChildrenBd_bore_2_wmask = 4'($urandom);
      p_boreChildrenBd_bore_2_re = 1'($urandom);
      p_boreChildrenBd_bore_2_we = 1'($urandom);
      p_boreChildrenBd_bore_2_ack = 1'($urandom);
      p_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      p_boreChildrenBd_bore_2_array = 7'($urandom);
      p_boreChildrenBd_bore_3_addr = 9'($urandom);
      p_boreChildrenBd_bore_3_addr_rd = 9'($urandom);
      p_boreChildrenBd_bore_3_wdata = 8'($urandom);
      p_boreChildrenBd_bore_3_wmask = 4'($urandom);
      p_boreChildrenBd_bore_3_re = 1'($urandom);
      p_boreChildrenBd_bore_3_we = 1'($urandom);
      p_boreChildrenBd_bore_3_ack = 1'($urandom);
      p_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      p_boreChildrenBd_bore_3_array = 7'($urandom);
      p_sigFromSrams_bore_ram_hold = 1'($urandom);
      p_sigFromSrams_bore_ram_bypass = 1'($urandom);
      p_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      p_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      p_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      p_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      p_sigFromSrams_bore_cgen = 1'($urandom);
      p_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      p_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      p_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      p_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      p_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      p_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      p_sigFromSrams_bore_1_cgen = 1'($urandom);
      p_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      p_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      p_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      p_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      p_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      p_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      p_sigFromSrams_bore_2_cgen = 1'($urandom);
      p_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      p_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      p_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      p_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      p_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      p_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      p_sigFromSrams_bore_3_cgen = 1'($urandom);
      p_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p
        p_io_req_bits = p_pool[$urandom_range(0, 15)];
        p_io_update_pc = p_pool[$urandom_range(0, 15)];
        if (p_mode < 14) begin
          p_sigFromSrams_bore_ram_hold = '0;
          p_sigFromSrams_bore_ram_bypass = '0;
          p_sigFromSrams_bore_ram_bp_clken = '0;
          p_sigFromSrams_bore_ram_aux_clk = '0;
          p_sigFromSrams_bore_ram_aux_ckbp = '0;
          p_sigFromSrams_bore_ram_mcp_hold = '0;
          p_sigFromSrams_bore_cgen = '0;
          p_sigFromSrams_bore_1_ram_hold = '0;
          p_sigFromSrams_bore_1_ram_bypass = '0;
          p_sigFromSrams_bore_1_ram_bp_clken = '0;
          p_sigFromSrams_bore_1_ram_aux_clk = '0;
          p_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          p_sigFromSrams_bore_1_ram_mcp_hold = '0;
          p_sigFromSrams_bore_1_cgen = '0;
          p_sigFromSrams_bore_2_ram_hold = '0;
          p_sigFromSrams_bore_2_ram_bypass = '0;
          p_sigFromSrams_bore_2_ram_bp_clken = '0;
          p_sigFromSrams_bore_2_ram_aux_clk = '0;
          p_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          p_sigFromSrams_bore_2_ram_mcp_hold = '0;
          p_sigFromSrams_bore_2_cgen = '0;
          p_sigFromSrams_bore_3_ram_hold = '0;
          p_sigFromSrams_bore_3_ram_bypass = '0;
          p_sigFromSrams_bore_3_ram_bp_clken = '0;
          p_sigFromSrams_bore_3_ram_aux_clk = '0;
          p_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          p_sigFromSrams_bore_3_ram_mcp_hold = '0;
          p_sigFromSrams_bore_3_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && p_armed_at >= 0 && cyc >= p_armed_at) begin
        checks++;
        if (p_g_io_req_ready !== p_i_io_req_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.io_req_ready g=%h i=%h", cyc, p_g_io_req_ready, p_i_io_req_ready);
        end
        p_s1_io_req_ready |= p_g_io_req_ready;
        p_s0_io_req_ready |= ~p_g_io_req_ready;
        checks++;
        if (p_g_io_s1_cnt_0 !== p_i_io_s1_cnt_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.io_s1_cnt_0 g=%h i=%h", cyc, p_g_io_s1_cnt_0, p_i_io_s1_cnt_0);
        end
        p_s1_io_s1_cnt_0 |= p_g_io_s1_cnt_0;
        p_s0_io_s1_cnt_0 |= ~p_g_io_s1_cnt_0;
        checks++;
        if (p_g_io_s1_cnt_1 !== p_i_io_s1_cnt_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.io_s1_cnt_1 g=%h i=%h", cyc, p_g_io_s1_cnt_1, p_i_io_s1_cnt_1);
        end
        p_s1_io_s1_cnt_1 |= p_g_io_s1_cnt_1;
        p_s0_io_s1_cnt_1 |= ~p_g_io_s1_cnt_1;
        checks++;
        if (p_g_io_s1_resp_valid !== p_i_io_s1_resp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.io_s1_resp_valid g=%h i=%h", cyc, p_g_io_s1_resp_valid, p_i_io_s1_resp_valid);
        end
        p_s1_io_s1_resp_valid |= p_g_io_s1_resp_valid;
        p_s0_io_s1_resp_valid |= ~p_g_io_s1_resp_valid;
        checks++;
        if (p_g_boreChildrenBd_bore_rdata !== p_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.boreChildrenBd_bore_rdata g=%h i=%h", cyc, p_g_boreChildrenBd_bore_rdata, p_i_boreChildrenBd_bore_rdata);
        end
        p_s1_boreChildrenBd_bore_rdata |= p_g_boreChildrenBd_bore_rdata;
        p_s0_boreChildrenBd_bore_rdata |= ~p_g_boreChildrenBd_bore_rdata;
        checks++;
        if (p_g_boreChildrenBd_bore_1_rdata !== p_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, p_g_boreChildrenBd_bore_1_rdata, p_i_boreChildrenBd_bore_1_rdata);
        end
        p_s1_boreChildrenBd_bore_1_rdata |= p_g_boreChildrenBd_bore_1_rdata;
        p_s0_boreChildrenBd_bore_1_rdata |= ~p_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (p_g_boreChildrenBd_bore_2_rdata !== p_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, p_g_boreChildrenBd_bore_2_rdata, p_i_boreChildrenBd_bore_2_rdata);
        end
        p_s1_boreChildrenBd_bore_2_rdata |= p_g_boreChildrenBd_bore_2_rdata;
        p_s0_boreChildrenBd_bore_2_rdata |= ~p_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (p_g_boreChildrenBd_bore_3_rdata !== p_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d TageBTable.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, p_g_boreChildrenBd_bore_3_rdata, p_i_boreChildrenBd_bore_3_rdata);
        end
        p_s1_boreChildrenBd_bore_3_rdata |= p_g_boreChildrenBd_bore_3_rdata;
        p_s0_boreChildrenBd_bore_3_rdata |= ~p_g_boreChildrenBd_bore_3_rdata;
        if (p_io_req_valid && p_g_io_req_ready) p_cov_read_fire++;
        if (p_g_io_s1_resp_valid) p_cov_resp_valid++;
        if (p_io_update_mask_0 || p_io_update_mask_1) p_cov_update_any++;
      end
      if (p_io_req_valid && p_g_io_req_ready) p_armed[0] = 1'b1;
      if (p_armed_at < 0 && (&p_armed)) p_armed_at = cyc + 1 + 3;
    end

    // ---- 覆盖闸 ----
    if (!(p_s0_io_req_ready && p_s1_io_req_ready)) begin cov_fail++; $display("[COV] TageBTable.io_req_ready 未见过 0 和 1"); end
    if (!(p_s0_io_s1_cnt_0[0] && p_s1_io_s1_cnt_0[0])) begin cov_fail++; $display("[COV] TageBTable.io_s1_cnt_0[0] 未见过 0 和 1"); end
    if (!(p_s0_io_s1_cnt_0[1] && p_s1_io_s1_cnt_0[1])) begin cov_fail++; $display("[COV] TageBTable.io_s1_cnt_0[1] 未见过 0 和 1"); end
    if (!(p_s0_io_s1_cnt_1[0] && p_s1_io_s1_cnt_1[0])) begin cov_fail++; $display("[COV] TageBTable.io_s1_cnt_1[0] 未见过 0 和 1"); end
    if (!(p_s0_io_s1_cnt_1[1] && p_s1_io_s1_cnt_1[1])) begin cov_fail++; $display("[COV] TageBTable.io_s1_cnt_1[1] 未见过 0 和 1"); end
    if (!(p_s0_io_s1_resp_valid && p_s1_io_s1_resp_valid)) begin cov_fail++; $display("[COV] TageBTable.io_s1_resp_valid 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[0] && p_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[1] && p_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[2] && p_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[3] && p_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[4] && p_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[5] && p_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[6] && p_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_rdata[7] && p_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[0] && p_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[1] && p_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[2] && p_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[3] && p_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[4] && p_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[5] && p_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[6] && p_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_1_rdata[7] && p_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[0] && p_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[1] && p_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[2] && p_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[3] && p_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[4] && p_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[5] && p_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[6] && p_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_2_rdata[7] && p_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[0] && p_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[1] && p_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[2] && p_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[3] && p_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[4] && p_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[5] && p_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[6] && p_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(p_s0_boreChildrenBd_bore_3_rdata[7] && p_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] TageBTable.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    $display("[ARM] TageBTable armed_at=%0d", p_armed_at);
    if (p_armed_at < 0) begin cov_fail++; $display("[ARM] TageBTable 从未 arm"); end
    $display("[COV] TageBTable.read_fire = %0d", p_cov_read_fire);
    if (p_cov_read_fire < 20) begin cov_fail++; $display("[COV] TageBTable.read_fire < 20"); end
    $display("[COV] TageBTable.resp_valid = %0d", p_cov_resp_valid);
    if (p_cov_resp_valid < 20) begin cov_fail++; $display("[COV] TageBTable.resp_valid < 20"); end
    $display("[COV] TageBTable.update_any = %0d", p_cov_update_any);
    if (p_cov_update_any < 20) begin cov_fail++; $display("[COV] TageBTable.update_any < 20"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
