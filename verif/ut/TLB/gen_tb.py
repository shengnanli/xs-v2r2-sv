#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— TLB（itlb）UT testbench 生成器。

双例化：golden TLB 与派生的 TLB_xs 吃同一组激励，逐拍比全部 43 根输出（1514 位）。
端口表从 G1 golden 逐字读（156 个端口），激励与比较的手写部分在下面的模板里。

用法：
    python3 gen_tb.py            # 生成 tb.sv（幂等：内容不变不写）
    python3 gen_tb.py --check    # tb.sv 与生成器不一致则 rc=1
"""
import os
import re
import sys

GOLDEN = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
TB = os.path.join(HERE, "tb.sv")


def ports():
    t = open(os.path.join(GOLDEN, "TLB.sv")).read()
    m = re.search(r"^module TLB\((.*?)^\);", t, re.S | re.M)
    out = []
    for ln in m.group(1).splitlines():
        mm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$", ln)
        if not mm:
            if ln.strip():
                sys.exit("gen_tb.py: 端口行解析不了：%r" % ln)
            continue
        d, msb, n = mm.groups()
        out.append((d, int(msb) + 1 if msb else 1, n))
    return out


HEADER = r"""// =============================================================================
// TLB（itlb）UT —— golden TLB 对重写 TLB_xs 双例化，同激励逐拍比对全部 43 根输出。
// 本文件由 verif/ut/TLB/gen_tb.py 生成（幂等），不要手改。
//
// 激励要点（判别力来自哪里）：
//   · vaddr 从 8 项 vpn 池取；PTW 模型对 golden 发出的每个 PTW 请求在 1~3 拍后回一个
//     **就是那一页**的响应（tag/asid/vmid 对得上），所以 refill 之后再查同一 vpn 会命中，
//     ptw_just_back / already_back / 阻塞口 block_ptw_hit / 旁路 p_hit 都能走到；
//     另有少量凭空响应（随机池内 vpn、随机 s2xlate）。
//   · 页表 level 0~3、Svnapot、valididx 缺页、pf/af/gpf/gaf、权限位 u/x/a/v 都按偏置概率给，
//     伪 PTE / 非叶子 / G-stage 故障（→ need_gpa → getGpa 往返）都会出现。
//   · CSR 分相：每 1500 拍换一次 satp/vsatp/hgatp.mode ∈ {0, Sv39, Sv48}、imode ∈ {U,S,M}、
//     priv.virt，换的那一拍给对应 changed 脉冲；偶发 sfence（一半带 flushPipe）。
//   · 三口请求随机，阻塞口 resp.ready 随机（85%）；各口 flushPipe 小概率；ptw_req.ready 随机（80%）。
//   · 偶发 3 拍复位脉冲（复位期间不比）。
// 比较窗口：+random 档两侧不复位寄存器初值各摇各的（req_out_vaddr / 旁路 p_* / need_gpa 素材 /
//   表项内容 / difftest 打拍）。复位释放后先等：三口都收过请求、PTW 回过响应、48 项表项全写过
//   一遍（golden 表项写口累计 >= 64 次），再加 4 拍，之后逐拍全比。gpaddr 另需 golden 的
//   resp_gpa_gvpn 被写过一次（resp_gpa_refill 出现过）—— 它只在 getGpa 往返时写，旁路未命中时
//   直接出现在 gpaddr 上。这段等待在 +0 档同样生效，checks 照实打印。
// 覆盖判据：窗口内 三口命中 / 三口 miss / PTW 请求各口 / 阻塞口挂起后由 PTW 直出交付 /
//   flushPipe 回 pf / need_gpa 进入 / getGpa 往返完成 / pf / gpf / af 各类都必须发生过，
//   否则本轮不作数（TEST FAILED）。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit  clk = 0;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;
"""

BODY = r"""
  // ---- 激励状态 ----
  logic [37:0] vpn_pool [8];
  logic [15:0] asid_cur, vasid_cur;
  logic [15:0] vmid_cur;
  typedef struct { logic [37:0] vpn; logic [1:0] s2x; logic get_gpa; int delay; } ptw_job_t;
  ptw_job_t jobs[$];

  function automatic logic [3:0] pick_mode();
    int k = $urandom_range(0, 9);
    return (k < 2) ? 4'h0 : (k < 6) ? 4'h8 : 4'h9;
  endfunction

  // 把 PTW 响应的全部字段按"这一页"拼出来
  task automatic make_ptw_resp(input logic [37:0] vpn, input logic [1:0] s2x, input logic get_gpa);
    logic [7:0] vidx;
    io_ptw_resp_bits_s2xlate          = ($urandom_range(0, 19) == 0) ? 2'($urandom) : s2x;
    io_ptw_resp_bits_s1_entry_tag     = vpn[37:3];
    io_ptw_resp_bits_s1_entry_asid    = ($urandom_range(0, 9) == 0) ? 16'($urandom)
                                        : ((s2x == 2'd0) ? asid_cur : vasid_cur);
    io_ptw_resp_bits_s1_entry_vmid    = ($urandom_range(0, 19) == 0) ? 14'($urandom) : vmid_cur[13:0];
    io_ptw_resp_bits_s1_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s1_entry_pbmt    = ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'd0;
    io_ptw_resp_bits_s1_entry_perm_d  = $urandom_range(0, 1);
    io_ptw_resp_bits_s1_entry_perm_a  = ($urandom_range(0, 9) != 0);
    io_ptw_resp_bits_s1_entry_perm_g  = ($urandom_range(0, 4) == 0);
    io_ptw_resp_bits_s1_entry_perm_u  = $urandom_range(0, 1);
    io_ptw_resp_bits_s1_entry_perm_x  = ($urandom_range(0, 7) != 0);
    io_ptw_resp_bits_s1_entry_perm_w  = $urandom_range(0, 1);
    io_ptw_resp_bits_s1_entry_perm_r  = $urandom_range(0, 1);
    case ($urandom_range(0, 19))
      0, 1, 2:  io_ptw_resp_bits_s1_entry_level = 2'd1;
      3, 4:     io_ptw_resp_bits_s1_entry_level = 2'd2;
      5:        io_ptw_resp_bits_s1_entry_level = 2'd3;
      default:  io_ptw_resp_bits_s1_entry_level = 2'd0;
    endcase
    io_ptw_resp_bits_s1_entry_v       = ($urandom_range(0, 9) != 0);
    io_ptw_resp_bits_s1_entry_ppn     = {9'($urandom), 32'($urandom)};
    io_ptw_resp_bits_s1_addr_low      = vpn[2:0];
    {io_ptw_resp_bits_s1_ppn_low_7, io_ptw_resp_bits_s1_ppn_low_6, io_ptw_resp_bits_s1_ppn_low_5,
     io_ptw_resp_bits_s1_ppn_low_4, io_ptw_resp_bits_s1_ppn_low_3, io_ptw_resp_bits_s1_ppn_low_2,
     io_ptw_resp_bits_s1_ppn_low_1, io_ptw_resp_bits_s1_ppn_low_0} = 24'($urandom);
    vidx = 8'($urandom) | (($urandom_range(0, 7) != 0) ? (8'd1 << vpn[2:0]) : 8'd0);
    {io_ptw_resp_bits_s1_valididx_7, io_ptw_resp_bits_s1_valididx_6, io_ptw_resp_bits_s1_valididx_5,
     io_ptw_resp_bits_s1_valididx_4, io_ptw_resp_bits_s1_valididx_3, io_ptw_resp_bits_s1_valididx_2,
     io_ptw_resp_bits_s1_valididx_1, io_ptw_resp_bits_s1_valididx_0} = vidx;
    {io_ptw_resp_bits_s1_pteidx_7, io_ptw_resp_bits_s1_pteidx_6, io_ptw_resp_bits_s1_pteidx_5,
     io_ptw_resp_bits_s1_pteidx_4, io_ptw_resp_bits_s1_pteidx_3, io_ptw_resp_bits_s1_pteidx_2,
     io_ptw_resp_bits_s1_pteidx_1, io_ptw_resp_bits_s1_pteidx_0} = 8'd1 << vpn[2:0];
    io_ptw_resp_bits_s1_pf            = ($urandom_range(0, 19) == 0);
    io_ptw_resp_bits_s1_af            = ($urandom_range(0, 29) == 0);
    io_ptw_resp_bits_s2_entry_tag     = ($urandom_range(0, 9) == 0) ? 38'($urandom) : vpn;
    io_ptw_resp_bits_s2_entry_vmid    = ($urandom_range(0, 19) == 0) ? 14'($urandom) : vmid_cur[13:0];
    io_ptw_resp_bits_s2_entry_n       = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s2_entry_pbmt    = ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'd0;
    io_ptw_resp_bits_s2_entry_ppn     = {6'($urandom), 32'($urandom)};
    io_ptw_resp_bits_s2_entry_perm_d  = $urandom_range(0, 1);
    io_ptw_resp_bits_s2_entry_perm_a  = ($urandom_range(0, 9) != 0);
    io_ptw_resp_bits_s2_entry_perm_g  = $urandom_range(0, 1);
    io_ptw_resp_bits_s2_entry_perm_u  = $urandom_range(0, 1);
    io_ptw_resp_bits_s2_entry_perm_x  = ($urandom_range(0, 5) != 0);
    io_ptw_resp_bits_s2_entry_perm_w  = $urandom_range(0, 1);
    io_ptw_resp_bits_s2_entry_perm_r  = $urandom_range(0, 1);
    io_ptw_resp_bits_s2_entry_level   = ($urandom_range(0, 3) == 0) ? 2'($urandom) : 2'd0;
    io_ptw_resp_bits_s2_gpf           = ($urandom_range(0, 9) == 0);
    io_ptw_resp_bits_s2_gaf           = ($urandom_range(0, 29) == 0);
    io_ptw_resp_bits_getGpa           = get_gpa;
  endtask

  task automatic drive_inputs(input longint c);
    // ---- CSR 分相 ----
    io_csr_satp_changed      = 1'b0;
    io_csr_vsatp_changed     = 1'b0;
    io_csr_hgatp_changed     = 1'b0;
    io_csr_priv_virt_changed = 1'b0;
    if (c % 1500 == 0) begin
      io_csr_satp_mode  = pick_mode();
      io_csr_vsatp_mode = pick_mode();
      io_csr_hgatp_mode = pick_mode();
      case ($urandom_range(0, 5))
        0:       io_csr_priv_imode = 2'd3;
        1, 2:    io_csr_priv_imode = 2'd0;
        default: io_csr_priv_imode = 2'd1;
      endcase
      io_csr_priv_virt  = ($urandom_range(0, 2) == 0);
      asid_cur  = 16'($urandom_range(0, 3));
      vasid_cur = 16'($urandom_range(0, 3));
      vmid_cur  = 16'($urandom_range(0, 3));
      io_csr_satp_asid  = asid_cur;
      io_csr_vsatp_asid = vasid_cur;
      io_csr_hgatp_vmid = vmid_cur;
      io_csr_satp_ppn   = 44'($urandom);
      io_csr_vsatp_ppn  = 44'($urandom);
      io_csr_hgatp_ppn  = 44'($urandom);
      io_csr_satp_changed      = 1'b1;
      io_csr_vsatp_changed     = $urandom_range(0, 1);
      io_csr_hgatp_changed     = $urandom_range(0, 1);
      io_csr_priv_virt_changed = $urandom_range(0, 1);
    end
    io_csr_priv_mxr  = $urandom_range(0, 1);
    io_csr_priv_sum  = $urandom_range(0, 1);
    io_csr_priv_vmxr = $urandom_range(0, 1);
    io_csr_priv_vsum = $urandom_range(0, 1);
    io_csr_priv_spvp = $urandom_range(0, 1);
    io_csr_priv_dmode = 2'($urandom);
    io_csr_priv_debug = 1'b0;
    io_csr_mbmc_BME   = 1'b0;
    io_csr_mbmc_CMODE = 1'b0;
    io_csr_pmm_mseccfg = 2'($urandom);
    io_csr_pmm_menvcfg = 2'($urandom);
    io_csr_pmm_henvcfg = 2'($urandom);
    io_csr_pmm_hstatus = 2'($urandom);
    io_csr_pmm_senvcfg = 2'($urandom);
    io_hartId = 6'd5;
    // ---- sfence：偶发，一半带 flushPipe；rs1/rs2 随机（全刷/按地址/按 asid）----
    io_sfence_valid          = ($urandom_range(0, 999) == 0);
    io_sfence_bits_rs1       = $urandom_range(0, 1);
    io_sfence_bits_rs2       = $urandom_range(0, 1);
    io_sfence_bits_addr      = {vpn_pool[$urandom_range(0, 7)], 12'($urandom)};
    io_sfence_bits_id        = 16'($urandom_range(0, 3));
    io_sfence_bits_flushPipe = $urandom_range(0, 1);
    io_sfence_bits_hv        = ($urandom_range(0, 3) == 0);
    io_sfence_bits_hg        = ($urandom_range(0, 3) == 0);
    // ---- 三口请求 ----
    io_requestor_0_req_valid      = ($urandom_range(0, 9) < 6);
    io_requestor_0_req_bits_vaddr = {vpn_pool[$urandom_range(0, 7)], 12'($urandom)};
    io_requestor_1_req_valid      = ($urandom_range(0, 9) < 6);
    io_requestor_1_req_bits_vaddr = {vpn_pool[$urandom_range(0, 7)], 12'($urandom)};
    io_requestor_2_req_valid      = ($urandom_range(0, 9) < 4);
    io_requestor_2_req_bits_vaddr = {vpn_pool[$urandom_range(0, 7)], 12'($urandom)};
    io_requestor_2_resp_ready     = ($urandom_range(0, 19) < 17);
    io_flushPipe_0 = ($urandom_range(0, 99) == 0);
    io_flushPipe_1 = ($urandom_range(0, 99) == 0);
    io_flushPipe_2 = ($urandom_range(0, 49) == 0);
    io_ptw_req_0_ready = ($urandom_range(0, 9) < 8);
    io_ptw_req_1_ready = ($urandom_range(0, 9) < 8);
    io_ptw_req_2_ready = ($urandom_range(0, 9) < 8);
    // ---- PTW 回应：队首到期就回；另有少量凭空回应 ----
    io_ptw_resp_valid = 1'b0;
    make_ptw_resp(vpn_pool[$urandom_range(0, 7)], 2'($urandom), $urandom_range(0, 1));
    if (jobs.size() > 0 && jobs[0].delay <= 0) begin
      ptw_job_t j = jobs.pop_front();
      make_ptw_resp(j.vpn, j.s2x, j.get_gpa);
      io_ptw_resp_valid = 1'b1;
    end else if ($urandom_range(0, 49) == 0) begin
      io_ptw_resp_valid = 1'b1;
    end
    foreach (jobs[k]) jobs[k].delay--;
  endtask

  // golden 发出的 PTW 请求被收下 -> 进 PTW 模型队列
  task automatic collect_ptw_reqs();
    if (g_io_ptw_req_0_valid && io_ptw_req_0_ready)
      jobs.push_back('{g_io_ptw_req_0_bits_vpn, g_io_ptw_req_0_bits_s2xlate, g_io_ptw_req_0_bits_getGpa, $urandom_range(1, 3)});
    if (g_io_ptw_req_1_valid && io_ptw_req_1_ready)
      jobs.push_back('{g_io_ptw_req_1_bits_vpn, g_io_ptw_req_1_bits_s2xlate, g_io_ptw_req_1_bits_getGpa, $urandom_range(1, 3)});
    if (g_io_ptw_req_2_valid && io_ptw_req_2_ready)
      jobs.push_back('{g_io_ptw_req_2_bits_vpn, g_io_ptw_req_2_bits_s2xlate, g_io_ptw_req_2_bits_getGpa, $urandom_range(1, 3)});
    while (jobs.size() > 16) void'(jobs.pop_front());
  endtask

  task automatic cmp1(input string name, input logic [338:0] g, input logic [338:0] x);
    checks++;
    if (g !== x) begin
      errors++;
      if (errors <= 20) $display("[%0t] MISMATCH %s golden=%h rewrite=%h", $time, name, g, x);
    end
  endtask

  // ---- 覆盖事件（golden 侧计数，窗口内）----
  longint n_hit[3], n_miss[3], n_ptwreq[3], n_block_ptw, n_flush_pf, n_need_gpa, n_gpa_refill;
  longint n_pf, n_gpf, n_af;
  task automatic collect_cov();
    if (g_dut.req_out_v_0 & ~g_io_requestor_0_resp_bits_miss & g_dut.privNeedTranslate_0) n_hit[0]++;
    if (g_dut.req_out_v_1 & ~g_io_requestor_1_resp_bits_miss & g_dut.privNeedTranslate_1) n_hit[1]++;
    if (g_io_requestor_2_resp_valid & ~g_io_requestor_2_resp_bits_miss & g_dut.privNeedTranslate_2) n_hit[2]++;
    if (g_dut.req_out_v_0 & g_io_requestor_0_resp_bits_miss) n_miss[0]++;
    if (g_dut.req_out_v_1 & g_io_requestor_1_resp_bits_miss) n_miss[1]++;
    if (g_dut.req_out_v_2 & g_io_requestor_2_resp_bits_miss) n_miss[2]++;
    if (g_io_ptw_req_0_valid) n_ptwreq[0]++;
    if (g_io_ptw_req_1_valid) n_ptwreq[1]++;
    if (g_io_ptw_req_2_valid) n_ptwreq[2]++;
    if (g_dut._GEN_27) n_block_ptw++;
    if (g_dut.io_requestor_2_resp_bits_excp_0_pf_st) n_flush_pf++;
    if (g_dut.need_gpa_wire) n_need_gpa++;
    if (g_dut.resp_gpa_refill) n_gpa_refill++;
    if (g_io_requestor_0_resp_bits_excp_0_pf_instr | g_io_requestor_1_resp_bits_excp_0_pf_instr
        | g_io_requestor_2_resp_bits_excp_0_pf_instr) n_pf++;
    if (g_io_requestor_0_resp_bits_excp_0_gpf_instr | g_io_requestor_1_resp_bits_excp_0_gpf_instr
        | g_io_requestor_2_resp_bits_excp_0_gpf_instr) n_gpf++;
    if (g_io_requestor_0_resp_bits_excp_0_af_instr | g_io_requestor_1_resp_bits_excp_0_af_instr
        | g_io_requestor_2_resp_bits_excp_0_af_instr) n_af++;
  endtask

  initial begin
    bit seen_fire[3], seen_ptw, cmp_on, gpa_on;
    int warm_cnt;
    longint n_wr;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 8; i++) vpn_pool[i] = {6'($urandom), 32'($urandom)};
    // 让池里有同一 2MB/1GB 区域内的相邻页（超页命中与 sector 命中都要有）
    vpn_pool[1] = {vpn_pool[0][37:3], 3'd5};
    vpn_pool[2] = {vpn_pool[0][37:9], 9'h1f3};
    vpn_pool[3] = {vpn_pool[0][37:18], 18'h2a5c1};
    seen_fire = '{0, 0, 0}; seen_ptw = 0; cmp_on = 0; gpa_on = 0; warm_cnt = 0; n_wr = 0;
    asid_cur = 0; vasid_cur = 0; vmid_cur = 0;
    reset = 1;
    drive_inputs(0);
    repeat (10) @(negedge clk);
    reset = 0;
    for (longint c = 1; c <= NCYCLES; c++) begin
      if (c > 1000 && $urandom_range(0, 39999) == 0) begin
        reset = 1;
        repeat (3) begin drive_inputs(c); @(negedge clk); end
        reset = 0;
        jobs.delete();
      end
      drive_inputs(c);
      #1;
      if (io_requestor_0_req_valid) seen_fire[0] = 1;
      if (io_requestor_1_req_valid) seen_fire[1] = 1;
      if (io_requestor_2_req_valid && g_io_requestor_2_req_ready) seen_fire[2] = 1;
      if (io_ptw_resp_valid) seen_ptw = 1;
      if (g_dut.entries.io_w_valid) n_wr++;
      if (g_dut.resp_gpa_refill) gpa_on = 1;
      if (seen_fire[0] && seen_fire[1] && seen_fire[2] && seen_ptw && n_wr >= 64 && !cmp_on) begin
        warm_cnt++;
        if (warm_cnt > 4) cmp_on = 1;
      end
      if (cmp_on) begin compare_outputs(gpa_on); collect_cov(); end
      collect_ptw_reqs();
      @(negedge clk);
    end
    $display("=== COVERAGE (TLB) === checks=%0d hit=%0d/%0d/%0d miss=%0d/%0d/%0d ptwreq=%0d/%0d/%0d block_ptw=%0d flush_pf=%0d need_gpa=%0d gpa_refill=%0d pf=%0d gpf=%0d af=%0d",
             checks, n_hit[0], n_hit[1], n_hit[2], n_miss[0], n_miss[1], n_miss[2],
             n_ptwreq[0], n_ptwreq[1], n_ptwreq[2], n_block_ptw, n_flush_pf, n_need_gpa, n_gpa_refill,
             n_pf, n_gpf, n_af);
    if (n_hit[0] == 0 || n_hit[1] == 0 || n_hit[2] == 0 || n_miss[0] == 0 || n_miss[1] == 0 ||
        n_miss[2] == 0 || n_ptwreq[0] == 0 || n_ptwreq[1] == 0 || n_ptwreq[2] == 0 ||
        n_block_ptw == 0 || n_flush_pf == 0 || n_need_gpa == 0 || n_gpa_refill == 0 ||
        n_pf == 0 || n_gpf == 0 || n_af == 0) begin
      $display("COVERAGE INSUFFICIENT");
      errors++;
    end
    if (errors == 0) $display("TEST PASSED (checks=%0d errors=0)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
"""


def gen():
    ps = ports()
    o = [HEADER]
    o.append("  // ---- 输入（两个 DUT 共用）----")
    for d, w, n in ps:
        if d == "input" and n != "clock":
            o.append("  logic %s%s;" % ("[%d:0] " % (w - 1) if w > 1 else "", n))
    o.append("")
    o.append("  // ---- 输出：g_ = golden，x_ = 重写 ----")
    for d, w, n in ps:
        if d == "output":
            o.append("  logic %sg_%s, x_%s;" % ("[%d:0] " % (w - 1) if w > 1 else "", n, n))
    o.append("")
    for mod, inst, pre in (("TLB", "g_dut", "g_"), ("TLB_xs", "x_dut", "x_")):
        o.append("  %s %s (" % (mod, inst))
        conns = []
        for d, w, n in ps:
            if n == "clock":
                conns.append("    .clock (clk)")
            elif d == "input":
                conns.append("    .%s (%s)" % (n, n))
            else:
                conns.append("    .%s (%s%s)" % (n, pre, n))
        o.append(",\n".join(conns))
        o.append("  );")
        o.append("")
    o.append("  // ---- 逐拍比全部输出（gpaddr 另有门控，见文件头）----")
    o.append("  task automatic compare_outputs(input bit gpa_on);")
    for d, w, n in ps:
        if d != "output":
            continue
        line = '    cmp1("%s", g_%s, x_%s);' % (n, n, n)
        if "gpaddr" in n:
            line = "    if (gpa_on) " + line.strip()
        o.append(line)
    o.append("  endtask")
    o.append(BODY)
    return "\n".join(o)


def main():
    text = gen()
    cur = open(TB).read() if os.path.exists(TB) else None
    if "--check" in sys.argv[1:]:
        if cur != text:
            print("gen_tb.py: DRIFT verif/ut/TLB/tb.sv")
            return 1
        print("gen_tb.py: OK    verif/ut/TLB/tb.sv")
        return 0
    if cur != text:
        open(TB, "w").write(text)
        print("gen_tb.py: WROTE verif/ut/TLB/tb.sv")
    else:
        print("gen_tb.py: OK    verif/ut/TLB/tb.sv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
