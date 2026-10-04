#!/usr/bin/env python3
"""gen.py —— 生成 verif/ut/FTB/tb.sv（FTB 双例化 UT：golden FTB vs 重写 FTB_xs）。

端口表从 G1 golden FTB.sv 机械读出：每个 input 一根 tb 驱动线（两侧共用），
每个 output 两根（g_/i_），逐拍逐端口比较。激励逻辑（手写模板，见 STIM）：
  * PC 池：64 个 PC（同一 4KB 区内，若干组/tag 撞车），s0 PC 与 update PC 都从池里取，
    保证 FTB 训练后能命中、能出现同组多路；
  * fire：四份 dup 的 fire 多数拍取同值（真实 BPU 就是复制），少数拍各自独立；
    s0_fire[0] 只在 golden 的 io_s1_ready=1 时给（真实 BPU 的握手约束）；
  * uFTB 条目：分阶段——"一致期"直接把 golden ftbBank 当拍读出的条目和命中喂作 uFTB 的
    输入，让一致性计数器连涨到 500 触发"关闭 FTB 读"；"随机期"随机条目；
  * update：随机 pc/条目/meta(hit, way)，偶发 old_entry / false_hit；IFU 重定向偶发，
    用来重开。
复位后 WARMUP 拍（覆盖 SRAM 上电清零 512 拍）不比较。

用法：python3 gen.py [--check]
"""
import argparse
import os
import re
import sys

G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, 'tb.sv')
PORT_RE = re.compile(r'^\s*(input|output)\s+(\[(\d+):0\]\s+)?(\w+),?\s*$')


