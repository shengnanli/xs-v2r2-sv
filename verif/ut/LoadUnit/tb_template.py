# -*- coding: utf-8 -*-
"""tb_template.py —— LoadUnit UT tb 的生成模板（被 gen_loadunit.py 调用；本文件本身不单独运行）。

端口声明、双例化连线、逐拍比对由端口表机械生成；**激励整形与覆盖计数是手写的**（本文件里的
SHAPE / COVER 两段 SystemVerilog 文本）。设计意图：

  * 所有输入每拍先全随机，再按"名字模式"整形成有意义的分布：
      - 地址（vaddr/paddr/src_0/tdata2 等）取自一个 4 个页的小地址池 + 随机页内偏移，
        这样 st-ld 违例的地址比较、触发器地址比较、前递的 paddr 才会经常真的相等；
      - robIdx / lqIdx 取自小池子，让重定向冲刷、older/younger 判定两边都常出现；
      - fuOpType 以 90% 取自 load 指令集合（含 prefetch.r/w/i、hlv*），10% 全随机；
      - 各种异常位 / nack / miss / denied / corrupt 按低概率置位；
  * valid 的密度分"相位"变化（每 512 拍换一次），既有稀疏也有全满的压力段；
  * fast_rep_in 以 60% 概率回灌上一拍 golden 的 fast_rep_out（真实系统里就是自己接自己）。

覆盖判据（读重写核内部信号 + golden 输出）：每一路来源被选中并 fire、11 种 replay 原因里
除 wpu_fail（本配置恒 0）外的 10 种、快速重发、非对齐进缓冲、非对齐唤醒回送、回滚、MMIO
写回、NC 带数据、向量写回、D 通道前递、MSHR 前递、全前递、s1/s2 违例、触发器命中、6 种
写回异常、TLB miss、prefetch.i、预取训练，**每项 ≥1 拍**，否则本轮 errors=0 不作数。
"""


def rand_expr(w):
    words = (w + 31) // 32
    if words == 1:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * words))


