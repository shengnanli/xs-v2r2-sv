// 生成 SCTable 家族（SCTable / _1 / _2 / _3）的双例化 UT testbench（tb.sv）。
//
// 四对 golden <V> vs 重写 <V>_xs 同 tb 并跑（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比全部输出。
// 子模块：golden 侧接 golden SRAMTemplate_68 / WrBypass_33 / MbistPipeSc_N，重写侧接本仓重写件（均已签核）；
// 两侧共读同一份厂商 SRAM 宏链（sram_array_1p128x24m6s1h0l1b_bp_sc -> array_5 -> array_5_ext.v）。
//
// 激励要点（判别力来自哪里）：
//   · 读 pc 与更新 pc 从同一个 24 项小池子取（池子里各项的 pc[8:1] 互不相同但只差几位），
//     ghist / 折叠历史也从 4 项小池取 —— 同一行反复被读、被连续更新，写旁路（16 项）经常命中；
//   · update.mask 各 1/2 概率，tagePreds / takens 随机，oldCtrs 一半取饱和边界（+31 / -32 / ±0 附近），
//     一半随机 —— 饱和 ±1 的四条分支都走到；
//   · 读写同拍同 bank（冲突清零）自然高频发生；
//   · MBIST 测试口与 SRAM 广播控制位平时钉 0（否则 SRAM 一直被测试口占着），mode>=13 的阶段（3/16）全随机。
// 比较窗口：SRAM 读出保持寄存器与 s1_* 寄存器不复位 —— 等 golden 两个 bank 各完成过一次读（ren）再开比。
// 覆盖（golden 内部语义信号）：冲突清零、写旁路命中且该路有效、饱和 +31/-32 停住、两个 bank 都被写过。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= SCTable =================
  int unsigned s0_mode = 0;
  logic [49:0] s0_pc_pool [24];
  logic [255:0] s0_gh_pool [4];
  initial begin
    for (int k = 0; k < 24; k++) s0_pc_pool[k] = {$urandom, $urandom} ^ (50'(k) << 1);
    for (int k = 0; k < 4; k++) s0_gh_pool[k] = {8{$urandom}};
  end
  function automatic logic [5:0] s0_pick_ctr();
    case ($urandom_range(0, 7))
      0: return 6'h1F; 1: return 6'h20; 2: return 6'h1E; 3: return 6'h21; 4: return 6'h00; 5: return 6'h3F;
      default: return 6'($urandom);
    endcase
  endfunction
  logic s0_reset;
  logic s0_io_req_valid;
  logic [49:0] s0_io_req_bits_pc;
  wire  [5:0] s0_g_io_resp_ctrs_0_0, s0_i_io_resp_ctrs_0_0;
  logic [5:0] s0_s0_io_resp_ctrs_0_0 = '0, s0_s1_io_resp_ctrs_0_0 = '0;
  wire  [5:0] s0_g_io_resp_ctrs_0_1, s0_i_io_resp_ctrs_0_1;
  logic [5:0] s0_s0_io_resp_ctrs_0_1 = '0, s0_s1_io_resp_ctrs_0_1 = '0;
  wire  [5:0] s0_g_io_resp_ctrs_1_0, s0_i_io_resp_ctrs_1_0;
  logic [5:0] s0_s0_io_resp_ctrs_1_0 = '0, s0_s1_io_resp_ctrs_1_0 = '0;
  wire  [5:0] s0_g_io_resp_ctrs_1_1, s0_i_io_resp_ctrs_1_1;
  logic [5:0] s0_s0_io_resp_ctrs_1_1 = '0, s0_s1_io_resp_ctrs_1_1 = '0;
  logic [49:0] s0_io_update_pc;
  logic s0_io_update_mask_0;
  logic s0_io_update_mask_1;
  logic [5:0] s0_io_update_oldCtrs_0;
  logic [5:0] s0_io_update_oldCtrs_1;
  logic s0_io_update_tagePreds_0;
  logic s0_io_update_tagePreds_1;
  logic s0_io_update_takens_0;
  logic s0_io_update_takens_1;
  logic [6:0] s0_boreChildrenBd_bore_array;
  logic s0_boreChildrenBd_bore_all;
  logic s0_boreChildrenBd_bore_req;
  wire  s0_g_boreChildrenBd_bore_ack, s0_i_boreChildrenBd_bore_ack;
  logic s0_s0_boreChildrenBd_bore_ack = '0, s0_s1_boreChildrenBd_bore_ack = '0;
  logic s0_boreChildrenBd_bore_writeen;
  logic [3:0] s0_boreChildrenBd_bore_be;
  logic [7:0] s0_boreChildrenBd_bore_addr;
  logic [23:0] s0_boreChildrenBd_bore_indata;
  logic s0_boreChildrenBd_bore_readen;
  logic [7:0] s0_boreChildrenBd_bore_addr_rd;
  wire  [23:0] s0_g_boreChildrenBd_bore_outdata, s0_i_boreChildrenBd_bore_outdata;
  logic [23:0] s0_s0_boreChildrenBd_bore_outdata = '0, s0_s1_boreChildrenBd_bore_outdata = '0;
  logic s0_sigFromSrams_bore_ram_hold;
  logic s0_sigFromSrams_bore_ram_bypass;
  logic s0_sigFromSrams_bore_ram_bp_clken;
  logic s0_sigFromSrams_bore_ram_aux_clk;
  logic s0_sigFromSrams_bore_ram_aux_ckbp;
  logic s0_sigFromSrams_bore_ram_mcp_hold;
  logic s0_sigFromSrams_bore_cgen;
  logic s0_sigFromSrams_bore_1_ram_hold;
  logic s0_sigFromSrams_bore_1_ram_bypass;
  logic s0_sigFromSrams_bore_1_ram_bp_clken;
  logic s0_sigFromSrams_bore_1_ram_aux_clk;
  logic s0_sigFromSrams_bore_1_ram_aux_ckbp;
  logic s0_sigFromSrams_bore_1_ram_mcp_hold;
  logic s0_sigFromSrams_bore_1_cgen;
  int s0_cov_conflict_zeroed = 0;
  int s0_cov_bypass_hit_valid_br0 = 0;
  int s0_cov_bypass_hit_valid_br1 = 0;
  int s0_cov_sat_pos_hold = 0;
  int s0_cov_sat_neg_hold = 0;
  int s0_cov_bank0_write = 0;
  int s0_cov_bank1_write = 0;
  logic [1:0] s0_armed = '0;
  int s0_armed_at = -1;
  SCTable s0_u_gold (
    .clock(clk),
    .reset(s0_reset),
    .io_req_valid(s0_io_req_valid),
    .io_req_bits_pc(s0_io_req_bits_pc),
    .io_resp_ctrs_0_0(s0_g_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s0_g_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s0_g_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s0_g_io_resp_ctrs_1_1),
    .io_update_pc(s0_io_update_pc),
    .io_update_mask_0(s0_io_update_mask_0),
    .io_update_mask_1(s0_io_update_mask_1),
    .io_update_oldCtrs_0(s0_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s0_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s0_io_update_tagePreds_0),
    .io_update_tagePreds_1(s0_io_update_tagePreds_1),
    .io_update_takens_0(s0_io_update_takens_0),
    .io_update_takens_1(s0_io_update_takens_1),
    .boreChildrenBd_bore_array(s0_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s0_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s0_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s0_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s0_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s0_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s0_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s0_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s0_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s0_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s0_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s0_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s0_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s0_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s0_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s0_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s0_sigFromSrams_bore_1_cgen)
  );
  SCTable_xs s0_u_impl (
    .clock(clk),
    .reset(s0_reset),
    .io_req_valid(s0_io_req_valid),
    .io_req_bits_pc(s0_io_req_bits_pc),
    .io_resp_ctrs_0_0(s0_i_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s0_i_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s0_i_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s0_i_io_resp_ctrs_1_1),
    .io_update_pc(s0_io_update_pc),
    .io_update_mask_0(s0_io_update_mask_0),
    .io_update_mask_1(s0_io_update_mask_1),
    .io_update_oldCtrs_0(s0_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s0_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s0_io_update_tagePreds_0),
    .io_update_tagePreds_1(s0_io_update_tagePreds_1),
    .io_update_takens_0(s0_io_update_takens_0),
    .io_update_takens_1(s0_io_update_takens_1),
    .boreChildrenBd_bore_array(s0_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s0_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s0_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s0_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s0_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s0_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s0_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s0_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s0_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s0_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s0_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s0_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s0_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s0_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s0_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s0_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s0_sigFromSrams_bore_1_cgen)
  );

  // ================= SCTable_1 =================
  int unsigned s1_mode = 0;
  logic [49:0] s1_pc_pool [24];
  logic [255:0] s1_gh_pool [4];
  initial begin
    for (int k = 0; k < 24; k++) s1_pc_pool[k] = {$urandom, $urandom} ^ (50'(k) << 1);
    for (int k = 0; k < 4; k++) s1_gh_pool[k] = {8{$urandom}};
  end
  function automatic logic [5:0] s1_pick_ctr();
    case ($urandom_range(0, 7))
      0: return 6'h1F; 1: return 6'h20; 2: return 6'h1E; 3: return 6'h21; 4: return 6'h00; 5: return 6'h3F;
      default: return 6'($urandom);
    endcase
  endfunction
  logic s1_reset;
  logic s1_io_req_valid;
  logic [49:0] s1_io_req_bits_pc;
  logic [3:0] s1_io_req_bits_folded_hist_hist_12_folded_hist;
  wire  [5:0] s1_g_io_resp_ctrs_0_0, s1_i_io_resp_ctrs_0_0;
  logic [5:0] s1_s0_io_resp_ctrs_0_0 = '0, s1_s1_io_resp_ctrs_0_0 = '0;
  wire  [5:0] s1_g_io_resp_ctrs_0_1, s1_i_io_resp_ctrs_0_1;
  logic [5:0] s1_s0_io_resp_ctrs_0_1 = '0, s1_s1_io_resp_ctrs_0_1 = '0;
  wire  [5:0] s1_g_io_resp_ctrs_1_0, s1_i_io_resp_ctrs_1_0;
  logic [5:0] s1_s0_io_resp_ctrs_1_0 = '0, s1_s1_io_resp_ctrs_1_0 = '0;
  wire  [5:0] s1_g_io_resp_ctrs_1_1, s1_i_io_resp_ctrs_1_1;
  logic [5:0] s1_s0_io_resp_ctrs_1_1 = '0, s1_s1_io_resp_ctrs_1_1 = '0;
  logic [49:0] s1_io_update_pc;
  logic [255:0] s1_io_update_ghist;
  logic s1_io_update_mask_0;
  logic s1_io_update_mask_1;
  logic [5:0] s1_io_update_oldCtrs_0;
  logic [5:0] s1_io_update_oldCtrs_1;
  logic s1_io_update_tagePreds_0;
  logic s1_io_update_tagePreds_1;
  logic s1_io_update_takens_0;
  logic s1_io_update_takens_1;
  logic [6:0] s1_boreChildrenBd_bore_array;
  logic s1_boreChildrenBd_bore_all;
  logic s1_boreChildrenBd_bore_req;
  wire  s1_g_boreChildrenBd_bore_ack, s1_i_boreChildrenBd_bore_ack;
  logic s1_s0_boreChildrenBd_bore_ack = '0, s1_s1_boreChildrenBd_bore_ack = '0;
  logic s1_boreChildrenBd_bore_writeen;
  logic [3:0] s1_boreChildrenBd_bore_be;
  logic [7:0] s1_boreChildrenBd_bore_addr;
  logic [23:0] s1_boreChildrenBd_bore_indata;
  logic s1_boreChildrenBd_bore_readen;
  logic [7:0] s1_boreChildrenBd_bore_addr_rd;
  wire  [23:0] s1_g_boreChildrenBd_bore_outdata, s1_i_boreChildrenBd_bore_outdata;
  logic [23:0] s1_s0_boreChildrenBd_bore_outdata = '0, s1_s1_boreChildrenBd_bore_outdata = '0;
  logic s1_sigFromSrams_bore_ram_hold;
  logic s1_sigFromSrams_bore_ram_bypass;
  logic s1_sigFromSrams_bore_ram_bp_clken;
  logic s1_sigFromSrams_bore_ram_aux_clk;
  logic s1_sigFromSrams_bore_ram_aux_ckbp;
  logic s1_sigFromSrams_bore_ram_mcp_hold;
  logic s1_sigFromSrams_bore_cgen;
  logic s1_sigFromSrams_bore_1_ram_hold;
  logic s1_sigFromSrams_bore_1_ram_bypass;
  logic s1_sigFromSrams_bore_1_ram_bp_clken;
  logic s1_sigFromSrams_bore_1_ram_aux_clk;
  logic s1_sigFromSrams_bore_1_ram_aux_ckbp;
  logic s1_sigFromSrams_bore_1_ram_mcp_hold;
  logic s1_sigFromSrams_bore_1_cgen;
  int s1_cov_conflict_zeroed = 0;
  int s1_cov_bypass_hit_valid_br0 = 0;
  int s1_cov_bypass_hit_valid_br1 = 0;
  int s1_cov_sat_pos_hold = 0;
  int s1_cov_sat_neg_hold = 0;
  int s1_cov_bank0_write = 0;
  int s1_cov_bank1_write = 0;
  logic [1:0] s1_armed = '0;
  int s1_armed_at = -1;
  SCTable_1 s1_u_gold (
    .clock(clk),
    .reset(s1_reset),
    .io_req_valid(s1_io_req_valid),
    .io_req_bits_pc(s1_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_12_folded_hist(s1_io_req_bits_folded_hist_hist_12_folded_hist),
    .io_resp_ctrs_0_0(s1_g_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s1_g_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s1_g_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s1_g_io_resp_ctrs_1_1),
    .io_update_pc(s1_io_update_pc),
    .io_update_ghist(s1_io_update_ghist),
    .io_update_mask_0(s1_io_update_mask_0),
    .io_update_mask_1(s1_io_update_mask_1),
    .io_update_oldCtrs_0(s1_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s1_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s1_io_update_tagePreds_0),
    .io_update_tagePreds_1(s1_io_update_tagePreds_1),
    .io_update_takens_0(s1_io_update_takens_0),
    .io_update_takens_1(s1_io_update_takens_1),
    .boreChildrenBd_bore_array(s1_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s1_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s1_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s1_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s1_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s1_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s1_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s1_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s1_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s1_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s1_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s1_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s1_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s1_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s1_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s1_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s1_sigFromSrams_bore_1_cgen)
  );
  SCTable_1_xs s1_u_impl (
    .clock(clk),
    .reset(s1_reset),
    .io_req_valid(s1_io_req_valid),
    .io_req_bits_pc(s1_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_12_folded_hist(s1_io_req_bits_folded_hist_hist_12_folded_hist),
    .io_resp_ctrs_0_0(s1_i_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s1_i_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s1_i_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s1_i_io_resp_ctrs_1_1),
    .io_update_pc(s1_io_update_pc),
    .io_update_ghist(s1_io_update_ghist),
    .io_update_mask_0(s1_io_update_mask_0),
    .io_update_mask_1(s1_io_update_mask_1),
    .io_update_oldCtrs_0(s1_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s1_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s1_io_update_tagePreds_0),
    .io_update_tagePreds_1(s1_io_update_tagePreds_1),
    .io_update_takens_0(s1_io_update_takens_0),
    .io_update_takens_1(s1_io_update_takens_1),
    .boreChildrenBd_bore_array(s1_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s1_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s1_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s1_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s1_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s1_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s1_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s1_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s1_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s1_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s1_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s1_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s1_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s1_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s1_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s1_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s1_sigFromSrams_bore_1_cgen)
  );

  // ================= SCTable_2 =================
  int unsigned s2_mode = 0;
  logic [49:0] s2_pc_pool [24];
  logic [255:0] s2_gh_pool [4];
  initial begin
    for (int k = 0; k < 24; k++) s2_pc_pool[k] = {$urandom, $urandom} ^ (50'(k) << 1);
    for (int k = 0; k < 4; k++) s2_gh_pool[k] = {8{$urandom}};
  end
  function automatic logic [5:0] s2_pick_ctr();
    case ($urandom_range(0, 7))
      0: return 6'h1F; 1: return 6'h20; 2: return 6'h1E; 3: return 6'h21; 4: return 6'h00; 5: return 6'h3F;
      default: return 6'($urandom);
    endcase
  endfunction
  logic s2_reset;
  logic s2_io_req_valid;
  logic [49:0] s2_io_req_bits_pc;
  logic [7:0] s2_io_req_bits_folded_hist_hist_11_folded_hist;
  wire  [5:0] s2_g_io_resp_ctrs_0_0, s2_i_io_resp_ctrs_0_0;
  logic [5:0] s2_s0_io_resp_ctrs_0_0 = '0, s2_s1_io_resp_ctrs_0_0 = '0;
  wire  [5:0] s2_g_io_resp_ctrs_0_1, s2_i_io_resp_ctrs_0_1;
  logic [5:0] s2_s0_io_resp_ctrs_0_1 = '0, s2_s1_io_resp_ctrs_0_1 = '0;
  wire  [5:0] s2_g_io_resp_ctrs_1_0, s2_i_io_resp_ctrs_1_0;
  logic [5:0] s2_s0_io_resp_ctrs_1_0 = '0, s2_s1_io_resp_ctrs_1_0 = '0;
  wire  [5:0] s2_g_io_resp_ctrs_1_1, s2_i_io_resp_ctrs_1_1;
  logic [5:0] s2_s0_io_resp_ctrs_1_1 = '0, s2_s1_io_resp_ctrs_1_1 = '0;
  logic [49:0] s2_io_update_pc;
  logic [255:0] s2_io_update_ghist;
  logic s2_io_update_mask_0;
  logic s2_io_update_mask_1;
  logic [5:0] s2_io_update_oldCtrs_0;
  logic [5:0] s2_io_update_oldCtrs_1;
  logic s2_io_update_tagePreds_0;
  logic s2_io_update_tagePreds_1;
  logic s2_io_update_takens_0;
  logic s2_io_update_takens_1;
  logic [6:0] s2_boreChildrenBd_bore_array;
  logic s2_boreChildrenBd_bore_all;
  logic s2_boreChildrenBd_bore_req;
  wire  s2_g_boreChildrenBd_bore_ack, s2_i_boreChildrenBd_bore_ack;
  logic s2_s0_boreChildrenBd_bore_ack = '0, s2_s1_boreChildrenBd_bore_ack = '0;
  logic s2_boreChildrenBd_bore_writeen;
  logic [3:0] s2_boreChildrenBd_bore_be;
  logic [7:0] s2_boreChildrenBd_bore_addr;
  logic [23:0] s2_boreChildrenBd_bore_indata;
  logic s2_boreChildrenBd_bore_readen;
  logic [7:0] s2_boreChildrenBd_bore_addr_rd;
  wire  [23:0] s2_g_boreChildrenBd_bore_outdata, s2_i_boreChildrenBd_bore_outdata;
  logic [23:0] s2_s0_boreChildrenBd_bore_outdata = '0, s2_s1_boreChildrenBd_bore_outdata = '0;
  logic s2_sigFromSrams_bore_ram_hold;
  logic s2_sigFromSrams_bore_ram_bypass;
  logic s2_sigFromSrams_bore_ram_bp_clken;
  logic s2_sigFromSrams_bore_ram_aux_clk;
  logic s2_sigFromSrams_bore_ram_aux_ckbp;
  logic s2_sigFromSrams_bore_ram_mcp_hold;
  logic s2_sigFromSrams_bore_cgen;
  logic s2_sigFromSrams_bore_1_ram_hold;
  logic s2_sigFromSrams_bore_1_ram_bypass;
  logic s2_sigFromSrams_bore_1_ram_bp_clken;
  logic s2_sigFromSrams_bore_1_ram_aux_clk;
  logic s2_sigFromSrams_bore_1_ram_aux_ckbp;
  logic s2_sigFromSrams_bore_1_ram_mcp_hold;
  logic s2_sigFromSrams_bore_1_cgen;
  int s2_cov_conflict_zeroed = 0;
  int s2_cov_bypass_hit_valid_br0 = 0;
  int s2_cov_bypass_hit_valid_br1 = 0;
  int s2_cov_sat_pos_hold = 0;
  int s2_cov_sat_neg_hold = 0;
  int s2_cov_bank0_write = 0;
  int s2_cov_bank1_write = 0;
  logic [1:0] s2_armed = '0;
  int s2_armed_at = -1;
  SCTable_2 s2_u_gold (
    .clock(clk),
    .reset(s2_reset),
    .io_req_valid(s2_io_req_valid),
    .io_req_bits_pc(s2_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_11_folded_hist(s2_io_req_bits_folded_hist_hist_11_folded_hist),
    .io_resp_ctrs_0_0(s2_g_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s2_g_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s2_g_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s2_g_io_resp_ctrs_1_1),
    .io_update_pc(s2_io_update_pc),
    .io_update_ghist(s2_io_update_ghist),
    .io_update_mask_0(s2_io_update_mask_0),
    .io_update_mask_1(s2_io_update_mask_1),
    .io_update_oldCtrs_0(s2_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s2_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s2_io_update_tagePreds_0),
    .io_update_tagePreds_1(s2_io_update_tagePreds_1),
    .io_update_takens_0(s2_io_update_takens_0),
    .io_update_takens_1(s2_io_update_takens_1),
    .boreChildrenBd_bore_array(s2_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s2_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s2_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s2_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s2_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s2_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s2_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s2_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s2_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s2_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s2_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s2_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s2_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s2_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s2_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s2_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s2_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s2_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s2_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s2_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s2_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s2_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s2_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s2_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s2_sigFromSrams_bore_1_cgen)
  );
  SCTable_2_xs s2_u_impl (
    .clock(clk),
    .reset(s2_reset),
    .io_req_valid(s2_io_req_valid),
    .io_req_bits_pc(s2_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_11_folded_hist(s2_io_req_bits_folded_hist_hist_11_folded_hist),
    .io_resp_ctrs_0_0(s2_i_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s2_i_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s2_i_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s2_i_io_resp_ctrs_1_1),
    .io_update_pc(s2_io_update_pc),
    .io_update_ghist(s2_io_update_ghist),
    .io_update_mask_0(s2_io_update_mask_0),
    .io_update_mask_1(s2_io_update_mask_1),
    .io_update_oldCtrs_0(s2_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s2_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s2_io_update_tagePreds_0),
    .io_update_tagePreds_1(s2_io_update_tagePreds_1),
    .io_update_takens_0(s2_io_update_takens_0),
    .io_update_takens_1(s2_io_update_takens_1),
    .boreChildrenBd_bore_array(s2_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s2_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s2_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s2_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s2_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s2_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s2_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s2_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s2_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s2_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s2_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s2_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s2_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s2_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s2_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s2_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s2_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s2_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s2_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s2_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s2_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s2_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s2_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s2_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s2_sigFromSrams_bore_1_cgen)
  );

  // ================= SCTable_3 =================
  int unsigned s3_mode = 0;
  logic [49:0] s3_pc_pool [24];
  logic [255:0] s3_gh_pool [4];
  initial begin
    for (int k = 0; k < 24; k++) s3_pc_pool[k] = {$urandom, $urandom} ^ (50'(k) << 1);
    for (int k = 0; k < 4; k++) s3_gh_pool[k] = {8{$urandom}};
  end
  function automatic logic [5:0] s3_pick_ctr();
    case ($urandom_range(0, 7))
      0: return 6'h1F; 1: return 6'h20; 2: return 6'h1E; 3: return 6'h21; 4: return 6'h00; 5: return 6'h3F;
      default: return 6'($urandom);
    endcase
  endfunction
  logic s3_reset;
  logic s3_io_req_valid;
  logic [49:0] s3_io_req_bits_pc;
  logic [7:0] s3_io_req_bits_folded_hist_hist_2_folded_hist;
  wire  [5:0] s3_g_io_resp_ctrs_0_0, s3_i_io_resp_ctrs_0_0;
  logic [5:0] s3_s0_io_resp_ctrs_0_0 = '0, s3_s1_io_resp_ctrs_0_0 = '0;
  wire  [5:0] s3_g_io_resp_ctrs_0_1, s3_i_io_resp_ctrs_0_1;
  logic [5:0] s3_s0_io_resp_ctrs_0_1 = '0, s3_s1_io_resp_ctrs_0_1 = '0;
  wire  [5:0] s3_g_io_resp_ctrs_1_0, s3_i_io_resp_ctrs_1_0;
  logic [5:0] s3_s0_io_resp_ctrs_1_0 = '0, s3_s1_io_resp_ctrs_1_0 = '0;
  wire  [5:0] s3_g_io_resp_ctrs_1_1, s3_i_io_resp_ctrs_1_1;
  logic [5:0] s3_s0_io_resp_ctrs_1_1 = '0, s3_s1_io_resp_ctrs_1_1 = '0;
  logic [49:0] s3_io_update_pc;
  logic [255:0] s3_io_update_ghist;
  logic s3_io_update_mask_0;
  logic s3_io_update_mask_1;
  logic [5:0] s3_io_update_oldCtrs_0;
  logic [5:0] s3_io_update_oldCtrs_1;
  logic s3_io_update_tagePreds_0;
  logic s3_io_update_tagePreds_1;
  logic s3_io_update_takens_0;
  logic s3_io_update_takens_1;
  logic [6:0] s3_boreChildrenBd_bore_array;
  logic s3_boreChildrenBd_bore_all;
  logic s3_boreChildrenBd_bore_req;
  wire  s3_g_boreChildrenBd_bore_ack, s3_i_boreChildrenBd_bore_ack;
  logic s3_s0_boreChildrenBd_bore_ack = '0, s3_s1_boreChildrenBd_bore_ack = '0;
  logic s3_boreChildrenBd_bore_writeen;
  logic [3:0] s3_boreChildrenBd_bore_be;
  logic [7:0] s3_boreChildrenBd_bore_addr;
  logic [23:0] s3_boreChildrenBd_bore_indata;
  logic s3_boreChildrenBd_bore_readen;
  logic [7:0] s3_boreChildrenBd_bore_addr_rd;
  wire  [23:0] s3_g_boreChildrenBd_bore_outdata, s3_i_boreChildrenBd_bore_outdata;
  logic [23:0] s3_s0_boreChildrenBd_bore_outdata = '0, s3_s1_boreChildrenBd_bore_outdata = '0;
  logic s3_sigFromSrams_bore_ram_hold;
  logic s3_sigFromSrams_bore_ram_bypass;
  logic s3_sigFromSrams_bore_ram_bp_clken;
  logic s3_sigFromSrams_bore_ram_aux_clk;
  logic s3_sigFromSrams_bore_ram_aux_ckbp;
  logic s3_sigFromSrams_bore_ram_mcp_hold;
  logic s3_sigFromSrams_bore_cgen;
  logic s3_sigFromSrams_bore_1_ram_hold;
  logic s3_sigFromSrams_bore_1_ram_bypass;
  logic s3_sigFromSrams_bore_1_ram_bp_clken;
  logic s3_sigFromSrams_bore_1_ram_aux_clk;
  logic s3_sigFromSrams_bore_1_ram_aux_ckbp;
  logic s3_sigFromSrams_bore_1_ram_mcp_hold;
  logic s3_sigFromSrams_bore_1_cgen;
  int s3_cov_conflict_zeroed = 0;
  int s3_cov_bypass_hit_valid_br0 = 0;
  int s3_cov_bypass_hit_valid_br1 = 0;
  int s3_cov_sat_pos_hold = 0;
  int s3_cov_sat_neg_hold = 0;
  int s3_cov_bank0_write = 0;
  int s3_cov_bank1_write = 0;
  logic [1:0] s3_armed = '0;
  int s3_armed_at = -1;
  SCTable_3 s3_u_gold (
    .clock(clk),
    .reset(s3_reset),
    .io_req_valid(s3_io_req_valid),
    .io_req_bits_pc(s3_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_2_folded_hist(s3_io_req_bits_folded_hist_hist_2_folded_hist),
    .io_resp_ctrs_0_0(s3_g_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s3_g_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s3_g_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s3_g_io_resp_ctrs_1_1),
    .io_update_pc(s3_io_update_pc),
    .io_update_ghist(s3_io_update_ghist),
    .io_update_mask_0(s3_io_update_mask_0),
    .io_update_mask_1(s3_io_update_mask_1),
    .io_update_oldCtrs_0(s3_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s3_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s3_io_update_tagePreds_0),
    .io_update_tagePreds_1(s3_io_update_tagePreds_1),
    .io_update_takens_0(s3_io_update_takens_0),
    .io_update_takens_1(s3_io_update_takens_1),
    .boreChildrenBd_bore_array(s3_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s3_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s3_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s3_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s3_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s3_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s3_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s3_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s3_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s3_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s3_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s3_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s3_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s3_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s3_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s3_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s3_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s3_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s3_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s3_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s3_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s3_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s3_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s3_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s3_sigFromSrams_bore_1_cgen)
  );
  SCTable_3_xs s3_u_impl (
    .clock(clk),
    .reset(s3_reset),
    .io_req_valid(s3_io_req_valid),
    .io_req_bits_pc(s3_io_req_bits_pc),
    .io_req_bits_folded_hist_hist_2_folded_hist(s3_io_req_bits_folded_hist_hist_2_folded_hist),
    .io_resp_ctrs_0_0(s3_i_io_resp_ctrs_0_0),
    .io_resp_ctrs_0_1(s3_i_io_resp_ctrs_0_1),
    .io_resp_ctrs_1_0(s3_i_io_resp_ctrs_1_0),
    .io_resp_ctrs_1_1(s3_i_io_resp_ctrs_1_1),
    .io_update_pc(s3_io_update_pc),
    .io_update_ghist(s3_io_update_ghist),
    .io_update_mask_0(s3_io_update_mask_0),
    .io_update_mask_1(s3_io_update_mask_1),
    .io_update_oldCtrs_0(s3_io_update_oldCtrs_0),
    .io_update_oldCtrs_1(s3_io_update_oldCtrs_1),
    .io_update_tagePreds_0(s3_io_update_tagePreds_0),
    .io_update_tagePreds_1(s3_io_update_tagePreds_1),
    .io_update_takens_0(s3_io_update_takens_0),
    .io_update_takens_1(s3_io_update_takens_1),
    .boreChildrenBd_bore_array(s3_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(s3_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(s3_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(s3_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(s3_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(s3_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(s3_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(s3_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(s3_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(s3_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(s3_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(s3_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s3_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s3_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s3_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s3_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s3_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s3_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s3_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s3_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s3_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s3_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s3_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s3_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s3_sigFromSrams_bore_1_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) s0_mode = $urandom_range(0, 15);
      s0_io_req_valid = 1'($urandom);
      s0_io_req_bits_pc = 50'({$urandom, $urandom});
      s0_io_update_pc = 50'({$urandom, $urandom});
      s0_io_update_mask_0 = 1'($urandom);
      s0_io_update_mask_1 = 1'($urandom);
      s0_io_update_oldCtrs_0 = 6'($urandom);
      s0_io_update_oldCtrs_1 = 6'($urandom);
      s0_io_update_tagePreds_0 = 1'($urandom);
      s0_io_update_tagePreds_1 = 1'($urandom);
      s0_io_update_takens_0 = 1'($urandom);
      s0_io_update_takens_1 = 1'($urandom);
      s0_boreChildrenBd_bore_array = 7'($urandom);
      s0_boreChildrenBd_bore_all = 1'($urandom);
      s0_boreChildrenBd_bore_req = 1'($urandom);
      s0_boreChildrenBd_bore_writeen = 1'($urandom);
      s0_boreChildrenBd_bore_be = 4'($urandom);
      s0_boreChildrenBd_bore_addr = 8'($urandom);
      s0_boreChildrenBd_bore_indata = 24'($urandom);
      s0_boreChildrenBd_bore_readen = 1'($urandom);
      s0_boreChildrenBd_bore_addr_rd = 8'($urandom);
      s0_sigFromSrams_bore_ram_hold = 1'($urandom);
      s0_sigFromSrams_bore_ram_bypass = 1'($urandom);
      s0_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      s0_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      s0_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      s0_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      s0_sigFromSrams_bore_cgen = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      s0_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      s0_sigFromSrams_bore_1_cgen = 1'($urandom);
      s0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_s0
        s0_io_req_bits_pc = s0_pc_pool[$urandom_range(0, 23)];
        s0_io_update_pc = s0_pc_pool[$urandom_range(0, 23)];
        s0_io_update_oldCtrs_0 = s0_pick_ctr();
        s0_io_update_oldCtrs_1 = s0_pick_ctr();
        
        if (s0_mode < 13) begin
          s0_boreChildrenBd_bore_req = 1'b0; s0_boreChildrenBd_bore_all = 1'b0;
          s0_boreChildrenBd_bore_array = 7'h0; s0_boreChildrenBd_bore_writeen = 1'b0; s0_boreChildrenBd_bore_readen = 1'b0;
          s0_sigFromSrams_bore_ram_hold = 1'b0; s0_sigFromSrams_bore_ram_bypass = 1'b0; s0_sigFromSrams_bore_ram_bp_clken = 1'b0;
          s0_sigFromSrams_bore_ram_aux_clk = 1'b0; s0_sigFromSrams_bore_ram_aux_ckbp = 1'b0; s0_sigFromSrams_bore_ram_mcp_hold = 1'b0;
          s0_sigFromSrams_bore_cgen = 1'b0;
          s0_sigFromSrams_bore_1_ram_hold = 1'b0; s0_sigFromSrams_bore_1_ram_bypass = 1'b0; s0_sigFromSrams_bore_1_ram_bp_clken = 1'b0;
          s0_sigFromSrams_bore_1_ram_aux_clk = 1'b0; s0_sigFromSrams_bore_1_ram_aux_ckbp = 1'b0; s0_sigFromSrams_bore_1_ram_mcp_hold = 1'b0;
          s0_sigFromSrams_bore_1_cgen = 1'b0;
        end
      end
      if (cyc % 2000 == 0) s1_mode = $urandom_range(0, 15);
      s1_io_req_valid = 1'($urandom);
      s1_io_req_bits_pc = 50'({$urandom, $urandom});
      s1_io_req_bits_folded_hist_hist_12_folded_hist = 4'($urandom);
      s1_io_update_pc = 50'({$urandom, $urandom});
      s1_io_update_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      s1_io_update_mask_0 = 1'($urandom);
      s1_io_update_mask_1 = 1'($urandom);
      s1_io_update_oldCtrs_0 = 6'($urandom);
      s1_io_update_oldCtrs_1 = 6'($urandom);
      s1_io_update_tagePreds_0 = 1'($urandom);
      s1_io_update_tagePreds_1 = 1'($urandom);
      s1_io_update_takens_0 = 1'($urandom);
      s1_io_update_takens_1 = 1'($urandom);
      s1_boreChildrenBd_bore_array = 7'($urandom);
      s1_boreChildrenBd_bore_all = 1'($urandom);
      s1_boreChildrenBd_bore_req = 1'($urandom);
      s1_boreChildrenBd_bore_writeen = 1'($urandom);
      s1_boreChildrenBd_bore_be = 4'($urandom);
      s1_boreChildrenBd_bore_addr = 8'($urandom);
      s1_boreChildrenBd_bore_indata = 24'($urandom);
      s1_boreChildrenBd_bore_readen = 1'($urandom);
      s1_boreChildrenBd_bore_addr_rd = 8'($urandom);
      s1_sigFromSrams_bore_ram_hold = 1'($urandom);
      s1_sigFromSrams_bore_ram_bypass = 1'($urandom);
      s1_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      s1_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      s1_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      s1_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      s1_sigFromSrams_bore_cgen = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      s1_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      s1_sigFromSrams_bore_1_cgen = 1'($urandom);
      s1_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_s1
        s1_io_req_bits_pc = s1_pc_pool[$urandom_range(0, 23)];
        s1_io_update_pc = s1_pc_pool[$urandom_range(0, 23)];
        s1_io_update_oldCtrs_0 = s1_pick_ctr();
        s1_io_update_oldCtrs_1 = s1_pick_ctr();
        s1_io_req_bits_folded_hist_hist_12_folded_hist = s1_gh_pool[$urandom_range(0, 3)][7:0] ^ 8'($urandom_range(0, 1));
        s1_io_update_ghist = s1_gh_pool[$urandom_range(0, 3)];
        if (s1_mode < 13) begin
          s1_boreChildrenBd_bore_req = 1'b0; s1_boreChildrenBd_bore_all = 1'b0;
          s1_boreChildrenBd_bore_array = 7'h0; s1_boreChildrenBd_bore_writeen = 1'b0; s1_boreChildrenBd_bore_readen = 1'b0;
          s1_sigFromSrams_bore_ram_hold = 1'b0; s1_sigFromSrams_bore_ram_bypass = 1'b0; s1_sigFromSrams_bore_ram_bp_clken = 1'b0;
          s1_sigFromSrams_bore_ram_aux_clk = 1'b0; s1_sigFromSrams_bore_ram_aux_ckbp = 1'b0; s1_sigFromSrams_bore_ram_mcp_hold = 1'b0;
          s1_sigFromSrams_bore_cgen = 1'b0;
          s1_sigFromSrams_bore_1_ram_hold = 1'b0; s1_sigFromSrams_bore_1_ram_bypass = 1'b0; s1_sigFromSrams_bore_1_ram_bp_clken = 1'b0;
          s1_sigFromSrams_bore_1_ram_aux_clk = 1'b0; s1_sigFromSrams_bore_1_ram_aux_ckbp = 1'b0; s1_sigFromSrams_bore_1_ram_mcp_hold = 1'b0;
          s1_sigFromSrams_bore_1_cgen = 1'b0;
        end
      end
      if (cyc % 2000 == 0) s2_mode = $urandom_range(0, 15);
      s2_io_req_valid = 1'($urandom);
      s2_io_req_bits_pc = 50'({$urandom, $urandom});
      s2_io_req_bits_folded_hist_hist_11_folded_hist = 8'($urandom);
      s2_io_update_pc = 50'({$urandom, $urandom});
      s2_io_update_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      s2_io_update_mask_0 = 1'($urandom);
      s2_io_update_mask_1 = 1'($urandom);
      s2_io_update_oldCtrs_0 = 6'($urandom);
      s2_io_update_oldCtrs_1 = 6'($urandom);
      s2_io_update_tagePreds_0 = 1'($urandom);
      s2_io_update_tagePreds_1 = 1'($urandom);
      s2_io_update_takens_0 = 1'($urandom);
      s2_io_update_takens_1 = 1'($urandom);
      s2_boreChildrenBd_bore_array = 7'($urandom);
      s2_boreChildrenBd_bore_all = 1'($urandom);
      s2_boreChildrenBd_bore_req = 1'($urandom);
      s2_boreChildrenBd_bore_writeen = 1'($urandom);
      s2_boreChildrenBd_bore_be = 4'($urandom);
      s2_boreChildrenBd_bore_addr = 8'($urandom);
      s2_boreChildrenBd_bore_indata = 24'($urandom);
      s2_boreChildrenBd_bore_readen = 1'($urandom);
      s2_boreChildrenBd_bore_addr_rd = 8'($urandom);
      s2_sigFromSrams_bore_ram_hold = 1'($urandom);
      s2_sigFromSrams_bore_ram_bypass = 1'($urandom);
      s2_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      s2_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      s2_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      s2_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      s2_sigFromSrams_bore_cgen = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      s2_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      s2_sigFromSrams_bore_1_cgen = 1'($urandom);
      s2_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_s2
        s2_io_req_bits_pc = s2_pc_pool[$urandom_range(0, 23)];
        s2_io_update_pc = s2_pc_pool[$urandom_range(0, 23)];
        s2_io_update_oldCtrs_0 = s2_pick_ctr();
        s2_io_update_oldCtrs_1 = s2_pick_ctr();
        s2_io_req_bits_folded_hist_hist_11_folded_hist = s2_gh_pool[$urandom_range(0, 3)][7:0] ^ 8'($urandom_range(0, 1));
        s2_io_update_ghist = s2_gh_pool[$urandom_range(0, 3)];
        if (s2_mode < 13) begin
          s2_boreChildrenBd_bore_req = 1'b0; s2_boreChildrenBd_bore_all = 1'b0;
          s2_boreChildrenBd_bore_array = 7'h0; s2_boreChildrenBd_bore_writeen = 1'b0; s2_boreChildrenBd_bore_readen = 1'b0;
          s2_sigFromSrams_bore_ram_hold = 1'b0; s2_sigFromSrams_bore_ram_bypass = 1'b0; s2_sigFromSrams_bore_ram_bp_clken = 1'b0;
          s2_sigFromSrams_bore_ram_aux_clk = 1'b0; s2_sigFromSrams_bore_ram_aux_ckbp = 1'b0; s2_sigFromSrams_bore_ram_mcp_hold = 1'b0;
          s2_sigFromSrams_bore_cgen = 1'b0;
          s2_sigFromSrams_bore_1_ram_hold = 1'b0; s2_sigFromSrams_bore_1_ram_bypass = 1'b0; s2_sigFromSrams_bore_1_ram_bp_clken = 1'b0;
          s2_sigFromSrams_bore_1_ram_aux_clk = 1'b0; s2_sigFromSrams_bore_1_ram_aux_ckbp = 1'b0; s2_sigFromSrams_bore_1_ram_mcp_hold = 1'b0;
          s2_sigFromSrams_bore_1_cgen = 1'b0;
        end
      end
      if (cyc % 2000 == 0) s3_mode = $urandom_range(0, 15);
      s3_io_req_valid = 1'($urandom);
      s3_io_req_bits_pc = 50'({$urandom, $urandom});
      s3_io_req_bits_folded_hist_hist_2_folded_hist = 8'($urandom);
      s3_io_update_pc = 50'({$urandom, $urandom});
      s3_io_update_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      s3_io_update_mask_0 = 1'($urandom);
      s3_io_update_mask_1 = 1'($urandom);
      s3_io_update_oldCtrs_0 = 6'($urandom);
      s3_io_update_oldCtrs_1 = 6'($urandom);
      s3_io_update_tagePreds_0 = 1'($urandom);
      s3_io_update_tagePreds_1 = 1'($urandom);
      s3_io_update_takens_0 = 1'($urandom);
      s3_io_update_takens_1 = 1'($urandom);
      s3_boreChildrenBd_bore_array = 7'($urandom);
      s3_boreChildrenBd_bore_all = 1'($urandom);
      s3_boreChildrenBd_bore_req = 1'($urandom);
      s3_boreChildrenBd_bore_writeen = 1'($urandom);
      s3_boreChildrenBd_bore_be = 4'($urandom);
      s3_boreChildrenBd_bore_addr = 8'($urandom);
      s3_boreChildrenBd_bore_indata = 24'($urandom);
      s3_boreChildrenBd_bore_readen = 1'($urandom);
      s3_boreChildrenBd_bore_addr_rd = 8'($urandom);
      s3_sigFromSrams_bore_ram_hold = 1'($urandom);
      s3_sigFromSrams_bore_ram_bypass = 1'($urandom);
      s3_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      s3_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      s3_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      s3_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      s3_sigFromSrams_bore_cgen = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      s3_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      s3_sigFromSrams_bore_1_cgen = 1'($urandom);
      s3_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_s3
        s3_io_req_bits_pc = s3_pc_pool[$urandom_range(0, 23)];
        s3_io_update_pc = s3_pc_pool[$urandom_range(0, 23)];
        s3_io_update_oldCtrs_0 = s3_pick_ctr();
        s3_io_update_oldCtrs_1 = s3_pick_ctr();
        s3_io_req_bits_folded_hist_hist_2_folded_hist = s3_gh_pool[$urandom_range(0, 3)][7:0] ^ 8'($urandom_range(0, 1));
        s3_io_update_ghist = s3_gh_pool[$urandom_range(0, 3)];
        if (s3_mode < 13) begin
          s3_boreChildrenBd_bore_req = 1'b0; s3_boreChildrenBd_bore_all = 1'b0;
          s3_boreChildrenBd_bore_array = 7'h0; s3_boreChildrenBd_bore_writeen = 1'b0; s3_boreChildrenBd_bore_readen = 1'b0;
          s3_sigFromSrams_bore_ram_hold = 1'b0; s3_sigFromSrams_bore_ram_bypass = 1'b0; s3_sigFromSrams_bore_ram_bp_clken = 1'b0;
          s3_sigFromSrams_bore_ram_aux_clk = 1'b0; s3_sigFromSrams_bore_ram_aux_ckbp = 1'b0; s3_sigFromSrams_bore_ram_mcp_hold = 1'b0;
          s3_sigFromSrams_bore_cgen = 1'b0;
          s3_sigFromSrams_bore_1_ram_hold = 1'b0; s3_sigFromSrams_bore_1_ram_bypass = 1'b0; s3_sigFromSrams_bore_1_ram_bp_clken = 1'b0;
          s3_sigFromSrams_bore_1_ram_aux_clk = 1'b0; s3_sigFromSrams_bore_1_ram_aux_ckbp = 1'b0; s3_sigFromSrams_bore_1_ram_mcp_hold = 1'b0;
          s3_sigFromSrams_bore_1_cgen = 1'b0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && s0_armed_at >= 0 && cyc >= s0_armed_at) begin
        checks++;
        if (s0_g_io_resp_ctrs_0_0 !== s0_i_io_resp_ctrs_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.io_resp_ctrs_0_0 g=%h i=%h", cyc, s0_g_io_resp_ctrs_0_0, s0_i_io_resp_ctrs_0_0);
        end
        s0_s1_io_resp_ctrs_0_0 |= s0_g_io_resp_ctrs_0_0;
        s0_s0_io_resp_ctrs_0_0 |= ~s0_g_io_resp_ctrs_0_0;
        checks++;
        if (s0_g_io_resp_ctrs_0_1 !== s0_i_io_resp_ctrs_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.io_resp_ctrs_0_1 g=%h i=%h", cyc, s0_g_io_resp_ctrs_0_1, s0_i_io_resp_ctrs_0_1);
        end
        s0_s1_io_resp_ctrs_0_1 |= s0_g_io_resp_ctrs_0_1;
        s0_s0_io_resp_ctrs_0_1 |= ~s0_g_io_resp_ctrs_0_1;
        checks++;
        if (s0_g_io_resp_ctrs_1_0 !== s0_i_io_resp_ctrs_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.io_resp_ctrs_1_0 g=%h i=%h", cyc, s0_g_io_resp_ctrs_1_0, s0_i_io_resp_ctrs_1_0);
        end
        s0_s1_io_resp_ctrs_1_0 |= s0_g_io_resp_ctrs_1_0;
        s0_s0_io_resp_ctrs_1_0 |= ~s0_g_io_resp_ctrs_1_0;
        checks++;
        if (s0_g_io_resp_ctrs_1_1 !== s0_i_io_resp_ctrs_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.io_resp_ctrs_1_1 g=%h i=%h", cyc, s0_g_io_resp_ctrs_1_1, s0_i_io_resp_ctrs_1_1);
        end
        s0_s1_io_resp_ctrs_1_1 |= s0_g_io_resp_ctrs_1_1;
        s0_s0_io_resp_ctrs_1_1 |= ~s0_g_io_resp_ctrs_1_1;
        checks++;
        if (s0_g_boreChildrenBd_bore_ack !== s0_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.boreChildrenBd_bore_ack g=%h i=%h", cyc, s0_g_boreChildrenBd_bore_ack, s0_i_boreChildrenBd_bore_ack);
        end
        s0_s1_boreChildrenBd_bore_ack |= s0_g_boreChildrenBd_bore_ack;
        s0_s0_boreChildrenBd_bore_ack |= ~s0_g_boreChildrenBd_bore_ack;
        checks++;
        if (s0_g_boreChildrenBd_bore_outdata !== s0_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable.boreChildrenBd_bore_outdata g=%h i=%h", cyc, s0_g_boreChildrenBd_bore_outdata, s0_i_boreChildrenBd_bore_outdata);
        end
        s0_s1_boreChildrenBd_bore_outdata |= s0_g_boreChildrenBd_bore_outdata;
        s0_s0_boreChildrenBd_bore_outdata |= ~s0_g_boreChildrenBd_bore_outdata;
        if (s0_u_gold.s1_resp_invalid_by_conflict && !s0_reset) s0_cov_conflict_zeroed++;
        if (s0_io_update_mask_0 && s0_u_gold._wrbypasses_0_io_hit && (s0_u_gold._wrbypasses_0_io_hit_data_0_valid || s0_u_gold._wrbypasses_0_io_hit_data_1_valid)) s0_cov_bypass_hit_valid_br0++;
        if (s0_io_update_mask_1 && s0_u_gold._wrbypasses_1_io_hit && (s0_u_gold._wrbypasses_1_io_hit_data_0_valid || s0_u_gold._wrbypasses_1_io_hit_data_1_valid)) s0_cov_bypass_hit_valid_br1++;
        if (s0_u_gold.update_wdata_0 == 6'h1F && s0_u_gold.oldCtr == 6'h1F) s0_cov_sat_pos_hold++;
        if (s0_u_gold.update_wdata_1 == 6'h20 && s0_u_gold.oldCtr_1 == 6'h20) s0_cov_sat_neg_hold++;
        if (s0_u_gold.table_0.io_w_req_valid && !s0_u_gold.table_0._resetState) s0_cov_bank0_write++;
        if (s0_u_gold.table_1.io_w_req_valid && !s0_u_gold.table_1._resetState) s0_cov_bank1_write++;
      end
      if (s0_u_gold.table_0.ren) s0_armed[0] = 1'b1;
      if (s0_u_gold.table_1.ren) s0_armed[1] = 1'b1;
      if (s0_armed_at < 0 && (&s0_armed)) s0_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && s1_armed_at >= 0 && cyc >= s1_armed_at) begin
        checks++;
        if (s1_g_io_resp_ctrs_0_0 !== s1_i_io_resp_ctrs_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.io_resp_ctrs_0_0 g=%h i=%h", cyc, s1_g_io_resp_ctrs_0_0, s1_i_io_resp_ctrs_0_0);
        end
        s1_s1_io_resp_ctrs_0_0 |= s1_g_io_resp_ctrs_0_0;
        s1_s0_io_resp_ctrs_0_0 |= ~s1_g_io_resp_ctrs_0_0;
        checks++;
        if (s1_g_io_resp_ctrs_0_1 !== s1_i_io_resp_ctrs_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.io_resp_ctrs_0_1 g=%h i=%h", cyc, s1_g_io_resp_ctrs_0_1, s1_i_io_resp_ctrs_0_1);
        end
        s1_s1_io_resp_ctrs_0_1 |= s1_g_io_resp_ctrs_0_1;
        s1_s0_io_resp_ctrs_0_1 |= ~s1_g_io_resp_ctrs_0_1;
        checks++;
        if (s1_g_io_resp_ctrs_1_0 !== s1_i_io_resp_ctrs_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.io_resp_ctrs_1_0 g=%h i=%h", cyc, s1_g_io_resp_ctrs_1_0, s1_i_io_resp_ctrs_1_0);
        end
        s1_s1_io_resp_ctrs_1_0 |= s1_g_io_resp_ctrs_1_0;
        s1_s0_io_resp_ctrs_1_0 |= ~s1_g_io_resp_ctrs_1_0;
        checks++;
        if (s1_g_io_resp_ctrs_1_1 !== s1_i_io_resp_ctrs_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.io_resp_ctrs_1_1 g=%h i=%h", cyc, s1_g_io_resp_ctrs_1_1, s1_i_io_resp_ctrs_1_1);
        end
        s1_s1_io_resp_ctrs_1_1 |= s1_g_io_resp_ctrs_1_1;
        s1_s0_io_resp_ctrs_1_1 |= ~s1_g_io_resp_ctrs_1_1;
        checks++;
        if (s1_g_boreChildrenBd_bore_ack !== s1_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.boreChildrenBd_bore_ack g=%h i=%h", cyc, s1_g_boreChildrenBd_bore_ack, s1_i_boreChildrenBd_bore_ack);
        end
        s1_s1_boreChildrenBd_bore_ack |= s1_g_boreChildrenBd_bore_ack;
        s1_s0_boreChildrenBd_bore_ack |= ~s1_g_boreChildrenBd_bore_ack;
        checks++;
        if (s1_g_boreChildrenBd_bore_outdata !== s1_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_1.boreChildrenBd_bore_outdata g=%h i=%h", cyc, s1_g_boreChildrenBd_bore_outdata, s1_i_boreChildrenBd_bore_outdata);
        end
        s1_s1_boreChildrenBd_bore_outdata |= s1_g_boreChildrenBd_bore_outdata;
        s1_s0_boreChildrenBd_bore_outdata |= ~s1_g_boreChildrenBd_bore_outdata;
        if (s1_u_gold.s1_resp_invalid_by_conflict && !s1_reset) s1_cov_conflict_zeroed++;
        if (s1_io_update_mask_0 && s1_u_gold._wrbypasses_0_io_hit && (s1_u_gold._wrbypasses_0_io_hit_data_0_valid || s1_u_gold._wrbypasses_0_io_hit_data_1_valid)) s1_cov_bypass_hit_valid_br0++;
        if (s1_io_update_mask_1 && s1_u_gold._wrbypasses_1_io_hit && (s1_u_gold._wrbypasses_1_io_hit_data_0_valid || s1_u_gold._wrbypasses_1_io_hit_data_1_valid)) s1_cov_bypass_hit_valid_br1++;
        if (s1_u_gold.update_wdata_0 == 6'h1F && s1_u_gold.oldCtr == 6'h1F) s1_cov_sat_pos_hold++;
        if (s1_u_gold.update_wdata_1 == 6'h20 && s1_u_gold.oldCtr_1 == 6'h20) s1_cov_sat_neg_hold++;
        if (s1_u_gold.table_0.io_w_req_valid && !s1_u_gold.table_0._resetState) s1_cov_bank0_write++;
        if (s1_u_gold.table_1.io_w_req_valid && !s1_u_gold.table_1._resetState) s1_cov_bank1_write++;
      end
      if (s1_u_gold.table_0.ren) s1_armed[0] = 1'b1;
      if (s1_u_gold.table_1.ren) s1_armed[1] = 1'b1;
      if (s1_armed_at < 0 && (&s1_armed)) s1_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && s2_armed_at >= 0 && cyc >= s2_armed_at) begin
        checks++;
        if (s2_g_io_resp_ctrs_0_0 !== s2_i_io_resp_ctrs_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.io_resp_ctrs_0_0 g=%h i=%h", cyc, s2_g_io_resp_ctrs_0_0, s2_i_io_resp_ctrs_0_0);
        end
        s2_s1_io_resp_ctrs_0_0 |= s2_g_io_resp_ctrs_0_0;
        s2_s0_io_resp_ctrs_0_0 |= ~s2_g_io_resp_ctrs_0_0;
        checks++;
        if (s2_g_io_resp_ctrs_0_1 !== s2_i_io_resp_ctrs_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.io_resp_ctrs_0_1 g=%h i=%h", cyc, s2_g_io_resp_ctrs_0_1, s2_i_io_resp_ctrs_0_1);
        end
        s2_s1_io_resp_ctrs_0_1 |= s2_g_io_resp_ctrs_0_1;
        s2_s0_io_resp_ctrs_0_1 |= ~s2_g_io_resp_ctrs_0_1;
        checks++;
        if (s2_g_io_resp_ctrs_1_0 !== s2_i_io_resp_ctrs_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.io_resp_ctrs_1_0 g=%h i=%h", cyc, s2_g_io_resp_ctrs_1_0, s2_i_io_resp_ctrs_1_0);
        end
        s2_s1_io_resp_ctrs_1_0 |= s2_g_io_resp_ctrs_1_0;
        s2_s0_io_resp_ctrs_1_0 |= ~s2_g_io_resp_ctrs_1_0;
        checks++;
        if (s2_g_io_resp_ctrs_1_1 !== s2_i_io_resp_ctrs_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.io_resp_ctrs_1_1 g=%h i=%h", cyc, s2_g_io_resp_ctrs_1_1, s2_i_io_resp_ctrs_1_1);
        end
        s2_s1_io_resp_ctrs_1_1 |= s2_g_io_resp_ctrs_1_1;
        s2_s0_io_resp_ctrs_1_1 |= ~s2_g_io_resp_ctrs_1_1;
        checks++;
        if (s2_g_boreChildrenBd_bore_ack !== s2_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.boreChildrenBd_bore_ack g=%h i=%h", cyc, s2_g_boreChildrenBd_bore_ack, s2_i_boreChildrenBd_bore_ack);
        end
        s2_s1_boreChildrenBd_bore_ack |= s2_g_boreChildrenBd_bore_ack;
        s2_s0_boreChildrenBd_bore_ack |= ~s2_g_boreChildrenBd_bore_ack;
        checks++;
        if (s2_g_boreChildrenBd_bore_outdata !== s2_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_2.boreChildrenBd_bore_outdata g=%h i=%h", cyc, s2_g_boreChildrenBd_bore_outdata, s2_i_boreChildrenBd_bore_outdata);
        end
        s2_s1_boreChildrenBd_bore_outdata |= s2_g_boreChildrenBd_bore_outdata;
        s2_s0_boreChildrenBd_bore_outdata |= ~s2_g_boreChildrenBd_bore_outdata;
        if (s2_u_gold.s1_resp_invalid_by_conflict && !s2_reset) s2_cov_conflict_zeroed++;
        if (s2_io_update_mask_0 && s2_u_gold._wrbypasses_0_io_hit && (s2_u_gold._wrbypasses_0_io_hit_data_0_valid || s2_u_gold._wrbypasses_0_io_hit_data_1_valid)) s2_cov_bypass_hit_valid_br0++;
        if (s2_io_update_mask_1 && s2_u_gold._wrbypasses_1_io_hit && (s2_u_gold._wrbypasses_1_io_hit_data_0_valid || s2_u_gold._wrbypasses_1_io_hit_data_1_valid)) s2_cov_bypass_hit_valid_br1++;
        if (s2_u_gold.update_wdata_0 == 6'h1F && s2_u_gold.oldCtr == 6'h1F) s2_cov_sat_pos_hold++;
        if (s2_u_gold.update_wdata_1 == 6'h20 && s2_u_gold.oldCtr_1 == 6'h20) s2_cov_sat_neg_hold++;
        if (s2_u_gold.table_0.io_w_req_valid && !s2_u_gold.table_0._resetState) s2_cov_bank0_write++;
        if (s2_u_gold.table_1.io_w_req_valid && !s2_u_gold.table_1._resetState) s2_cov_bank1_write++;
      end
      if (s2_u_gold.table_0.ren) s2_armed[0] = 1'b1;
      if (s2_u_gold.table_1.ren) s2_armed[1] = 1'b1;
      if (s2_armed_at < 0 && (&s2_armed)) s2_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && s3_armed_at >= 0 && cyc >= s3_armed_at) begin
        checks++;
        if (s3_g_io_resp_ctrs_0_0 !== s3_i_io_resp_ctrs_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.io_resp_ctrs_0_0 g=%h i=%h", cyc, s3_g_io_resp_ctrs_0_0, s3_i_io_resp_ctrs_0_0);
        end
        s3_s1_io_resp_ctrs_0_0 |= s3_g_io_resp_ctrs_0_0;
        s3_s0_io_resp_ctrs_0_0 |= ~s3_g_io_resp_ctrs_0_0;
        checks++;
        if (s3_g_io_resp_ctrs_0_1 !== s3_i_io_resp_ctrs_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.io_resp_ctrs_0_1 g=%h i=%h", cyc, s3_g_io_resp_ctrs_0_1, s3_i_io_resp_ctrs_0_1);
        end
        s3_s1_io_resp_ctrs_0_1 |= s3_g_io_resp_ctrs_0_1;
        s3_s0_io_resp_ctrs_0_1 |= ~s3_g_io_resp_ctrs_0_1;
        checks++;
        if (s3_g_io_resp_ctrs_1_0 !== s3_i_io_resp_ctrs_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.io_resp_ctrs_1_0 g=%h i=%h", cyc, s3_g_io_resp_ctrs_1_0, s3_i_io_resp_ctrs_1_0);
        end
        s3_s1_io_resp_ctrs_1_0 |= s3_g_io_resp_ctrs_1_0;
        s3_s0_io_resp_ctrs_1_0 |= ~s3_g_io_resp_ctrs_1_0;
        checks++;
        if (s3_g_io_resp_ctrs_1_1 !== s3_i_io_resp_ctrs_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.io_resp_ctrs_1_1 g=%h i=%h", cyc, s3_g_io_resp_ctrs_1_1, s3_i_io_resp_ctrs_1_1);
        end
        s3_s1_io_resp_ctrs_1_1 |= s3_g_io_resp_ctrs_1_1;
        s3_s0_io_resp_ctrs_1_1 |= ~s3_g_io_resp_ctrs_1_1;
        checks++;
        if (s3_g_boreChildrenBd_bore_ack !== s3_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.boreChildrenBd_bore_ack g=%h i=%h", cyc, s3_g_boreChildrenBd_bore_ack, s3_i_boreChildrenBd_bore_ack);
        end
        s3_s1_boreChildrenBd_bore_ack |= s3_g_boreChildrenBd_bore_ack;
        s3_s0_boreChildrenBd_bore_ack |= ~s3_g_boreChildrenBd_bore_ack;
        checks++;
        if (s3_g_boreChildrenBd_bore_outdata !== s3_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SCTable_3.boreChildrenBd_bore_outdata g=%h i=%h", cyc, s3_g_boreChildrenBd_bore_outdata, s3_i_boreChildrenBd_bore_outdata);
        end
        s3_s1_boreChildrenBd_bore_outdata |= s3_g_boreChildrenBd_bore_outdata;
        s3_s0_boreChildrenBd_bore_outdata |= ~s3_g_boreChildrenBd_bore_outdata;
        if (s3_u_gold.s1_resp_invalid_by_conflict && !s3_reset) s3_cov_conflict_zeroed++;
        if (s3_io_update_mask_0 && s3_u_gold._wrbypasses_0_io_hit && (s3_u_gold._wrbypasses_0_io_hit_data_0_valid || s3_u_gold._wrbypasses_0_io_hit_data_1_valid)) s3_cov_bypass_hit_valid_br0++;
        if (s3_io_update_mask_1 && s3_u_gold._wrbypasses_1_io_hit && (s3_u_gold._wrbypasses_1_io_hit_data_0_valid || s3_u_gold._wrbypasses_1_io_hit_data_1_valid)) s3_cov_bypass_hit_valid_br1++;
        if (s3_u_gold.update_wdata_0 == 6'h1F && s3_u_gold.oldCtr == 6'h1F) s3_cov_sat_pos_hold++;
        if (s3_u_gold.update_wdata_1 == 6'h20 && s3_u_gold.oldCtr_1 == 6'h20) s3_cov_sat_neg_hold++;
        if (s3_u_gold.table_0.io_w_req_valid && !s3_u_gold.table_0._resetState) s3_cov_bank0_write++;
        if (s3_u_gold.table_1.io_w_req_valid && !s3_u_gold.table_1._resetState) s3_cov_bank1_write++;
      end
      if (s3_u_gold.table_0.ren) s3_armed[0] = 1'b1;
      if (s3_u_gold.table_1.ren) s3_armed[1] = 1'b1;
      if (s3_armed_at < 0 && (&s3_armed)) s3_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(s0_s0_io_resp_ctrs_0_0[0] && s0_s1_io_resp_ctrs_0_0[0])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[0] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_0[1] && s0_s1_io_resp_ctrs_0_0[1])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[1] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_0[2] && s0_s1_io_resp_ctrs_0_0[2])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[2] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_0[3] && s0_s1_io_resp_ctrs_0_0[3])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[3] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_0[4] && s0_s1_io_resp_ctrs_0_0[4])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[4] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_0[5] && s0_s1_io_resp_ctrs_0_0[5])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_0[5] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[0] && s0_s1_io_resp_ctrs_0_1[0])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[0] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[1] && s0_s1_io_resp_ctrs_0_1[1])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[1] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[2] && s0_s1_io_resp_ctrs_0_1[2])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[2] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[3] && s0_s1_io_resp_ctrs_0_1[3])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[3] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[4] && s0_s1_io_resp_ctrs_0_1[4])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[4] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_0_1[5] && s0_s1_io_resp_ctrs_0_1[5])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_0_1[5] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[0] && s0_s1_io_resp_ctrs_1_0[0])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[0] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[1] && s0_s1_io_resp_ctrs_1_0[1])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[1] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[2] && s0_s1_io_resp_ctrs_1_0[2])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[2] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[3] && s0_s1_io_resp_ctrs_1_0[3])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[3] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[4] && s0_s1_io_resp_ctrs_1_0[4])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[4] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_0[5] && s0_s1_io_resp_ctrs_1_0[5])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_0[5] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[0] && s0_s1_io_resp_ctrs_1_1[0])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[0] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[1] && s0_s1_io_resp_ctrs_1_1[1])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[1] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[2] && s0_s1_io_resp_ctrs_1_1[2])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[2] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[3] && s0_s1_io_resp_ctrs_1_1[3])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[3] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[4] && s0_s1_io_resp_ctrs_1_1[4])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[4] 未见过 0 和 1"); end
    if (!(s0_s0_io_resp_ctrs_1_1[5] && s0_s1_io_resp_ctrs_1_1[5])) begin cov_fail++; $display("[COV] SCTable.io_resp_ctrs_1_1[5] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_ack && s0_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[0] && s0_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[1] && s0_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[2] && s0_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[3] && s0_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[4] && s0_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[5] && s0_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[6] && s0_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[7] && s0_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[8] && s0_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[9] && s0_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[10] && s0_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[11] && s0_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[12] && s0_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[13] && s0_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[14] && s0_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[15] && s0_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[16] && s0_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[17] && s0_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[18] && s0_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[19] && s0_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[20] && s0_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[21] && s0_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[22] && s0_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(s0_s0_boreChildrenBd_bore_outdata[23] && s0_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] SCTable.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    $display("[ARM] SCTable armed_at=%0d", s0_armed_at);
    if (s0_armed_at < 0) begin cov_fail++; $display("[ARM] SCTable 从未 arm"); end
    $display("[COV] SCTable.conflict_zeroed = %0d", s0_cov_conflict_zeroed);
    if (s0_cov_conflict_zeroed < 100) begin cov_fail++; $display("[COV] SCTable.conflict_zeroed < 100"); end
    $display("[COV] SCTable.bypass_hit_valid_br0 = %0d", s0_cov_bypass_hit_valid_br0);
    if (s0_cov_bypass_hit_valid_br0 < 100) begin cov_fail++; $display("[COV] SCTable.bypass_hit_valid_br0 < 100"); end
    $display("[COV] SCTable.bypass_hit_valid_br1 = %0d", s0_cov_bypass_hit_valid_br1);
    if (s0_cov_bypass_hit_valid_br1 < 100) begin cov_fail++; $display("[COV] SCTable.bypass_hit_valid_br1 < 100"); end
    $display("[COV] SCTable.sat_pos_hold = %0d", s0_cov_sat_pos_hold);
    if (s0_cov_sat_pos_hold < 100) begin cov_fail++; $display("[COV] SCTable.sat_pos_hold < 100"); end
    $display("[COV] SCTable.sat_neg_hold = %0d", s0_cov_sat_neg_hold);
    if (s0_cov_sat_neg_hold < 100) begin cov_fail++; $display("[COV] SCTable.sat_neg_hold < 100"); end
    $display("[COV] SCTable.bank0_write = %0d", s0_cov_bank0_write);
    if (s0_cov_bank0_write < 100) begin cov_fail++; $display("[COV] SCTable.bank0_write < 100"); end
    $display("[COV] SCTable.bank1_write = %0d", s0_cov_bank1_write);
    if (s0_cov_bank1_write < 100) begin cov_fail++; $display("[COV] SCTable.bank1_write < 100"); end
    if (!(s1_s0_io_resp_ctrs_0_0[0] && s1_s1_io_resp_ctrs_0_0[0])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[0] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_0[1] && s1_s1_io_resp_ctrs_0_0[1])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[1] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_0[2] && s1_s1_io_resp_ctrs_0_0[2])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[2] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_0[3] && s1_s1_io_resp_ctrs_0_0[3])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[3] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_0[4] && s1_s1_io_resp_ctrs_0_0[4])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[4] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_0[5] && s1_s1_io_resp_ctrs_0_0[5])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_0[5] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[0] && s1_s1_io_resp_ctrs_0_1[0])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[0] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[1] && s1_s1_io_resp_ctrs_0_1[1])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[1] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[2] && s1_s1_io_resp_ctrs_0_1[2])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[2] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[3] && s1_s1_io_resp_ctrs_0_1[3])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[3] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[4] && s1_s1_io_resp_ctrs_0_1[4])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[4] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_0_1[5] && s1_s1_io_resp_ctrs_0_1[5])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_0_1[5] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[0] && s1_s1_io_resp_ctrs_1_0[0])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[0] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[1] && s1_s1_io_resp_ctrs_1_0[1])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[1] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[2] && s1_s1_io_resp_ctrs_1_0[2])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[2] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[3] && s1_s1_io_resp_ctrs_1_0[3])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[3] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[4] && s1_s1_io_resp_ctrs_1_0[4])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[4] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_0[5] && s1_s1_io_resp_ctrs_1_0[5])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_0[5] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[0] && s1_s1_io_resp_ctrs_1_1[0])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[0] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[1] && s1_s1_io_resp_ctrs_1_1[1])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[1] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[2] && s1_s1_io_resp_ctrs_1_1[2])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[2] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[3] && s1_s1_io_resp_ctrs_1_1[3])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[3] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[4] && s1_s1_io_resp_ctrs_1_1[4])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[4] 未见过 0 和 1"); end
    if (!(s1_s0_io_resp_ctrs_1_1[5] && s1_s1_io_resp_ctrs_1_1[5])) begin cov_fail++; $display("[COV] SCTable_1.io_resp_ctrs_1_1[5] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_ack && s1_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[0] && s1_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[1] && s1_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[2] && s1_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[3] && s1_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[4] && s1_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[5] && s1_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[6] && s1_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[7] && s1_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[8] && s1_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[9] && s1_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[10] && s1_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[11] && s1_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[12] && s1_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[13] && s1_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[14] && s1_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[15] && s1_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[16] && s1_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[17] && s1_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[18] && s1_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[19] && s1_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[20] && s1_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[21] && s1_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[22] && s1_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(s1_s0_boreChildrenBd_bore_outdata[23] && s1_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] SCTable_1.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    $display("[ARM] SCTable_1 armed_at=%0d", s1_armed_at);
    if (s1_armed_at < 0) begin cov_fail++; $display("[ARM] SCTable_1 从未 arm"); end
    $display("[COV] SCTable_1.conflict_zeroed = %0d", s1_cov_conflict_zeroed);
    if (s1_cov_conflict_zeroed < 100) begin cov_fail++; $display("[COV] SCTable_1.conflict_zeroed < 100"); end
    $display("[COV] SCTable_1.bypass_hit_valid_br0 = %0d", s1_cov_bypass_hit_valid_br0);
    if (s1_cov_bypass_hit_valid_br0 < 100) begin cov_fail++; $display("[COV] SCTable_1.bypass_hit_valid_br0 < 100"); end
    $display("[COV] SCTable_1.bypass_hit_valid_br1 = %0d", s1_cov_bypass_hit_valid_br1);
    if (s1_cov_bypass_hit_valid_br1 < 100) begin cov_fail++; $display("[COV] SCTable_1.bypass_hit_valid_br1 < 100"); end
    $display("[COV] SCTable_1.sat_pos_hold = %0d", s1_cov_sat_pos_hold);
    if (s1_cov_sat_pos_hold < 100) begin cov_fail++; $display("[COV] SCTable_1.sat_pos_hold < 100"); end
    $display("[COV] SCTable_1.sat_neg_hold = %0d", s1_cov_sat_neg_hold);
    if (s1_cov_sat_neg_hold < 100) begin cov_fail++; $display("[COV] SCTable_1.sat_neg_hold < 100"); end
    $display("[COV] SCTable_1.bank0_write = %0d", s1_cov_bank0_write);
    if (s1_cov_bank0_write < 100) begin cov_fail++; $display("[COV] SCTable_1.bank0_write < 100"); end
    $display("[COV] SCTable_1.bank1_write = %0d", s1_cov_bank1_write);
    if (s1_cov_bank1_write < 100) begin cov_fail++; $display("[COV] SCTable_1.bank1_write < 100"); end
    if (!(s2_s0_io_resp_ctrs_0_0[0] && s2_s1_io_resp_ctrs_0_0[0])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[0] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_0[1] && s2_s1_io_resp_ctrs_0_0[1])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[1] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_0[2] && s2_s1_io_resp_ctrs_0_0[2])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[2] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_0[3] && s2_s1_io_resp_ctrs_0_0[3])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[3] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_0[4] && s2_s1_io_resp_ctrs_0_0[4])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[4] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_0[5] && s2_s1_io_resp_ctrs_0_0[5])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_0[5] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[0] && s2_s1_io_resp_ctrs_0_1[0])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[0] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[1] && s2_s1_io_resp_ctrs_0_1[1])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[1] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[2] && s2_s1_io_resp_ctrs_0_1[2])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[2] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[3] && s2_s1_io_resp_ctrs_0_1[3])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[3] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[4] && s2_s1_io_resp_ctrs_0_1[4])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[4] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_0_1[5] && s2_s1_io_resp_ctrs_0_1[5])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_0_1[5] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[0] && s2_s1_io_resp_ctrs_1_0[0])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[0] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[1] && s2_s1_io_resp_ctrs_1_0[1])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[1] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[2] && s2_s1_io_resp_ctrs_1_0[2])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[2] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[3] && s2_s1_io_resp_ctrs_1_0[3])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[3] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[4] && s2_s1_io_resp_ctrs_1_0[4])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[4] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_0[5] && s2_s1_io_resp_ctrs_1_0[5])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_0[5] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[0] && s2_s1_io_resp_ctrs_1_1[0])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[0] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[1] && s2_s1_io_resp_ctrs_1_1[1])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[1] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[2] && s2_s1_io_resp_ctrs_1_1[2])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[2] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[3] && s2_s1_io_resp_ctrs_1_1[3])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[3] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[4] && s2_s1_io_resp_ctrs_1_1[4])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[4] 未见过 0 和 1"); end
    if (!(s2_s0_io_resp_ctrs_1_1[5] && s2_s1_io_resp_ctrs_1_1[5])) begin cov_fail++; $display("[COV] SCTable_2.io_resp_ctrs_1_1[5] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_ack && s2_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[0] && s2_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[1] && s2_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[2] && s2_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[3] && s2_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[4] && s2_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[5] && s2_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[6] && s2_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[7] && s2_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[8] && s2_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[9] && s2_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[10] && s2_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[11] && s2_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[12] && s2_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[13] && s2_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[14] && s2_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[15] && s2_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[16] && s2_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[17] && s2_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[18] && s2_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[19] && s2_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[20] && s2_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[21] && s2_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[22] && s2_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(s2_s0_boreChildrenBd_bore_outdata[23] && s2_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] SCTable_2.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    $display("[ARM] SCTable_2 armed_at=%0d", s2_armed_at);
    if (s2_armed_at < 0) begin cov_fail++; $display("[ARM] SCTable_2 从未 arm"); end
    $display("[COV] SCTable_2.conflict_zeroed = %0d", s2_cov_conflict_zeroed);
    if (s2_cov_conflict_zeroed < 100) begin cov_fail++; $display("[COV] SCTable_2.conflict_zeroed < 100"); end
    $display("[COV] SCTable_2.bypass_hit_valid_br0 = %0d", s2_cov_bypass_hit_valid_br0);
    if (s2_cov_bypass_hit_valid_br0 < 100) begin cov_fail++; $display("[COV] SCTable_2.bypass_hit_valid_br0 < 100"); end
    $display("[COV] SCTable_2.bypass_hit_valid_br1 = %0d", s2_cov_bypass_hit_valid_br1);
    if (s2_cov_bypass_hit_valid_br1 < 100) begin cov_fail++; $display("[COV] SCTable_2.bypass_hit_valid_br1 < 100"); end
    $display("[COV] SCTable_2.sat_pos_hold = %0d", s2_cov_sat_pos_hold);
    if (s2_cov_sat_pos_hold < 100) begin cov_fail++; $display("[COV] SCTable_2.sat_pos_hold < 100"); end
    $display("[COV] SCTable_2.sat_neg_hold = %0d", s2_cov_sat_neg_hold);
    if (s2_cov_sat_neg_hold < 100) begin cov_fail++; $display("[COV] SCTable_2.sat_neg_hold < 100"); end
    $display("[COV] SCTable_2.bank0_write = %0d", s2_cov_bank0_write);
    if (s2_cov_bank0_write < 100) begin cov_fail++; $display("[COV] SCTable_2.bank0_write < 100"); end
    $display("[COV] SCTable_2.bank1_write = %0d", s2_cov_bank1_write);
    if (s2_cov_bank1_write < 100) begin cov_fail++; $display("[COV] SCTable_2.bank1_write < 100"); end
    if (!(s3_s0_io_resp_ctrs_0_0[0] && s3_s1_io_resp_ctrs_0_0[0])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[0] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_0[1] && s3_s1_io_resp_ctrs_0_0[1])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[1] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_0[2] && s3_s1_io_resp_ctrs_0_0[2])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[2] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_0[3] && s3_s1_io_resp_ctrs_0_0[3])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[3] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_0[4] && s3_s1_io_resp_ctrs_0_0[4])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[4] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_0[5] && s3_s1_io_resp_ctrs_0_0[5])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_0[5] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[0] && s3_s1_io_resp_ctrs_0_1[0])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[0] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[1] && s3_s1_io_resp_ctrs_0_1[1])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[1] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[2] && s3_s1_io_resp_ctrs_0_1[2])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[2] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[3] && s3_s1_io_resp_ctrs_0_1[3])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[3] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[4] && s3_s1_io_resp_ctrs_0_1[4])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[4] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_0_1[5] && s3_s1_io_resp_ctrs_0_1[5])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_0_1[5] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[0] && s3_s1_io_resp_ctrs_1_0[0])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[0] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[1] && s3_s1_io_resp_ctrs_1_0[1])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[1] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[2] && s3_s1_io_resp_ctrs_1_0[2])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[2] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[3] && s3_s1_io_resp_ctrs_1_0[3])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[3] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[4] && s3_s1_io_resp_ctrs_1_0[4])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[4] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_0[5] && s3_s1_io_resp_ctrs_1_0[5])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_0[5] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[0] && s3_s1_io_resp_ctrs_1_1[0])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[0] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[1] && s3_s1_io_resp_ctrs_1_1[1])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[1] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[2] && s3_s1_io_resp_ctrs_1_1[2])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[2] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[3] && s3_s1_io_resp_ctrs_1_1[3])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[3] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[4] && s3_s1_io_resp_ctrs_1_1[4])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[4] 未见过 0 和 1"); end
    if (!(s3_s0_io_resp_ctrs_1_1[5] && s3_s1_io_resp_ctrs_1_1[5])) begin cov_fail++; $display("[COV] SCTable_3.io_resp_ctrs_1_1[5] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_ack && s3_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[0] && s3_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[1] && s3_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[2] && s3_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[3] && s3_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[4] && s3_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[5] && s3_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[6] && s3_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[7] && s3_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[8] && s3_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[9] && s3_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[10] && s3_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[11] && s3_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[12] && s3_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[13] && s3_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[14] && s3_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[15] && s3_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[16] && s3_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[17] && s3_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[18] && s3_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[19] && s3_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[20] && s3_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[21] && s3_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[22] && s3_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(s3_s0_boreChildrenBd_bore_outdata[23] && s3_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] SCTable_3.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    $display("[ARM] SCTable_3 armed_at=%0d", s3_armed_at);
    if (s3_armed_at < 0) begin cov_fail++; $display("[ARM] SCTable_3 从未 arm"); end
    $display("[COV] SCTable_3.conflict_zeroed = %0d", s3_cov_conflict_zeroed);
    if (s3_cov_conflict_zeroed < 100) begin cov_fail++; $display("[COV] SCTable_3.conflict_zeroed < 100"); end
    $display("[COV] SCTable_3.bypass_hit_valid_br0 = %0d", s3_cov_bypass_hit_valid_br0);
    if (s3_cov_bypass_hit_valid_br0 < 100) begin cov_fail++; $display("[COV] SCTable_3.bypass_hit_valid_br0 < 100"); end
    $display("[COV] SCTable_3.bypass_hit_valid_br1 = %0d", s3_cov_bypass_hit_valid_br1);
    if (s3_cov_bypass_hit_valid_br1 < 100) begin cov_fail++; $display("[COV] SCTable_3.bypass_hit_valid_br1 < 100"); end
    $display("[COV] SCTable_3.sat_pos_hold = %0d", s3_cov_sat_pos_hold);
    if (s3_cov_sat_pos_hold < 100) begin cov_fail++; $display("[COV] SCTable_3.sat_pos_hold < 100"); end
    $display("[COV] SCTable_3.sat_neg_hold = %0d", s3_cov_sat_neg_hold);
    if (s3_cov_sat_neg_hold < 100) begin cov_fail++; $display("[COV] SCTable_3.sat_neg_hold < 100"); end
    $display("[COV] SCTable_3.bank0_write = %0d", s3_cov_bank0_write);
    if (s3_cov_bank0_write < 100) begin cov_fail++; $display("[COV] SCTable_3.bank0_write < 100"); end
    $display("[COV] SCTable_3.bank1_write = %0d", s3_cov_bank1_write);
    if (s3_cov_bank1_write < 100) begin cov_fail++; $display("[COV] SCTable_3.bank1_write < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