def ports():
    txt = open(os.path.join(G, 'FTB.sv')).read()
    m = re.search(r'^module FTB\(\n(.*?)^\);', txt, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if not pm:
            raise SystemExit('gen.py: 端口行解析失败 %r' % line)
        res.append((pm.group(1), int(pm.group(3)) + 1 if pm.group(3) else 1, pm.group(4)))
    return res


ENTRY = ['isCall', 'isRet', 'isJalr', 'valid', 'brSlots_0_offset', 'brSlots_0_sharing',
         'brSlots_0_valid', 'brSlots_0_lower', 'brSlots_0_tarStat', 'tailSlot_offset',
         'tailSlot_sharing', 'tailSlot_valid', 'tailSlot_lower', 'tailSlot_tarStat',
         'pftAddr', 'carry', 'last_may_be_rvi_call', 'strong_bias_0', 'strong_bias_1']


def gen():
    P = ports()
    L = []
    A = L.append
    A('// FTB UT —— 自动生成：verif/ut/FTB/gen.py（勿手改）')
    A('// golden FTB vs 重写 FTB_xs（rtl/frontend/FTB.sv 经 derive_ut_impl 改名），逐拍比全部输出。')
    A('// 激励说明见 gen.py 文件头。')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  int unsigned WARMUP  = 1200;')
    A('  bit clock = 0;')
    A('  logic reset;')
    A('  int errors = 0, checks = 0;')
    A('  int unsigned cycle = 0;')
    A('  always #5 clock = ~clock;')
    A('')
    A('  // ---- 输入（两侧共用）----')
    for d, w, n in P:
        if d == 'input' and n not in ('clock', 'reset'):
            A('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    A('  // ---- 输出 ----')
    for d, w, n in P:
        if d == 'output':
            A('  wire %sg_%s, i_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n, n))
    A('')
    for side, mod in (('g', 'FTB'), ('i', 'FTB_xs')):
        A('  %s u_%s (' % (mod, side))
        for k, (d, w, n) in enumerate(P):
            sig = n if d == 'input' else '%s_%s' % (side, n)
            A('    .%s(%s)%s' % (n, sig, ',' if k < len(P) - 1 else ''))
        A('  );')
        A('')
    A('  // ---- 逐拍比较（下降沿采样：上升沿后组合输出已稳定）----')
    A('  task automatic compare();')
    for d, w, n in P:
        if d == 'output':
            A('    checks++;')
            A('    if (g_%s !== i_%s) begin errors++; if (errors <= 20) '
              '$display("[%%0d] MISMATCH %s g=%%h i=%%h", cycle, g_%s, i_%s); end' % (n, n, n, n, n))
    A('  endtask')
    A('')
    A(STIM)
    A('endmodule')
    return '\n'.join(L) + '\n'


STIM = r'''  // ========================================================================
  // 激励
  // ========================================================================
  logic [49:0] pc_pool [64];
  int unsigned phase_left = 0;
  int unsigned phase      = 0;     // 0 = 一致期（uFTB 条目 = golden bank 读出），1 = 随机期
  // 覆盖计数（读 golden 内部线，只统计不参与判定）
  int unsigned cov_s2_hit, cov_multi, cov_close, cov_reopen, cov_upd_now, cov_upd_read,
               cov_write, cov_fterr, cov_cnt_max, cov_s3_hit, cov_cnt_peak, cov_both_hit;

  function automatic logic [49:0] pick_pc();
    return pc_pool[$urandom_range(63)];
  endfunction

  task automatic drive_entry_rand(output logic isCall, isRet, isJalr, valid,
      output logic [3:0] broff, output logic brsh, brv, output logic [11:0] brlo,
      output logic [1:0] brts, output logic [3:0] tloff, output logic tlsh, tlv,
      output logic [19:0] tllo, output logic [1:0] tlts, output logic [3:0] pft,
      output logic carry, lastrvi, sb0, sb1);
    isCall = $urandom; isRet = $urandom; isJalr = $urandom; valid = ($urandom_range(7) != 0);
    broff = $urandom; brsh = $urandom; brv = $urandom; brlo = $urandom; brts = $urandom;
    tloff = $urandom; tlsh = $urandom; tlv = $urandom; tllo = $urandom; tlts = $urandom;
    pft = $urandom; carry = $urandom; lastrvi = $urandom; sb0 = $urandom; sb1 = $urandom;
  endtask

  task automatic copy_bank_to_fau();
      io_fauftb_entry_in_isCall               = u_g.ftbBank.io_read_resp_isCall;
      io_fauftb_entry_in_isRet                = u_g.ftbBank.io_read_resp_isRet;
      io_fauftb_entry_in_isJalr               = u_g.ftbBank.io_read_resp_isJalr;
      io_fauftb_entry_in_valid                = u_g.ftbBank.io_read_resp_valid;
      io_fauftb_entry_in_brSlots_0_offset     = u_g.ftbBank.io_read_resp_brSlots_0_offset;
      io_fauftb_entry_in_brSlots_0_sharing    = u_g.ftbBank.io_read_resp_brSlots_0_sharing;
      io_fauftb_entry_in_brSlots_0_valid      = u_g.ftbBank.io_read_resp_brSlots_0_valid;
      io_fauftb_entry_in_brSlots_0_lower      = u_g.ftbBank.io_read_resp_brSlots_0_lower;
      io_fauftb_entry_in_brSlots_0_tarStat    = u_g.ftbBank.io_read_resp_brSlots_0_tarStat;
      io_fauftb_entry_in_tailSlot_offset      = u_g.ftbBank.io_read_resp_tailSlot_offset;
      io_fauftb_entry_in_tailSlot_sharing     = u_g.ftbBank.io_read_resp_tailSlot_sharing;
      io_fauftb_entry_in_tailSlot_valid       = u_g.ftbBank.io_read_resp_tailSlot_valid;
      io_fauftb_entry_in_tailSlot_lower       = u_g.ftbBank.io_read_resp_tailSlot_lower;
      io_fauftb_entry_in_tailSlot_tarStat     = u_g.ftbBank.io_read_resp_tailSlot_tarStat;
      io_fauftb_entry_in_pftAddr              = u_g.ftbBank.io_read_resp_pftAddr;
      io_fauftb_entry_in_carry                = u_g.ftbBank.io_read_resp_carry;
      io_fauftb_entry_in_last_may_be_rvi_call = u_g.ftbBank.io_read_resp_last_may_be_rvi_call;
      io_fauftb_entry_in_strong_bias_0        = u_g.ftbBank.io_read_resp_strong_bias_0;
      io_fauftb_entry_in_strong_bias_1        = u_g.ftbBank.io_read_resp_strong_bias_1;
      io_fauftb_entry_hit_in                  = u_g.ftbBank.io_read_hits_valid | ($urandom_range(63) == 0);
      if ($urandom_range(8191) == 0) io_fauftb_entry_in_pftAddr = $urandom;  // 偶发不一致
  endtask

  task automatic drive_inputs();
    logic f;
    // ---- 阶段切换 ----
    if (phase_left == 0) begin
      phase      = ($urandom_range(7) == 0) ? 1 : 0;
      phase_left = $urandom_range(3000, 200);
    end
    phase_left--;
    // ---- PC / fire ----
    io_in_bits_s0_pc_0 = pick_pc();
    io_in_bits_s0_pc_1 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    io_in_bits_s0_pc_2 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    io_in_bits_s0_pc_3 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    f = ($urandom_range(3) != 0) && g_io_s1_ready;
    io_s0_fire_0 = f;
    io_s0_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s0_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s0_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    f = ($urandom_range(3) != 0);
    io_s1_fire_0 = f;
    io_s1_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s1_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s1_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    f = ($urandom_range(3) != 0);
    io_s2_fire_0 = f;
    io_s2_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s2_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s2_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s3_fire_0 = $urandom;
    {io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
     io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
     io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1} = $urandom;
    io_ctrl_btb_enable = (phase == 0) || ($urandom_range(31) != 0);
    // ---- uFTB 条目 ----
    if (phase == 0) begin
      copy_bank_to_fau();   // 先给个值；主循环在其它输入稳定后再抄一遍
    end else begin
      drive_entry_rand(io_fauftb_entry_in_isCall, io_fauftb_entry_in_isRet, io_fauftb_entry_in_isJalr,
        io_fauftb_entry_in_valid, io_fauftb_entry_in_brSlots_0_offset, io_fauftb_entry_in_brSlots_0_sharing,
        io_fauftb_entry_in_brSlots_0_valid, io_fauftb_entry_in_brSlots_0_lower,
        io_fauftb_entry_in_brSlots_0_tarStat, io_fauftb_entry_in_tailSlot_offset,
        io_fauftb_entry_in_tailSlot_sharing, io_fauftb_entry_in_tailSlot_valid,
        io_fauftb_entry_in_tailSlot_lower, io_fauftb_entry_in_tailSlot_tarStat, io_fauftb_entry_in_pftAddr,
        io_fauftb_entry_in_carry, io_fauftb_entry_in_last_may_be_rvi_call, io_fauftb_entry_in_strong_bias_0,
        io_fauftb_entry_in_strong_bias_1);
      io_fauftb_entry_hit_in = $urandom;
    end
    // ---- update ----
    io_update_valid          = ($urandom_range(3) == 0);
    io_update_bits_pc        = pick_pc();
    drive_entry_rand(io_update_bits_ftb_entry_isCall, io_update_bits_ftb_entry_isRet,
      io_update_bits_ftb_entry_isJalr, io_update_bits_ftb_entry_valid,
      io_update_bits_ftb_entry_brSlots_0_offset, io_update_bits_ftb_entry_brSlots_0_sharing,
      io_update_bits_ftb_entry_brSlots_0_valid, io_update_bits_ftb_entry_brSlots_0_lower,
      io_update_bits_ftb_entry_brSlots_0_tarStat, io_update_bits_ftb_entry_tailSlot_offset,
      io_update_bits_ftb_entry_tailSlot_sharing, io_update_bits_ftb_entry_tailSlot_valid,
      io_update_bits_ftb_entry_tailSlot_lower, io_update_bits_ftb_entry_tailSlot_tarStat,
      io_update_bits_ftb_entry_pftAddr, io_update_bits_ftb_entry_carry,
      io_update_bits_ftb_entry_last_may_be_rvi_call, io_update_bits_ftb_entry_strong_bias_0,
      io_update_bits_ftb_entry_strong_bias_1);
    io_update_bits_false_hit = ($urandom_range(63) == 0);
    io_update_bits_old_entry = ($urandom_range(7) == 0);
    for (int k = 0; k < 516; k += 32) io_update_bits_meta[k +: 32] = $urandom;
    io_redirectFromIFU       = ($urandom_range(1023) == 0);
    // ---- MBIST / SRAM 旁带：功能模式下保持静默 ----
    boreChildrenBd_bore_array   = '0;  boreChildrenBd_bore_all     = 1'b0;
    boreChildrenBd_bore_req     = 1'b0; boreChildrenBd_bore_writeen = 1'b0;
    boreChildrenBd_bore_be      = '0;  boreChildrenBd_bore_addr    = '0;
    boreChildrenBd_bore_indata  = '0;  boreChildrenBd_bore_readen  = 1'b0;
    boreChildrenBd_bore_addr_rd = '0;
  endtask

  initial begin
    logic [49:0] base;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    base = {$urandom, $urandom} & 50'h3_ffff_ffff_f000;
    for (int k = 0; k < 64; k++)
      // 64 个 PC：同一 4KB 区内，块内偏移随机（覆盖 fall-through 合法/非法两种）
      pc_pool[k] = base | 50'($urandom_range(4095) & ~1);
    io_reset_vector = {$urandom, $urandom};
    // sigFromSrams_*：功能模式全 0
    {sigFromSrams_bore_ram_hold, sigFromSrams_bore_ram_bypass, sigFromSrams_bore_ram_bp_clken,
     sigFromSrams_bore_ram_aux_clk, sigFromSrams_bore_ram_aux_ckbp, sigFromSrams_bore_ram_mcp_hold,
     sigFromSrams_bore_cgen} = '0;
    {sigFromSrams_bore_1_ram_hold, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_1_ram_bp_clken,
     sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_mcp_hold,
     sigFromSrams_bore_1_cgen} = '0;
    {sigFromSrams_bore_2_ram_hold, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_2_ram_bp_clken,
     sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_2_ram_mcp_hold,
     sigFromSrams_bore_2_cgen} = '0;
    {sigFromSrams_bore_3_ram_hold, sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_3_ram_bp_clken,
     sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_3_ram_mcp_hold,
     sigFromSrams_bore_3_cgen} = '0;
    {sigFromSrams_bore_4_ram_hold, sigFromSrams_bore_4_ram_bypass, sigFromSrams_bore_4_ram_bp_clken,
     sigFromSrams_bore_4_ram_aux_clk, sigFromSrams_bore_4_ram_aux_ckbp, sigFromSrams_bore_4_ram_mcp_hold,
     sigFromSrams_bore_4_cgen} = '0;
    {sigFromSrams_bore_5_ram_hold, sigFromSrams_bore_5_ram_bypass, sigFromSrams_bore_5_ram_bp_clken,
     sigFromSrams_bore_5_ram_aux_clk, sigFromSrams_bore_5_ram_aux_ckbp, sigFromSrams_bore_5_ram_mcp_hold,
     sigFromSrams_bore_5_cgen} = '0;
    {sigFromSrams_bore_6_ram_hold, sigFromSrams_bore_6_ram_bypass, sigFromSrams_bore_6_ram_bp_clken,
     sigFromSrams_bore_6_ram_aux_clk, sigFromSrams_bore_6_ram_aux_ckbp, sigFromSrams_bore_6_ram_mcp_hold,
     sigFromSrams_bore_6_cgen} = '0;
    {sigFromSrams_bore_7_ram_hold, sigFromSrams_bore_7_ram_bypass, sigFromSrams_bore_7_ram_bp_clken,
     sigFromSrams_bore_7_ram_aux_clk, sigFromSrams_bore_7_ram_aux_ckbp, sigFromSrams_bore_7_ram_mcp_hold,
     sigFromSrams_bore_7_cgen} = '0;
    reset = 1'b1;
    drive_inputs();
    io_s0_fire_0 = 0; io_s0_fire_1 = 0; io_s0_fire_2 = 0; io_s0_fire_3 = 0;
    io_update_valid = 0;
    repeat (5) @(negedge clock);
    reset = 1'b0;
    while (cycle < NCYCLES) begin
      @(negedge clock);
      drive_inputs();
      #1;
      // bank 读出可能组合依赖本拍刚给的 fire：等其它输入稳定后再把它抄给 uFTB 输入
      if (phase == 0) copy_bank_to_fau();
      #1;
      if (cycle >= WARMUP) compare();
      // 覆盖
      if (u_g.s2_hit_dup_0 && io_s2_fire_0)          cov_s2_hit++;
      if (u_g.s3_hit_dup_0)                          cov_s3_hit++;
      if (u_g.s2_multi_hit_enable_probe)             cov_multi++;
      if (u_g.s2_close_ftb_req && io_s2_fire_0)      cov_close++;
      if (u_g.needReopen)                            cov_reopen++;
      if (u_g.update_now)                            cov_upd_now++;
      if (u_g.update_need_read)                      cov_upd_read++;
      if (u_g.write_valid)                           cov_write++;
      if (u_g.io_out_s2_full_pred_0_fallThroughErr_0) cov_fterr++;
      if (u_g.fauftb_ftb_entry_consistent_counter > 9'd499) cov_cnt_max++;
      if (u_g.fauftb_ftb_entry_consistent_counter > cov_cnt_peak) cov_cnt_peak = u_g.fauftb_ftb_entry_consistent_counter;
      if (io_s2_fire_0 && u_g.s2_fauftb_ftb_entry_hit_dup_0 && u_g.s2_ftb_hit_dup_0) cov_both_hit++;
      cycle++;
    end
    $display("COVERAGE s2_hit=%0d s3_hit=%0d multi_hit_enable=%0d s2_closed=%0d reopen=%0d update_now=%0d update_need_read=%0d write=%0d s2_ft_err=%0d cnt_over_499=%0d cnt_peak=%0d both_hit_s2fire=%0d",
             cov_s2_hit, cov_s3_hit, cov_multi, cov_close, cov_reopen, cov_upd_now, cov_upd_read,
             cov_write, cov_fterr, cov_cnt_max, cov_cnt_peak, cov_both_hit);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    txt = gen()
    if a.check:
        if not os.path.exists(OUT) or open(OUT).read() != txt:
            print('DRIFT: tb.sv 与生成结果不一致')
            return 1
        print('gen.py: OK')
        return 0
    if not os.path.exists(OUT) or open(OUT).read() != txt:
        open(OUT, 'w').write(txt)
    return 0


if __name__ == '__main__':
    sys.exit(main())
