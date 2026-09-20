// tb_initreg_probe.sv —— 证明 `+vcs+initreg` 真的打进了 TlbStorageWrapper_2 的状态
//
// 为什么需要它（本仓已知坑）：
//   ★非打包数组的混合驱动会让 VCS **静默关掉** +vcs+initreg★。一旦发生，
//   "两轮 initreg 都绿"就什么也不证明 —— 因为第二轮根本没换初值。
//   codex 0168 因此要求：不能只跑两轮，还要**验证 initreg 确实改变了待测状态**。
//   本重写件里正好有三个非打包数组（acc_valid[] / acc_bits[] / access[]），
//   所以这条必须当场量，不能假定。
//
// 做法：只例化重写侧，**复位全程不拉高**，在任何时钟沿之前把
//   u_core.refill_idx_state_reg（47 位 PLRU 状态）与内层阵列的一组寄存器打出来。
//   - `+vcs+initreg+0`      期望：全 0
//   - `+vcs+initreg+random` 期望：与上一行**不同**（随 +ntb_random_seed 变）
//   两次相同 ⇒ initreg 没生效 ⇒ 前面那两轮 UT 的"initreg 覆盖"是假的。
//
// 判据在 initreg_probe_check.sh 里（它跑三次、比三份输出），本文件只负责打印。
//
// ★采样时刻要在 #1，不能在 #0★（2026-09-20 实测，第一版就踩了）：
//   在 `#0` 打，三跑全是 `x`，看起来正是"initreg 没生效"的样子 —— 差一点据此
//   写下"非打包数组把 initreg 关掉了"这个**错**结论。改成 `#1` 后立刻分开：
//     +vcs+initreg+0      -> 000000000000
//     +vcs+initreg+random -> 7fffffffffff (seed 1) / 7b5c2d57715a (seed 7)
//   也就是 initreg 的赋值发生在时间 0，但要等 `#0` 那一拍 delta 之后才看得到。
//   **一个采样时刻的错误，会伪装成一个设计结论。**
`timescale 1ns/1ps
module tb;
  logic clock = 0, reset = 0;          // ★reset 恒 0：不许把初值冲掉★
  logic [37:0] vpn0 = '0, vpn1 = '0;

  // 未驱动的输入保持 X/初值即可；只关心内部寄存器的上电值。
  TlbStorageWrapper_2 dut (
    .clock(clock), .reset(reset),
    .io_sfence_valid(1'b0), .io_sfence_bits_rs1(1'b0), .io_sfence_bits_rs2(1'b0),
    .io_sfence_bits_addr('0), .io_sfence_bits_id('0),
    .io_sfence_bits_hv(1'b0), .io_sfence_bits_hg(1'b0),
    .io_csr_satp_asid('0), .io_csr_vsatp_asid('0), .io_csr_hgatp_vmid('0),
    .io_csr_mbmc_BME(1'b0), .io_csr_mbmc_CMODE(1'b0), .io_csr_priv_virt(1'b0),
    .io_r_req_0_valid(1'b0), .io_r_req_0_bits_vpn(vpn0), .io_r_req_0_bits_s2xlate('0),
    .io_r_req_1_valid(1'b0), .io_r_req_1_bits_vpn(vpn1), .io_r_req_1_bits_s2xlate('0),
    .io_w_valid(1'b0), .io_w_bits_data_s2xlate('0),
    .io_w_bits_data_s1_entry_tag('0), .io_w_bits_data_s1_entry_asid('0),
    .io_w_bits_data_s1_entry_vmid('0), .io_w_bits_data_s1_entry_n(1'b0),
    .io_w_bits_data_s1_entry_pbmt('0), .io_w_bits_data_s1_entry_perm_d(1'b0),
    .io_w_bits_data_s1_entry_perm_a(1'b0), .io_w_bits_data_s1_entry_perm_g(1'b0),
    .io_w_bits_data_s1_entry_perm_u(1'b0), .io_w_bits_data_s1_entry_perm_x(1'b0),
    .io_w_bits_data_s1_entry_perm_w(1'b0), .io_w_bits_data_s1_entry_perm_r(1'b0),
    .io_w_bits_data_s1_entry_level('0), .io_w_bits_data_s1_entry_v(1'b0),
    .io_w_bits_data_s1_entry_ppn('0),
    .io_w_bits_data_s1_ppn_low_0('0), .io_w_bits_data_s1_ppn_low_1('0),
    .io_w_bits_data_s1_ppn_low_2('0), .io_w_bits_data_s1_ppn_low_3('0),
    .io_w_bits_data_s1_ppn_low_4('0), .io_w_bits_data_s1_ppn_low_5('0),
    .io_w_bits_data_s1_ppn_low_6('0), .io_w_bits_data_s1_ppn_low_7('0),
    .io_w_bits_data_s1_valididx_0(1'b0), .io_w_bits_data_s1_valididx_1(1'b0),
    .io_w_bits_data_s1_valididx_2(1'b0), .io_w_bits_data_s1_valididx_3(1'b0),
    .io_w_bits_data_s1_valididx_4(1'b0), .io_w_bits_data_s1_valididx_5(1'b0),
    .io_w_bits_data_s1_valididx_6(1'b0), .io_w_bits_data_s1_valididx_7(1'b0),
    .io_w_bits_data_s1_pteidx_0(1'b0), .io_w_bits_data_s1_pteidx_1(1'b0),
    .io_w_bits_data_s1_pteidx_2(1'b0), .io_w_bits_data_s1_pteidx_3(1'b0),
    .io_w_bits_data_s1_pteidx_4(1'b0), .io_w_bits_data_s1_pteidx_5(1'b0),
    .io_w_bits_data_s1_pteidx_6(1'b0), .io_w_bits_data_s1_pteidx_7(1'b0),
    .io_w_bits_data_s1_pf(1'b0), .io_w_bits_data_s1_af(1'b0),
    .io_w_bits_data_s2_entry_tag('0), .io_w_bits_data_s2_entry_vmid('0),
    .io_w_bits_data_s2_entry_n(1'b0), .io_w_bits_data_s2_entry_pbmt('0),
    .io_w_bits_data_s2_entry_ppn('0), .io_w_bits_data_s2_entry_perm_d(1'b0),
    .io_w_bits_data_s2_entry_perm_a(1'b0), .io_w_bits_data_s2_entry_perm_g(1'b0),
    .io_w_bits_data_s2_entry_perm_u(1'b0), .io_w_bits_data_s2_entry_perm_x(1'b0),
    .io_w_bits_data_s2_entry_perm_w(1'b0), .io_w_bits_data_s2_entry_perm_r(1'b0),
    .io_w_bits_data_s2_entry_level('0), .io_w_bits_data_s2_gpf(1'b0),
    .io_w_bits_data_s2_gaf(1'b0),
    .io_r_resp_0_bits_hit(), .io_r_resp_0_bits_ppn_0(), .io_r_resp_0_bits_pbmt_0(),
    .io_r_resp_0_bits_g_pbmt_0(), .io_r_resp_0_bits_perm_0_pf(), .io_r_resp_0_bits_perm_0_af(),
    .io_r_resp_0_bits_perm_0_v(), .io_r_resp_0_bits_perm_0_d(), .io_r_resp_0_bits_perm_0_a(),
    .io_r_resp_0_bits_perm_0_u(), .io_r_resp_0_bits_perm_0_x(), .io_r_resp_0_bits_perm_0_w(),
    .io_r_resp_0_bits_perm_0_r(), .io_r_resp_0_bits_g_perm_0_pf(), .io_r_resp_0_bits_g_perm_0_af(),
    .io_r_resp_0_bits_g_perm_0_d(), .io_r_resp_0_bits_g_perm_0_a(), .io_r_resp_0_bits_g_perm_0_x(),
    .io_r_resp_0_bits_g_perm_0_w(), .io_r_resp_0_bits_g_perm_0_r(), .io_r_resp_0_bits_s2xlate_0(),
    .io_r_resp_1_bits_hit(), .io_r_resp_1_bits_ppn_0(), .io_r_resp_1_bits_pbmt_0(),
    .io_r_resp_1_bits_g_pbmt_0(), .io_r_resp_1_bits_perm_0_pf(), .io_r_resp_1_bits_perm_0_af(),
    .io_r_resp_1_bits_perm_0_v(), .io_r_resp_1_bits_perm_0_d(), .io_r_resp_1_bits_perm_0_a(),
    .io_r_resp_1_bits_perm_0_u(), .io_r_resp_1_bits_perm_0_x(), .io_r_resp_1_bits_perm_0_w(),
    .io_r_resp_1_bits_perm_0_r(), .io_r_resp_1_bits_g_perm_0_pf(), .io_r_resp_1_bits_g_perm_0_af(),
    .io_r_resp_1_bits_g_perm_0_d(), .io_r_resp_1_bits_g_perm_0_a(), .io_r_resp_1_bits_g_perm_0_x(),
    .io_r_resp_1_bits_g_perm_0_w(), .io_r_resp_1_bits_g_perm_0_r(), .io_r_resp_1_bits_s2xlate_0()
  );

  initial begin
    #1;   // 时间 0 之后、任何时钟沿之前
    $display("PROBE plru_state=%h", dut.u_core.refill_idx_state_reg);
    $display("PROBE array_refill_way=%h", dut.page_sttlb_storage_fa.u_core.refill_way_q);
    $finish;
  end
endmodule