SHAPE = r'''
  // ---------------------------------------------------------------------------
  // 激励整形（手写）：在全随机之上把关键字段压到"会撞上"的分布
  // ---------------------------------------------------------------------------
  logic [35:0] page_pool [4];      // paddr[47:12] 的页号池
  logic [37:0] vpage_pool [4];     // vaddr[49:12] 的页号池
  logic [7:0]  rob_pool [6];
  int          phase_valid_pct;    // 本相位里各来源 valid 的概率（%）
  int          phase_ready_pct;    // 本相位里 dcache_req_ready 等的概率（%）

  function automatic bit pct(int p);
    return ($urandom_range(0, 99) < p);
  endfunction

  function automatic logic [47:0] rnd_paddr();
    return {page_pool[$urandom_range(0, 3)], 12'($urandom)};
  endfunction

  function automatic logic [49:0] rnd_vaddr();
    logic [49:0] a;
    a = {vpage_pool[$urandom_range(0, 3)], 12'($urandom)};
    case ($urandom_range(0, 3))          // 1/4 拍对齐到 8 字节，1/4 拍贴近 16B 边界
      0: a[2:0] = 3'b000;
      1: a[3:0] = 4'($urandom_range(13, 15));
      default: ;
    endcase
    return a;
  endfunction

  function automatic logic [8:0] rnd_fuop();
    logic [8:0] ops [19] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h04, 9'h05, 9'h06, 9'h08, 9'h09, 9'h0A,
                             9'h10, 9'h11, 9'h12, 9'h13, 9'h14, 9'h15, 9'h16, 9'h1D, 9'h1E};
    if (pct(90)) return ops[$urandom_range(0, 18)];
    return 9'($urandom);
  endfunction

  task automatic new_phase();
    for (int i = 0; i < 4; i++) begin
      page_pool[i]  = 36'({$urandom, $urandom});
      vpage_pool[i] = 38'({$urandom, $urandom});
      if (i == 3) vpage_pool[i] = '0;
    end
    for (int i = 0; i < 6; i++) rob_pool[i] = 8'($urandom);
    case ($urandom_range(0, 3))
      0: phase_valid_pct = 10;
      1: phase_valid_pct = 35;
      2: phase_valid_pct = 60;
      default: phase_valid_pct = 90;
    endcase
    phase_ready_pct = pct(50) ? 95 : 70;
  endtask

  task automatic shape_inputs();
    // ---- 各来源 valid ----
    io_ldin_valid          = pct(phase_valid_pct);
    io_vecldin_valid       = pct(phase_valid_pct / 3);
    io_misalign_ldin_valid = pct(phase_valid_pct / 4);
    io_replay_valid        = pct(phase_valid_pct / 2);
    io_lsq_uncache_valid   = pct(phase_valid_pct / 5);
    io_lsq_nc_ldin_valid   = pct(phase_valid_pct / 5);
    io_prefetch_req_valid  = pct(phase_valid_pct / 3);
    io_redirect_valid      = pct(4);
    io_dcache_req_ready    = pct(phase_ready_pct);
    io_ldout_ready         = pct(95);
    io_misalign_enq_req_ready        = pct(80);
    io_lsq_stld_nuke_query_req_ready = pct(85);
    io_lsq_ldld_nuke_query_req_ready = pct(85);
    io_csrCtrl_ldld_vio_check_enable = pct(90);
    io_csrCtrl_hd_misalign_ld_enable = pct(85);

    // ---- uop / 地址整形 ----
    io_ldin_bits_uop_fuOpType          = rnd_fuop();
    io_vecldin_bits_uop_fuOpType       = rnd_fuop();
    io_misalign_ldin_bits_uop_fuOpType = rnd_fuop();
    io_replay_bits_uop_fuOpType        = rnd_fuop();
    io_lsq_uncache_bits_uop_fuOpType   = rnd_fuop();
    io_lsq_nc_ldin_bits_uop_fuOpType   = rnd_fuop();
    io_lsq_ld_raw_data_uop_fuOpType    = rnd_fuop();
    io_ldin_bits_src_0                 = {14'($urandom), rnd_vaddr()};
    if (pct(80)) io_ldin_bits_src_0[63:50] = {14{io_ldin_bits_src_0[49]}};
    io_ldin_bits_uop_imm               = 32'($urandom_range(0, 4095)) - 32'd2048;
    io_vecldin_bits_vaddr              = {14'h0, rnd_vaddr()};
    io_misalign_ldin_bits_vaddr        = rnd_vaddr();
    io_replay_bits_vaddr               = rnd_vaddr();
    io_lsq_nc_ldin_bits_vaddr          = rnd_vaddr();
    io_lsq_nc_ldin_bits_paddr          = rnd_paddr();
    io_misalign_ldin_bits_paddr        = rnd_paddr();
    io_prefetch_req_bits_paddr         = rnd_paddr();
    io_tlb_resp_bits_paddr_0           = rnd_paddr();
    io_tlb_resp_bits_paddr_1           = io_tlb_resp_bits_paddr_0;
    io_stld_nuke_query_0_bits_paddr    = pct(50) ? io_tlb_resp_bits_paddr_0 : rnd_paddr();
    io_stld_nuke_query_1_bits_paddr    = rnd_paddr();
    io_stld_nuke_query_0_valid         = pct(30);
    io_stld_nuke_query_1_valid         = pct(30);
    io_ldin_bits_uop_robIdx_value          = rob_pool[$urandom_range(0, 5)];
    io_replay_bits_uop_robIdx_value        = rob_pool[$urandom_range(0, 5)];
    io_vecldin_bits_uop_robIdx_value       = rob_pool[$urandom_range(0, 5)];
    io_misalign_ldin_bits_uop_robIdx_value = rob_pool[$urandom_range(0, 5)];
    io_redirect_bits_robIdx_value          = rob_pool[$urandom_range(0, 5)];
    io_stld_nuke_query_0_bits_robIdx_value = rob_pool[$urandom_range(0, 5)];
    io_stld_nuke_query_1_bits_robIdx_value = rob_pool[$urandom_range(0, 5)];
    io_robDeqIdx_value                     = rob_pool[$urandom_range(0, 5)];
    io_replay_bits_uop_lqIdx_value         = 7'($urandom_range(0, 7));
    io_ldin_bits_uop_lqIdx_value           = 7'($urandom_range(0, 7));
    io_vecldin_bits_uop_lqIdx_value        = 7'($urandom_range(0, 7));
    io_replay_bits_forward_tlDchannel      = pct(30);
    io_replay_bits_mshrid                  = 4'($urandom_range(0, 3));
    io_replay_bits_isvec                   = pct(20);
    io_misalign_ldin_bits_misalignNeedWakeUp = pct(20);
    io_misalign_ldin_bits_isvec            = pct(10);
    io_lsq_nc_ldin_bits_isvec              = pct(10);
    io_ldin_bits_uop_storeSetHit           = pct(50);
    io_prefetch_req_bits_confidence        = pct(50);

    // ---- 各级应答 ----
    io_tlb_resp_valid                 = pct(95);
    io_tlb_resp_bits_miss             = pct(12);
    io_tlb_resp_bits_excp_0_pf_ld     = pct(4);
    io_tlb_resp_bits_excp_0_af_ld     = pct(4);
    io_tlb_resp_bits_excp_0_gpf_ld    = pct(3);
    io_tlb_resp_bits_pbmt_0           = pct(80) ? 2'd0 : 2'($urandom);
    io_pmp_ld                         = pct(4);
    io_pmp_st                         = pct(4);
    io_pmp_instr                      = pct(5);
    io_pmp_mmio                       = pct(8);
    io_dcache_resp_bits_miss          = pct(25);
    io_dcache_s2_bank_conflict        = pct(10);
    io_dcache_s2_mq_nack              = pct(10);
    io_dcache_resp_bits_tl_error_delayed_tl_denied  = pct(3);
    io_dcache_resp_bits_tl_error_delayed_tl_corrupt = pct(3);
    begin
      logic [15:0] lsq_fm, sb_fm, ub_fm;
      lsq_fm = pct(40) ? 16'h0 : (pct(20) ? 16'hFFFF : 16'($urandom));
      sb_fm  = pct(50) ? 16'h0 : (pct(10) ? 16'hFFFF : 16'($urandom));
      ub_fm  = pct(70) ? 16'h0 : 16'($urandom);
SPLIT_FWD_MASKS
    end
    io_lsq_forward_dataInvalid        = pct(10);
    io_lsq_forward_addrInvalid        = pct(15);
    io_lsq_forward_matchInvalid       = pct(3);
    io_sbuffer_matchInvalid           = pct(2);
    io_ubuffer_matchInvalid           = pct(2);
    io_forward_mshr_forward_result_valid = pct(30);
    io_forward_mshr_forward_mshr      = pct(40);
    io_forward_mshr_denied            = pct(8);
    io_forward_mshr_corrupt           = pct(8);
    io_tl_d_channel_valid             = pct(40);
    io_tl_d_channel_mshrid            = 4'($urandom_range(0, 3));
    io_tl_d_channel_denied            = pct(8);
    io_tl_d_channel_corrupt           = pct(8);
    io_lsq_ldld_nuke_query_resp_valid = pct(30);

    // ---- 触发器：偶尔打开，地址取自同一地址池 ----
    io_fromCsrTrigger_tEnableVec_0 = pct(30);
    io_fromCsrTrigger_tEnableVec_1 = pct(20);
    io_fromCsrTrigger_tEnableVec_2 = pct(20);
    io_fromCsrTrigger_tEnableVec_3 = pct(20);
    io_fromCsrTrigger_tdataVec_0_select = pct(10);
    io_fromCsrTrigger_tdataVec_0_chain  = pct(20);
    io_fromCsrTrigger_tdataVec_0_load   = pct(90);
    io_fromCsrTrigger_tdataVec_0_action = pct(90) ? 4'($urandom_range(0, 1)) : 4'($urandom);
    io_fromCsrTrigger_tdataVec_0_tdata2 = {14'h0, rnd_vaddr()};
    io_fromCsrTrigger_debugMode         = pct(5);

    // ---- 异常位：各来源 uop 的 exceptionVec 低概率置位 ----
    SHAPE_EXCEPTIONS

    // ---- fast_rep_in 回灌上一拍 golden 的 fast_rep_out ----
    if (have_prev_fast_rep && pct(60)) begin
      io_fast_rep_in_valid = prev_fast_rep_valid;
      FAST_REP_LOOPBACK
    end
  endtask
'''

