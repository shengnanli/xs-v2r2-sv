#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— 生成 RenameBuffer UT 的 tb.sv。

RenameBuffer 有 153 个端口（69 输入 / 84 输出）。端口声明、双例化连线、以及
84 根输出的逐拍比对都是纯机械的，手抄一次必错；而且这种错误 **UT 自己测不出来**
（tb 抄漏的那根线两侧都不接，两侧都对不上也发现不了）。所以这三段从
**G1 golden 的端口表**直接生成。

手写的部分只有两块，也正是有判断力的部分：
  · 激励（暖机 + 相位状态机，见 tb.sv 里的注释）
  · 覆盖事件统计（用层次引用读 **golden 侧**内部状态，不看重写侧）

用法: python3 gen.py   （Makefile 不自动调用；改了本文件要手动重跑并提交 tb.sv）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/RenameBuffer.sv')
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')


def parse_ports():
    txt = GOLDEN.read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module RenameBuffer('))
    ports, i = [], start + 1
    while txt[i].rstrip() != ');':
        m = PORT_RE.match(txt[i])
        if not m:
            raise SystemExit('端口行解析失败: %r' % txt[i])
        ports.append((m.group(1), m.group(2) or '', m.group(3)))
        i += 1
    if len(ports) != 153:
        raise SystemExit('只解析到 %d 个端口，与实测的 153 不符，拒绝生成' % len(ports))
    return ports


HEADER = r'''// =============================================================================
// RenameBuffer UT —— golden RenameBuffer 与重写 RenameBuffer_xs 双例化同激励，
// 逐拍比对全部 84 根输出端口。★本文件由 gen.py 生成，改激励请改 gen.py 再重跑★
//
// ★ 一、为什么要「暖机」，以及暖机之后必须做什么 ★
// RenameBuffer 有一大批**不带复位**的寄存器（256 项缓冲表 ×8 字段、walkPtr、
// vecLoadExcp_valid、6 组 toVecExcpMod 打拍寄存器，外加子模块里 4 个快照槽）。
// 上电随机（+vcs+initreg+random）时两个实例拿到的是**各自独立的随机值**，
// 逐拍比对必然一开始就炸 —— 这不是 bug，是这些位还没有被写过。
// 所以先跑一段**暖机**，把每一个不复位寄存器都至少写一次，之后才开比对：
//   暖机 A（~50 拍）：6 路全开、全都 needAlloc ⇒ 覆盖 256 项缓冲表一整圈；
//                      同时 snptEnq 连开 ⇒ 4 个快照槽全写一遍；
//   暖机 B（~40 拍）：灌一笔大 commitSize，再来一次「无快照重定向」⇒
//                      进 s_special_walk 且 vecLoadExcp_valid=1，
//                      6 路 toVecExcpMod 的 lreg/preg 全部被写；
//                      s_special_walk 结束进 s_walk ⇒ walkPtr 被写成确定值。
// ★暖机之后必须复核变异仍能被抓到★：暖机会把很多位洗成确定值，如果比对窗口
// 开得太晚，复位域的变异就可能被洗掉再也看不见。本 tb 的做法是：
//   **暖机结束后周期性打 reset 脉冲**（见 §RESET 与覆盖项 RST_PULSE：
//   每 2503 拍拉高 3 拍，200k 拍里约 237 个复位拍）。
//   那时所有不复位寄存器已经两侧一致，复位臂本身就落在比对窗口里 ——
//   「给 golden 没有复位的寄存器加复位」「改复位值」这两类变异因此可观测。
//   mutants.py 里的 M1/M2（复位值不是 0）与 M3（给不复位的缓冲表加复位）
//   就是专门打这条判据的。
//
// ★ 二、为什么激励不是「每个输入每拍独立均匀随机」★
// 这是一个 256 项循环队列 + 三状态回滚状态机 + 4 槽快照队列。判别力全在
// **边界与状态序列**上，纯随机走不到：
//   · 队列满 / 近满（allowEnqueue、allowEnqueueForDispatch 落 0）：要连续几十拍只进不出；
//   · 指针绕圈（enqPtr/deqPtr 的 flag 翻转、deqPtrOH 的 256 位循环左移绕回 bit0）：
//     要累计进出 256 条以上；
//   · s_walk 要靠 io_fromRob_walkEnd 才回得了 s_idle —— 纯随机里 walkEnd 只是
//     一根低概率的线，**不 pulse 就永远卡在 s_walk**，后面所有相位全部作废；
//   · s_special_walk 只能由「重定向 + useSnpt=0」进入，而它有没有意义
//     取决于此前攒了多少 commitSize；
//   · 快照队列满、以及 flushVec 打中有效槽后**重算 enqPtr** 那条路，
//     要求 snptEnq/snptDeq/flushVec 三者配合。
// 所以激励走一个**相位状态机**：FILL（只进不出）/ DRAIN（只出不进）/
// SNAP（快照进出与 flush）/ REDIR（重定向，两种 useSnpt 都打）/ RAND（全随机兜底），
// 每个相位随机长度，循环切换；重定向之后由 tb 侧的倒计时负责 pulse walkEnd。
// 相位是否真打到了这些状态，由文件末尾的 COVERAGE 段判定 —— 任何一项为 0
// 就判 TEST FAILED，不承认「随机跑了 200k 拍所以一定测到了」。
//
// ★ 三、覆盖统计只读 golden 侧 ★
// 所有层次引用都指向 dut_g（golden）。读重写侧会把「重写侧自己觉得到过」
// 当成覆盖证据，那是循环论证。
// =============================================================================
`timescale 1ns/1ps

module tb;

  // ---------------------------------------------------------------------------
  // 时钟 / 复位
  // ---------------------------------------------------------------------------
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  int unsigned ncycles = 200000;
  int unsigned cyc     = 0;
  int unsigned errors  = 0;
  int unsigned checked = 0;

  // 暖机窗口：期间**不比对**（不复位寄存器还没被写过）。
  localparam int WARM_CYCLES = 160;
  logic compare_en = 1'b0;
'''


def gen_decls(ports):
    L = ['', '  // --- 输入寄存器（两个 DUT 共用同一份激励） ---']
    for d, rng, n in ports:
        if n in ('clock', 'reset'):
            continue
        if d == 'input':
            L.append('  logic %-8s %s;' % (rng, n))
    L.append('')
    L.append('  // --- 输出线：g_ = golden，x_ = 重写 ---')
    for d, rng, n in ports:
        if d == 'output':
            L.append('  logic %-8s g_%s, x_%s;' % (rng, n, n))
    return '\n'.join(L)


def gen_inst(ports, mod, pfx):
    L = ['  %s %s (' % (mod, 'dut_g' if pfx == 'g_' else 'dut_x')]
    conns = []
    for d, rng, n in ports:
        if n in ('clock', 'reset'):
            conns.append('    .%-44s (%s)' % (n, n))
        elif d == 'input':
            conns.append('    .%-44s (%s)' % (n, n))
        else:
            conns.append('    .%-44s (%s%s)' % (n, pfx, n))
    L.append(',\n'.join(conns))
    L.append('  );')
    return '\n'.join(L)


def gen_compare(ports):
    L = ['  // --- 逐拍比对全部 84 根输出（本段由 gen.py 生成） ---',
         '  task automatic check_outputs();']
    for d, rng, n in ports:
        if d == 'output':
            L.append('    chk("%s", g_%s, x_%s);' % (n, n, n))
    L.append('  endtask')
    return '\n'.join(L)


BODY = r'''
  // ---------------------------------------------------------------------------
  // 比对
  // ---------------------------------------------------------------------------
  task automatic chk(string name, logic [31:0] gv, logic [31:0] xv);
    checked++;
    if (gv !== xv) begin
      errors++;
      if (errors <= 40)
        $display("[%0t] cyc=%0d MISMATCH %s: golden=%0h xs=%0h", $time, cyc, name, gv, xv);
    end
  endtask

  // ---------------------------------------------------------------------------
  // §STIM 激励 —— 相位状态机
  // ---------------------------------------------------------------------------
  typedef enum int {
    PH_FILL, PH_DRAIN, PH_SNAP, PH_REDIR, PH_RAND
  } phase_e;

  phase_e phase      = PH_FILL;
  int     phase_left = 0;
  // 重定向之后的倒计时：到 0 就 pulse walkEnd 把状态机拉回 s_idle。
  // ★没有这条，s_walk 是个吸收态，后面所有相位全废★
  int     walkend_cd = -1;

  function automatic logic chance(int pct);
    return ($urandom_range(0, 99) < pct);
  endfunction

  // 把一路 req 设成「有效且真的要占表项」或「无效」。
  task automatic set_req(int w, logic vld, logic need);
    logic [5:0] ld;  logic [7:0] pd;
    ld = $urandom_range(0, 63);
    pd = $urandom_range(0, 255);
    case (w)
      0: begin io_req_0_valid = vld; io_req_0_bits_ldest = ld; io_req_0_bits_pdest = pd;
               io_req_0_bits_rfWen = need & chance(70); io_req_0_bits_fpWen = need & chance(30);
               io_req_0_bits_vecWen= need & chance(30); io_req_0_bits_v0Wen = need & chance(20);
               io_req_0_bits_vlWen = need & chance(20); io_req_0_bits_isMove= chance(20);
               if (need && !(io_req_0_bits_rfWen|io_req_0_bits_fpWen|io_req_0_bits_vecWen
                            |io_req_0_bits_v0Wen|io_req_0_bits_vlWen)) io_req_0_bits_rfWen = 1'b1;
               if (!need) begin io_req_0_bits_rfWen=0; io_req_0_bits_fpWen=0;
                                io_req_0_bits_vecWen=0; io_req_0_bits_v0Wen=0;
                                io_req_0_bits_vlWen=0; end end
      1: begin io_req_1_valid = vld; io_req_1_bits_ldest = ld; io_req_1_bits_pdest = pd;
               io_req_1_bits_rfWen = need & chance(70); io_req_1_bits_fpWen = need & chance(30);
               io_req_1_bits_vecWen= need & chance(30); io_req_1_bits_v0Wen = need & chance(20);
               io_req_1_bits_vlWen = need & chance(20); io_req_1_bits_isMove= chance(20);
               if (need && !(io_req_1_bits_rfWen|io_req_1_bits_fpWen|io_req_1_bits_vecWen
                            |io_req_1_bits_v0Wen|io_req_1_bits_vlWen)) io_req_1_bits_rfWen = 1'b1;
               if (!need) begin io_req_1_bits_rfWen=0; io_req_1_bits_fpWen=0;
                                io_req_1_bits_vecWen=0; io_req_1_bits_v0Wen=0;
                                io_req_1_bits_vlWen=0; end end
      2: begin io_req_2_valid = vld; io_req_2_bits_ldest = ld; io_req_2_bits_pdest = pd;
               io_req_2_bits_rfWen = need & chance(70); io_req_2_bits_fpWen = need & chance(30);
               io_req_2_bits_vecWen= need & chance(30); io_req_2_bits_v0Wen = need & chance(20);
               io_req_2_bits_vlWen = need & chance(20); io_req_2_bits_isMove= chance(20);
               if (need && !(io_req_2_bits_rfWen|io_req_2_bits_fpWen|io_req_2_bits_vecWen
                            |io_req_2_bits_v0Wen|io_req_2_bits_vlWen)) io_req_2_bits_rfWen = 1'b1;
               if (!need) begin io_req_2_bits_rfWen=0; io_req_2_bits_fpWen=0;
                                io_req_2_bits_vecWen=0; io_req_2_bits_v0Wen=0;
                                io_req_2_bits_vlWen=0; end end
      3: begin io_req_3_valid = vld; io_req_3_bits_ldest = ld; io_req_3_bits_pdest = pd;
               io_req_3_bits_rfWen = need & chance(70); io_req_3_bits_fpWen = need & chance(30);
               io_req_3_bits_vecWen= need & chance(30); io_req_3_bits_v0Wen = need & chance(20);
               io_req_3_bits_vlWen = need & chance(20); io_req_3_bits_isMove= chance(20);
               if (need && !(io_req_3_bits_rfWen|io_req_3_bits_fpWen|io_req_3_bits_vecWen
                            |io_req_3_bits_v0Wen|io_req_3_bits_vlWen)) io_req_3_bits_rfWen = 1'b1;
               if (!need) begin io_req_3_bits_rfWen=0; io_req_3_bits_fpWen=0;
                                io_req_3_bits_vecWen=0; io_req_3_bits_v0Wen=0;
                                io_req_3_bits_vlWen=0; end end
      4: begin io_req_4_valid = vld; io_req_4_bits_ldest = ld; io_req_4_bits_pdest = pd;
               io_req_4_bits_rfWen = need & chance(70); io_req_4_bits_fpWen = need & chance(30);
               io_req_4_bits_vecWen= need & chance(30); io_req_4_bits_v0Wen = need & chance(20);
               io_req_4_bits_vlWen = need & chance(20); io_req_4_bits_isMove= chance(20);
               if (need && !(io_req_4_bits_rfWen|io_req_4_bits_fpWen|io_req_4_bits_vecWen
                            |io_req_4_bits_v0Wen|io_req_4_bits_vlWen)) io_req_4_bits_rfWen = 1'b1;
               if (!need) begin io_req_4_bits_rfWen=0; io_req_4_bits_fpWen=0;
                                io_req_4_bits_vecWen=0; io_req_4_bits_v0Wen=0;
                                io_req_4_bits_vlWen=0; end end
      5: begin io_req_5_valid = vld; io_req_5_bits_ldest = ld; io_req_5_bits_pdest = pd;
               io_req_5_bits_rfWen = need & chance(70); io_req_5_bits_fpWen = need & chance(30);
               io_req_5_bits_vecWen= need & chance(30); io_req_5_bits_v0Wen = need & chance(20);
               io_req_5_bits_vlWen = need & chance(20); io_req_5_bits_isMove= chance(20);
               if (need && !(io_req_5_bits_rfWen|io_req_5_bits_fpWen|io_req_5_bits_vecWen
                            |io_req_5_bits_v0Wen|io_req_5_bits_vlWen)) io_req_5_bits_rfWen = 1'b1;
               if (!need) begin io_req_5_bits_rfWen=0; io_req_5_bits_fpWen=0;
                                io_req_5_bits_vecWen=0; io_req_5_bits_v0Wen=0;
                                io_req_5_bits_vlWen=0; end end
    endcase
  endtask

  task automatic all_req(logic vld, logic need);
    for (int w = 0; w < 6; w++) set_req(w, vld, need);
  endtask

  task automatic idle_inputs();
    all_req(1'b0, 1'b0);
    io_redirect_valid            = 1'b0;
    io_fromRob_walkSize          = '0;
    io_fromRob_walkEnd           = 1'b0;
    io_fromRob_commitSize        = '0;
    io_fromRob_vecLoadExcp_valid = 1'b0;
    io_snpt_snptEnq              = 1'b0;
    io_snpt_snptDeq              = 1'b0;
    io_snpt_useSnpt              = 1'b0;
    io_snpt_snptSelect           = '0;
    io_snpt_flushVec_0           = 1'b0;
    io_snpt_flushVec_1           = 1'b0;
    io_snpt_flushVec_2           = 1'b0;
    io_snpt_flushVec_3           = 1'b0;
  endtask

  // 一次重定向脉冲。use_snpt=1 → 走快照直接进 s_walk；
  // use_snpt=0 → 进 s_special_walk（把攒下的 commitSize 转成 specialWalkSize）。
  task automatic do_redirect(logic use_snpt, logic vec_excp);
    io_redirect_valid            = 1'b1;
    io_snpt_useSnpt              = use_snpt;
    io_snpt_snptSelect           = $urandom_range(0, 3);
    io_fromRob_vecLoadExcp_valid = vec_excp;
    walkend_cd                   = $urandom_range(2, 40);
  endtask

  // ---------------------------------------------------------------------------
  // §WARM 暖机序列（见文件头 一）
  // ---------------------------------------------------------------------------
  task automatic warm_drive(int c);
    idle_inputs();
    if (c < 60) begin
      // A：6 路全开全占 ⇒ 写满 256 项缓冲表（6×60=360 > 256）
      all_req(1'b1, 1'b1);
      io_snpt_snptEnq = (c < 8);          // 4 个快照槽写满（满了自动丢弃）
    end else if (c == 70) begin
      io_fromRob_commitSize = 8'd120;     // 攒一笔待提交
    end else if (c == 74) begin
      // B：无快照重定向 + vecLoadExcp ⇒ 进 s_special_walk，6 路 toVecExcpMod 全写
      do_redirect(1'b0, 1'b1);
    end else if (c == 120) begin
      io_fromRob_walkEnd = 1'b1;          // 把 s_walk 收回 s_idle
    end else if (c > 130 && c < 140) begin
      io_snpt_snptDeq = 1'b1;             // 把快照槽放掉，回到干净状态
    end
  endtask

  // ---------------------------------------------------------------------------
  // §DRIVE 主激励
  // ---------------------------------------------------------------------------
  task automatic drive();
    idle_inputs();

    if (phase_left <= 0) begin
      case ($urandom_range(0, 9))
        0, 1:    phase = PH_FILL;
        2, 3:    phase = PH_DRAIN;
        4, 5:    phase = PH_SNAP;
        6, 7, 8: phase = PH_REDIR;
        default: phase = PH_RAND;
      endcase
      phase_left = $urandom_range(20, 300);
    end
    phase_left--;

    case (phase)
      PH_FILL: begin
        all_req(1'b1, chance(90));
        if (chance(3))  io_snpt_snptEnq = 1'b1;
        if (chance(2))  io_fromRob_commitSize = $urandom_range(0, 6);
      end
      PH_DRAIN: begin
        // 偶尔灌一笔大的，让 deqPtr / deqPtrOH 绕满一整圈
        if (chance(8))  io_fromRob_commitSize = chance(20) ? 8'd200 : $urandom_range(1, 12);
        if (chance(10)) io_snpt_snptDeq = 1'b1;
      end
      PH_SNAP: begin
        for (int w = 0; w < 6; w++) set_req(w, chance(50), chance(80));
        io_snpt_snptEnq    = chance(35);
        io_snpt_snptDeq    = chance(25);
        io_snpt_flushVec_0 = chance(12);
        io_snpt_flushVec_1 = chance(12);
        io_snpt_flushVec_2 = chance(12);
        io_snpt_flushVec_3 = chance(12);
        if (chance(5)) io_fromRob_commitSize = $urandom_range(0, 8);
      end
      PH_REDIR: begin
        for (int w = 0; w < 6; w++) set_req(w, chance(40), chance(80));
        if (chance(6)) io_fromRob_commitSize = $urandom_range(0, 30);
        if (chance(12)) do_redirect(chance(50), chance(60));
        io_snpt_snptEnq = chance(15);
        io_snpt_snptDeq = chance(10);
      end
      default: begin   // PH_RAND
        for (int w = 0; w < 6; w++) set_req(w, chance(50), chance(70));
        io_redirect_valid            = chance(3);
        io_snpt_useSnpt              = chance(50);
        io_snpt_snptSelect           = $urandom_range(0, 3);
        io_fromRob_walkSize          = chance(10) ? $urandom_range(0, 20) : '0;
        io_fromRob_walkEnd           = chance(5);
        io_fromRob_commitSize        = chance(10) ? $urandom_range(0, 20) : '0;
        io_fromRob_vecLoadExcp_valid = chance(20);
        io_snpt_snptEnq              = chance(10);
        io_snpt_snptDeq              = chance(10);
        io_snpt_flushVec_0           = chance(3);
        io_snpt_flushVec_1           = chance(3);
        io_snpt_flushVec_2           = chance(3);
        io_snpt_flushVec_3           = chance(3);
        if (io_redirect_valid) walkend_cd = $urandom_range(2, 40);
      end
    endcase

    // s_walk 的出口：重定向之后倒计时到点就 pulse walkEnd（walkSize=0）。
    // 中途也零星灌一点 walkSize，让 walk 真的走几拍而不是一拍就完。
    if (walkend_cd > 0) begin
      walkend_cd--;
      if (chance(25)) io_fromRob_walkSize = $urandom_range(1, 10);
    end else if (walkend_cd == 0) begin
      io_fromRob_walkEnd  = 1'b1;
      io_fromRob_walkSize = '0;
      walkend_cd          = -1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // §RESET 暖机后的复位脉冲（见文件头 一：复位窗口必须落在比对窗口里）
  // ---------------------------------------------------------------------------
  // ★周期性★ 每 RST_PERIOD 拍拉高 3 拍（暖机后 1000 拍起）。
  // 一开始只打了 3 次固定点，SnapshotGenerator 那条同形的复位域变异只报出
  // **26 个** error —— 换个 seed 就可能漏。判据是「余量薄的要点名」，
  // 于是改成周期性：200k 拍里约 80 次复位事件，复位臂被反复观测。
  // 周期取 2503（质数，避开与相位长度共振），两次复位之间有两千多拍，
  // 足够把指针绕圈 / 队列灌满这些深状态重新走一遍（覆盖数据见 run_*.log）。
  localparam int RST_PERIOD = 2503;
  function automatic logic want_reset(int unsigned c);
    return (c > WARM_CYCLES + 1000) && ((c % RST_PERIOD) < 3);
  endfunction
'''


COVERAGE = r'''
  // ---------------------------------------------------------------------------
  // §COV 覆盖事件 —— 全部读 golden 侧（dut_g）内部状态
  // ---------------------------------------------------------------------------
  int unsigned cov_state [3];          // 三个状态各停留多少拍
  int unsigned cov_trans [3][3];       // (state, stateNext) 转移
  int unsigned cov_full;               // allowEnqueue 落 0（队列满）
  int unsigned cov_dispatch_band;      // allowEnqForDispatch=0 而 allowEnq=1
  int unsigned cov_enq_flag [2];       // enqPtr.flag 两种取值
  int unsigned cov_deq_flag [2];       // deqPtr.flag 两种取值
  int unsigned cov_oh_high;            // deqPtrOH 落在 bit>=250
  int unsigned cov_oh_zero;            // deqPtrOH 回到 bit0（绕完一圈）
  int unsigned cov_walkptr_high;       // walkPtr 走到 >=250
  int unsigned cov_enqcnt [7];         // 本拍 needAlloc 的路数 0..6
  int unsigned cov_commit5, cov_walk5; // 第 6 路提交 / 回滚也有效
  int unsigned cov_snpt_full;          // 4 个快照槽同时有效
  int unsigned cov_snpt_drop;          // 快照队满时 snptEnq 被丢
  int unsigned cov_snpt_repair;        // flush 打中有效槽 ⇒ 重算 snptEnqPtr
  int unsigned cov_snptsel [4];        // 取快照那一拍用的是哪一号
  int unsigned cov_vexcp [6];          // toVecExcpMod 六路各自出过 valid
  int unsigned cov_vecexcp_set, cov_vecexcp_clr;
  int unsigned cov_rst_pulse;          // 暖机后的 reset 脉冲拍数

  logic [1:0] prev_state;
  logic       prev_reset;
  int unsigned enq_cnt_now;

  task automatic sample_cov();
    logic [3:0] snpt_valids, snpt_flush;
    logic       take_snapshot;
    cov_state[dut_g.state]++;
    cov_trans[dut_g.state][dut_g.stateNext]++;
    if (!dut_g.allowEnqueue_last_REG) cov_full++;
    if (!dut_g.allowEnqueueForDispatch_last_REG && dut_g.allowEnqueue_last_REG)
      cov_dispatch_band++;
    cov_enq_flag[dut_g.enqPtrVec_0_flag]++;
    cov_deq_flag[dut_g.deqPtrVec_0_flag]++;
    if (dut_g.deqPtrOH[255:250] != 6'h0) cov_oh_high++;
    if (dut_g.deqPtrOH[0])               cov_oh_zero++;
    if (dut_g.walkPtr_value >= 8'd250)   cov_walkptr_high++;

    enq_cnt_now = dut_g.realNeedAlloc_0 + dut_g.realNeedAlloc_1 + dut_g.realNeedAlloc_2
                + dut_g.realNeedAlloc_3 + dut_g.realNeedAlloc_4 + dut_g.realNeedAlloc_5;
    cov_enqcnt[enq_cnt_now]++;

    if (g_io_commits_commitValid_5) cov_commit5++;
    if (g_io_commits_walkValid_5)   cov_walk5++;

    snpt_valids = {dut_g.walkPtrSnapshots_snapshotGen.snptValids_3,
                   dut_g.walkPtrSnapshots_snapshotGen.snptValids_2,
                   dut_g.walkPtrSnapshots_snapshotGen.snptValids_1,
                   dut_g.walkPtrSnapshots_snapshotGen.snptValids_0};
    snpt_flush  = {io_snpt_flushVec_3, io_snpt_flushVec_2,
                   io_snpt_flushVec_1, io_snpt_flushVec_0};
    if (snpt_valids == 4'hF) cov_snpt_full++;
    if (io_snpt_snptEnq && !io_redirect_valid
        && (dut_g.walkPtrSnapshots_snapshotGen.snptEnqPtr_flag
            != dut_g.walkPtrSnapshots_snapshotGen.snptDeqPtr_flag)
        && (dut_g.walkPtrSnapshots_snapshotGen.snptEnqPtr_value
            == dut_g.walkPtrSnapshots_snapshotGen.snptDeqPtr_value)) cov_snpt_drop++;
    if (|(snpt_flush & snpt_valids)) cov_snpt_repair++;

    // 「这一拍 walkPtrNext 取的是快照」= walkPtr 的两条 snapshot 通路之一
    take_snapshot = ((dut_g.state == 2'd0) && (dut_g.stateNext == 2'd2))
                 || ((dut_g.state == 2'd2) && io_snpt_useSnpt && io_redirect_valid);
    if (take_snapshot) cov_snptsel[io_snpt_snptSelect]++;

    if (g_io_toVecExcpMod_logicPhyRegMap_0_valid) cov_vexcp[0]++;
    if (g_io_toVecExcpMod_logicPhyRegMap_1_valid) cov_vexcp[1]++;
    if (g_io_toVecExcpMod_logicPhyRegMap_2_valid) cov_vexcp[2]++;
    if (g_io_toVecExcpMod_logicPhyRegMap_3_valid) cov_vexcp[3]++;
    if (g_io_toVecExcpMod_logicPhyRegMap_4_valid) cov_vexcp[4]++;
    if (g_io_toVecExcpMod_logicPhyRegMap_5_valid) cov_vexcp[5]++;
    if (dut_g.vecLoadExcp_valid) cov_vecexcp_set++;
    if (!dut_g.vecLoadExcp_valid && (dut_g.state == 2'd1)) cov_vecexcp_clr++;

    if (reset && cyc > WARM_CYCLES) cov_rst_pulse++;
  endtask

  int unsigned cov_fail = 0;
  task automatic need(string name, int unsigned v, int unsigned lo);
    $display("  %-28s %10d %s", name, v, (v >= lo) ? "" : "  <<< 覆盖不足");
    if (v < lo) cov_fail++;
  endtask

  task automatic report_cov();
    $display("--- COVERAGE (golden 侧内部状态统计) ---");
    need("state s_idle",          cov_state[0], 100);
    need("state s_special_walk",  cov_state[1], 100);
    need("state s_walk",          cov_state[2], 100);
    need("trans idle->idle",      cov_trans[0][0], 10);
    need("trans idle->swlk",      cov_trans[0][1], 10);
    need("trans idle->walk",      cov_trans[0][2], 10);
    need("trans swlk->swlk",      cov_trans[1][1], 10);
    need("trans swlk->walk",      cov_trans[1][2], 10);
    need("trans walk->idle",      cov_trans[2][0], 10);
    need("trans walk->swlk",      cov_trans[2][1], 10);
    need("trans walk->walk",      cov_trans[2][2], 10);
    need("queue full (allowEnq=0)",   cov_full, 20);
    need("dispatch band",             cov_dispatch_band, 20);
    need("enqPtr.flag=0",             cov_enq_flag[0], 100);
    need("enqPtr.flag=1",             cov_enq_flag[1], 100);
    need("deqPtr.flag=0",             cov_deq_flag[0], 100);
    need("deqPtr.flag=1",             cov_deq_flag[1], 100);
    need("deqPtrOH bit>=250",         cov_oh_high, 20);
    need("deqPtrOH bit0 (wrapped)",   cov_oh_zero, 20);
    need("walkPtr >= 250",            cov_walkptr_high, 20);
    need("enqCount=0",                cov_enqcnt[0], 50);
    need("enqCount=6",                cov_enqcnt[6], 50);
    need("commitValid[5]",            cov_commit5, 50);
    need("walkValid[5]",              cov_walk5, 50);
    need("snapshot queue full",       cov_snpt_full, 20);
    need("snapshot enq dropped",      cov_snpt_drop, 5);
    need("flush repairs snptEnqPtr",  cov_snpt_repair, 10);
    need("snptSelect=0 used",         cov_snptsel[0], 3);
    need("snptSelect=1 used",         cov_snptsel[1], 3);
    need("snptSelect=2 used",         cov_snptsel[2], 3);
    need("snptSelect=3 used",         cov_snptsel[3], 3);
    need("vecExcpMap[0] valid",       cov_vexcp[0], 5);
    need("vecExcpMap[1] valid",       cov_vexcp[1], 5);
    need("vecExcpMap[2] valid",       cov_vexcp[2], 5);
    need("vecExcpMap[3] valid",       cov_vexcp[3], 5);
    need("vecExcpMap[4] valid",       cov_vexcp[4], 5);
    need("vecExcpMap[5] valid",       cov_vexcp[5], 5);
    need("vecLoadExcp_valid=1",       cov_vecexcp_set, 50);
    need("vecLoadExcp cleared in swlk", cov_vecexcp_clr, 10);
    need("RST_PULSE 暖机后复位拍数",  cov_rst_pulse, 60);
  endtask

  // ---------------------------------------------------------------------------
  // 主循环
  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    idle_inputs();
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;

    for (cyc = 0; cyc < ncycles; cyc++) begin
      // ★比对与覆盖采样都放在**上升沿之前**（输入已稳定的那一刻）★
      // 采样点选错会静默失效：放在 posedge 之后采 (state, stateNext) 采到的是
      // 「用上一拍输入算出来的、下一拍不会发生的」转移；采 snptValids & flushVec
      // 更是必然为 0（flush 已经把 valid 清掉了）。首版就是这么写的，
      // 结果 idle->swlk / flush 修复 两项恒为 0 —— 覆盖闸把它抓了出来。
      @(negedge clock);
      reset = want_reset(cyc);
      if (cyc < WARM_CYCLES) warm_drive(cyc);
      else                   drive();
      #2;                                  // 让组合路径稳定
      if (cyc >= WARM_CYCLES) begin
        compare_en = 1'b1;
        check_outputs();
        sample_cov();
      end
      @(posedge clock);
      if (errors > 200) begin
        $display("错误过多，提前结束");
        break;
      end
    end

    report_cov();
    $display("cycles=%0d  compared=%0d  errors=%0d  cov_fail=%0d",
             cyc, checked, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else                              $display("TEST FAILED");
    $finish;
  end

endmodule
'''


def main():
    ports = parse_ports()
    out = (HEADER + '\n' + gen_decls(ports) + '\n\n'
           + '  // --- 双例化（本段由 gen.py 生成） ---\n'
           + gen_inst(ports, 'RenameBuffer', 'g_') + '\n\n'
           + gen_inst(ports, 'RenameBuffer_xs', 'x_') + '\n\n'
           + gen_compare(ports) + '\n'
           + BODY + COVERAGE)
    (HERE / 'tb.sv').write_text(out)
    print('gen.py: 写出 tb.sv（%d 端口）' % len(ports))
    return 0


if __name__ == '__main__':
    sys.exit(main())