COVER = r'''
  // ---------------------------------------------------------------------------
  // 覆盖计数（手写）
  // ---------------------------------------------------------------------------
  longint cov_src_fire [11];
  longint cov_cause [11];
  longint cov_ldout_exc [24];
  longint cov_fast_rep, cov_mab_enq, cov_mab_wakeup, cov_rollback_flush, cov_rollback_after;
  longint cov_mmio_wb, cov_nc_wb, cov_vec_wb, cov_d_fwd, cov_mshr_fwd, cov_full_fwd, cov_s1_nuke, cov_s2_nuke;
  longint cov_trigger, cov_tlb_miss, cov_prefetch_i, cov_pf_train, cov_misalign16, cov_cross16, cov_s3_exc;
  longint cov_feedback, cov_ld2cancel, cov_wakeup;

  task automatic collect_cov();
    for (int i = 0; i < 11; i++)
      if (u_impl.u_core.s0_src_select[i] & (u_impl.u_core.s0_fire | u_impl.u_core.s0_mmio_fire))
        cov_src_fire[i]++;
    for (int i = 0; i < 11; i++)
      if (u_impl.u_core.s3_valid_last_REG & u_impl.u_core.s3_lrq_cause[i]) cov_cause[i]++;
    if (g_io_ldout_valid) begin
      if (g_io_ldout_bits_uop_exceptionVec_3)  cov_ldout_exc[3]++;
      if (g_io_ldout_bits_uop_exceptionVec_4)  cov_ldout_exc[4]++;
      if (g_io_ldout_bits_uop_exceptionVec_5)  cov_ldout_exc[5]++;
      if (g_io_ldout_bits_uop_exceptionVec_13) cov_ldout_exc[13]++;
      if (g_io_ldout_bits_uop_exceptionVec_19) cov_ldout_exc[19]++;
      if (g_io_ldout_bits_uop_exceptionVec_21) cov_ldout_exc[21]++;
    end
    if (g_io_fast_rep_out_valid)   cov_fast_rep++;
    if (g_io_misalign_enq_req_valid) cov_mab_enq++;
    if (u_impl.u_core.s3_misalign_wakeup_req_valid_REG_2) cov_mab_wakeup++;
    if (g_io_rollback_valid &  g_io_rollback_bits_level) cov_rollback_flush++;
    if (g_io_rollback_valid & ~g_io_rollback_bits_level) cov_rollback_after++;
    if (g_io_ldout_valid & ~u_impl.u_core.s3_valid_last_REG) cov_mmio_wb++;
    if (g_io_ldout_valid & u_impl.u_core.s3_nc_with_data & u_impl.u_core.s3_valid_last_REG) cov_nc_wb++;
    if (g_io_vecldout_valid) cov_vec_wb++;
    if (u_impl.u_core.s2_valid & u_impl.u_core.s2_fwd_frm_d_chan & io_forward_mshr_forward_result_valid) cov_d_fwd++;
    if (u_impl.u_core.s2_valid & io_forward_mshr_forward_mshr & io_forward_mshr_forward_result_valid) cov_mshr_fwd++;
    if (u_impl.u_core.s2_valid & u_impl.u_core.s2_full_fwd & (|u_impl.u_core.s2_in.mask)) cov_full_fwd++;
    if (u_impl.u_core.s1_valid & (|u_impl.u_core.s1_nuke_hit)) cov_s1_nuke++;
    if (u_impl.u_core.s2_valid & u_impl.u_core.s2_nuke & ~u_impl.u_core.s2_in.rep_info_cause[9]) cov_s2_nuke++;
    if (u_impl.u_core.s1_valid & (u_impl.u_core.s1_trigger_action != 4'hF)) cov_trigger++;
    if (u_impl.u_core.s1_tlb_miss) cov_tlb_miss++;
    if (g_io_ifetchPrefetch_valid) cov_prefetch_i++;
    if (g_io_prefetch_train_valid) cov_pf_train++;
    if (u_impl.u_core.s0_fire & u_impl.u_core.s0_misalignWith16Byte) cov_misalign16++;
    if (u_impl.u_core.s0_fire & u_impl.u_core.s0_rs_cross16Bytes & ~u_impl.u_core.s0_addr_aligned) cov_cross16++;
    if (u_impl.u_core.s3_valid_last_REG & u_impl.u_core.s3_exception) cov_s3_exc++;
    if (g_io_feedback_slow_valid) cov_feedback++;
    if (g_io_ldCancel_ld2Cancel) cov_ld2cancel++;
    if (g_io_wakeup_valid) cov_wakeup++;
  endtask

  function automatic int report_cov();
    int bad = 0;
    string names [11] = '{"mab", "super_rep", "fast_rep", "lsq_rep", "high_pf", "vec", "int",
                          "mmio", "nc", "l2l(off)", "low_pf"};
    string cnames [11] = '{"mem_amb", "tlb_miss", "fwd_fail", "dcache_rep", "dcache_miss", "wpu_fail(off)",
                           "bank_conflict", "rar_nack", "raw_nack", "nuke", "misalign_nack"};
    for (int i = 0; i < 11; i++) begin
      $display("  src %-10s fire=%0d", names[i], cov_src_fire[i]);
      if (i != 9 && cov_src_fire[i] == 0) bad++;
    end
    for (int i = 0; i < 11; i++) begin
      $display("  cause %-14s s3=%0d", cnames[i], cov_cause[i]);
      if (i != 5 && cov_cause[i] == 0) bad++;
    end
    foreach (cov_ldout_exc[i]) if (i inside {3, 4, 5, 13, 19, 21}) begin
      $display("  ldout exceptionVec[%0d]=%0d", i, cov_ldout_exc[i]);
      if (cov_ldout_exc[i] == 0) bad++;
    end
    $display("  fast_rep=%0d mab_enq=%0d mab_wakeup=%0d rollback(flush/after)=%0d/%0d",
             cov_fast_rep, cov_mab_enq, cov_mab_wakeup, cov_rollback_flush, cov_rollback_after);
    $display("  mmio_wb=%0d nc_wb=%0d vec_wb=%0d d_fwd=%0d mshr_fwd=%0d full_fwd=%0d s1_nuke=%0d s2_nuke=%0d",
             cov_mmio_wb, cov_nc_wb, cov_vec_wb, cov_d_fwd, cov_mshr_fwd, cov_full_fwd, cov_s1_nuke, cov_s2_nuke);
    $display("  trigger=%0d tlb_miss=%0d prefetch_i=%0d pf_train=%0d misalign16=%0d cross16=%0d s3_exc=%0d",
             cov_trigger, cov_tlb_miss, cov_prefetch_i, cov_pf_train, cov_misalign16, cov_cross16, cov_s3_exc);
    $display("  feedback=%0d ld2cancel=%0d wakeup=%0d", cov_feedback, cov_ld2cancel, cov_wakeup);
    foreach (cov_src_fire[i]) ;
    if (cov_fast_rep == 0 || cov_mab_enq == 0 || cov_mab_wakeup == 0 || cov_rollback_flush == 0
        || cov_rollback_after == 0 || cov_mmio_wb == 0 || cov_nc_wb == 0 || cov_vec_wb == 0
        || cov_d_fwd == 0 || cov_mshr_fwd == 0 || cov_full_fwd == 0 || cov_s1_nuke == 0 || cov_s2_nuke == 0
        || cov_trigger == 0 || cov_tlb_miss == 0 || cov_prefetch_i == 0 || cov_pf_train == 0
        || cov_misalign16 == 0 || cov_cross16 == 0 || cov_s3_exc == 0 || cov_feedback == 0
        || cov_ld2cancel == 0 || cov_wakeup == 0) bad++;
    return bad;
  endfunction
'''


def gen_tb(ports, regs):
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']
    innames = {n for _, n in ins}
    L = []
    L.append('// =============================================================================')
    L.append('// LoadUnit UT —— golden LoadUnit 对重写 LoadUnit_xs 双例化，同激励逐拍比对全部 %d 根输出。' % len(outs))
    L.append('// 本文件由 verif/ut/LoadUnit/gen_loadunit.py（模板 tb_template.py）生成，不要手改。')
    L.append('// 激励与覆盖判据见 tb_template.py 文件头。')
    L.append('// 两档上电初值：+vcs+initreg+0 从复位后第 0 拍就比；+vcs+initreg+random 两个实例的不复位')
    L.append('// 寄存器各摇各的初值，先跑 +warmup=N 拍让它们全部被写过一遍再开始比（Makefile 按档给 N）。')
    L.append('// =============================================================================')
    L.append('`timescale 1ns/1ps')
    L.append('')
    L.append('module tb;')
    L.append('')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  int unsigned WARMUP  = 0;')
    L.append('  bit     clock = 0;')
    L.append('  logic   reset;')
    L.append('  int     errors = 0;')
    L.append('  longint checks = 0;')
    L.append('  always #5 clock = ~clock;')
    L.append('')
    L.append('  // ---- 输入（两个 DUT 共用）----')
    for w, n in ins:
        L.append('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    L.append('')
    L.append('  // ---- 输出 ----')
    for w, n in outs:
        L.append('  wire  %sg_%s, x_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n, n))
    L.append('')
    for inst, mod, pre in (('u_golden', 'LoadUnit', 'g_'), ('u_impl', 'LoadUnit_xs', 'x_')):
        L.append('  %s %s (' % (mod, inst))
        conns = ['    .clock (clock)', '    .reset (reset)']
        conns += ['    .%s (%s)' % (n, n) for _, n in ins]
        conns += ['    .%s (%s%s)' % (n, pre, n) for _, n in outs]
        L.append(',\n'.join(conns))
        L.append('  );')
        L.append('')
    # fast_rep 回灌的影子寄存器
    loop = []
    for w, n in outs:
        if n.startswith('io_fast_rep_out_bits_'):
            src = n
            dst = 'io_fast_rep_in_bits_' + n[len('io_fast_rep_out_bits_'):]
            if dst in innames:
                loop.append((w, src, dst))
    L.append('  // ---- fast_rep_out → 下一拍 fast_rep_in 的回灌影子 ----')
    L.append('  bit have_prev_fast_rep = 0;')
    L.append('  logic prev_fast_rep_valid;')
    for w, src, dst in loop:
        L.append('  logic %sprev_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', src))
    L.append('  task automatic capture_fast_rep();')
    L.append('    have_prev_fast_rep  = 1;')
    L.append('    prev_fast_rep_valid = g_io_fast_rep_out_valid;')
    for w, src, dst in loop:
        L.append('    prev_%s = g_%s;' % (src, src))
    L.append('  endtask')
    shape = SHAPE
    exc_lines = []
    for w, n in ins:
        if '_uop_exceptionVec_' in n:
            exc_lines.append('    %s = pct(3);' % n)
    shape = shape.replace('    SHAPE_EXCEPTIONS\n', '\n'.join(exc_lines) + '\n')
    split = []
    for pre, var in (('io_lsq_forward_forwardMask_', 'lsq_fm'), ('io_sbuffer_forwardMask_', 'sb_fm'),
                     ('io_ubuffer_forwardMask_', 'ub_fm')):
        for i in range(16):
            split.append('      %s%d = %s[%d];' % (pre, i, var, i))
    shape = shape.replace('SPLIT_FWD_MASKS\n', '\n'.join(split) + '\n')
    shape = shape.replace('      FAST_REP_LOOPBACK\n',
                          ''.join('      %s = prev_%s;\n' % (dst, src) for w, src, dst in loop))
    L.append(shape)
    L.append('  // ---- 每拍：先全随机，再整形 ----')
    L.append('  task automatic drive_inputs();')
    for w, n in ins:
        L.append('    %s = %s;' % (n, rand_expr(w)))
    L.append('    shape_inputs();')
    L.append('  endtask')
    L.append('')
    L.append('  task automatic compare_outputs();')
    L.append('    checks++;')
    for w, n in outs:
        L.append('    if (g_%s !== x_%s) begin errors++; if (errors < 30) '
                 '$display("MISMATCH cyc=%%0d %s g=%%h x=%%h", checks, g_%s, x_%s); end'
                 % (n, n, n, n, n))
    L.append('  endtask')
    L.append(COVER)
    L.append('  initial begin')
    L.append('    int bad;')
    L.append('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    L.append('    if (!$value$plusargs("warmup=%d", WARMUP)) WARMUP = 0;')
    L.append('    foreach (cov_src_fire[i]) cov_src_fire[i] = 0;')
    L.append('    foreach (cov_cause[i]) cov_cause[i] = 0;')
    L.append('    foreach (cov_ldout_exc[i]) cov_ldout_exc[i] = 0;')
    L.append('    {cov_fast_rep, cov_mab_enq, cov_mab_wakeup, cov_rollback_flush, cov_rollback_after} = 0;')
    L.append('    {cov_mmio_wb, cov_nc_wb, cov_vec_wb, cov_d_fwd, cov_mshr_fwd, cov_full_fwd, cov_s1_nuke, cov_s2_nuke} = 0;')
    L.append('    {cov_trigger, cov_tlb_miss, cov_prefetch_i, cov_pf_train, cov_misalign16, cov_cross16, cov_s3_exc} = 0;')
    L.append('    {cov_feedback, cov_ld2cancel, cov_wakeup} = 0;')
    L.append('    new_phase();')
    L.append('    reset = 1;')
    L.append('    drive_inputs();')
    L.append('    repeat (5) @(negedge clock);')
    L.append('    reset = 0;')
    L.append('    for (int unsigned c = 0; c < NCYCLES + WARMUP; c++) begin')
    L.append('      @(negedge clock);')
    L.append('      if (c % 512 == 0) new_phase();')
    L.append('      drive_inputs();')
    L.append('      #4;')
    L.append('      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end')
    L.append('      capture_fast_rep();')
    L.append('    end')
    L.append('    bad = report_cov();')
    L.append('    $display("=== COVERAGE (LoadUnit) === checks=%0d uncovered=%0d", checks, bad);')
    L.append('    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end')
    L.append('    $display("LoadUnit UT: checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);')
    L.append('    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);')
    L.append('    $finish;')
    L.append('  end')
    L.append('')
    L.append('endmodule')
    return '\n'.join(L) + '\n'
