#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— 生成 verif/ut/SSIT/tb.sv。

为什么要生成而不是手写：SSIT 的可观测状态里有三组 1024 项的影子数组，golden 侧
被 firtool 展平成 `debug_valid_0 … debug_valid_1023` 这样的**平坦名**，没法用
genvar 索引，只能逐条写层次引用。3072 条引用手写不现实，也没法维护，所以这里生成。
重写侧是 packed 数组，一行就够，不用生成。

用法: python3 gen.py   （或 make tb）
"""
import pathlib

N = 1024
HERE = pathlib.Path(__file__).resolve().parent

HEAD = r'''// =============================================================================
// SSIT UT —— golden SSIT 与重写 SSIT_xs 双例化逐拍比对
//
// ★ 这个 UT 为什么长得跟别的不一样 ★
// SSIT **没有任何输出端口**（golden 10 个端口全是 input —— io.rdata 被 firtool
// -O=release 整条裁掉了）。于是「逐拍比全部输出」在这里等于什么都不比。本 UT 改为
// 比**完整的可观测状态 + 两块子存储的全部接口引脚**：
//   (a) 两块 SyncDataModuleTemplate 实例的全部输入引脚（ren/raddr/wen/waddr/wdata）
//       —— 这才是 SSIT 真正的“输出”；
//   (b) 它们的读回数据（rdata）—— 证明两侧存储内容一致；
//   (c) SSIT 自己的全部寄存器：state / resetCounter / resetStepCounter / REG /
//       s1_* / s2_*，以及 3×1024 项影子数组 debug_valid/ssid/strict。
// 两侧的子存储用的是**同一份 golden 定义**（Makefile 的 RTL_GOLDEN_DEPS），
// 各自例化一份，所以 (b) 的比对是有意义的（内容不同就会分叉）。
//
// ★ 暖机：不复位寄存器必须先写成确定值 ★
// golden 只有 debug_valid/resetCounter/resetStepCounter/state 带异步复位；
// debug_ssid[1024]、debug_strict[1024]、REG、s1_*、s2_*，以及两块子存储里的
// 1024 项数据与各读写地址副本寄存器，**统统不复位**。`+vcs+initreg+random` 会给
// 两个实例各自抽一份**不同**的随机初值，不暖机就会报一大片假失配。暖机分两段：
//   A 段（约 1100 拍）：复位后 state 就是 s_flush，让它把 valid_array 整表清一遍；
//                       期间 ren 常 1，把子存储里的读地址副本寄存器也写成确定值。
//                       ★此间不发 update★：update 会读到尚未确定的 data_array。
//   B 段（1024 拍）：ldpc=stpc=i 逐项扫一遍。两侧都没 valid → 情形 00 → 每项被
//                    写成 {valid=1, ssid=XORFold(i), strict=0}，data_array 与影子
//                    数组同时变确定；s1_*/s2_*/REG 也在这段里被写。
//   C 段（再来 1024 拍同样的扫描）★这一段不是冗余，是实测补上的★：
//     B 段里每次更新**先读后写**同一项，读到的是那一项**写之前**的内容 —— 也就是
//     data_array 的上电随机值。于是 B 段跑完，s2_loadOldSSID / s2_storeOldSSID /
//     s2_loadStrict 这三个寄存器里留着的是「最后一项的随机旧值」，两侧不同。
//     实测（2026-09-17，本文件上一版）：initreg=0 三个 seed 全绿、initreg=random
//     的 seed 7 报 9 个、seed 42 报 6 个失配，全部落在打开比对后的头 3 拍、
//     全部就是这三个寄存器，之后自愈。C 段再扫一遍时读到的已是 B 段写进去的确定值，
//     这三个寄存器才跟着变确定。
//     ★这正是 CONVENTIONS 里「两轮 initreg」要抓的东西：只跑 initreg=0 那一轮，
//       这个暖机漏洞会一直看不见。★
// 暖机之后才打开比对。**暖机会不会把判别力一起暖没**：由 mutants.py 回答
// （10 个变异全部在暖机之后的窗口里被抓到）。
//
// ★ 中途再来一次异步复位 ★
// 这是复位域的针对性检验：golden 复位时 debug_ssid/debug_strict **不动**。若重写
// 件好心给它们补了复位，两侧当场分叉。反过来，若漏掉 debug_valid 的复位也当场分叉。
//
// ★ 定向激励（纯随机打不到的边界）★
//   - ldpc == stpc（同一项被 load/store 两侧同时更新）：25% 概率强制相等。
//   - 更新撞上冲刷指针：25% 的 PC 取值直接取自 golden 当前的 resetStepCounter
//     （更新要两拍才到 s2，所以取 +0..+4 的偏移覆盖对齐窗口）。这条打的是两个
//     真实 hazard：写口 0 被 load 更新抢走导致本拍冲刷丢失；以及写口 1 因为
//     「与写口 0 同址」被压掉——而写口 0 的地址在冲刷时是 resetStepCounter。
//   - lvpred_timeout 取 0..3 的小值，让整表冲刷反复发生（取大值就几乎不冲刷）。
//
// 本文件由 gen.py 生成（3072 条 golden 侧影子数组层次引用），勿手改。
// =============================================================================
`timescale 1ns/1ps

`define CHK(NM, A, B) \
  begin \
    checks++; \
    if ((A) !== (B)) begin \
      errors++; \
      if (errors <= 20) \
        $display("MISMATCH cyc=%0d %s golden=%0h impl=%0h", cyc, NM, (A), (B)); \
    end \
  end

module tb;

  localparam int N = 1024;

  int unsigned NCYCLES = 200000;
  bit    clk = 1'b0;
  logic  rst;
  int    errors = 0;
  longint checks = 0;
  longint cyc = 0;
  bit    compare_on = 1'b0;

  always #5 clk = ~clk;
  always @(posedge clk) cyc++;

  // ---- 激励 ----------------------------------------------------------------
  logic        ren_0, ren_1;
  logic [9:0]  raddr_0, raddr_1;
  logic        upd_valid;
  logic [9:0]  upd_ldpc, upd_stpc;
  logic [4:0]  lvpred_timeout;

  SSIT g (
    .clock                     (clk),
    .reset                     (rst),
    .io_ren_0                  (ren_0),
    .io_ren_1                  (ren_1),
    .io_raddr_0                (raddr_0),
    .io_raddr_1                (raddr_1),
    .io_update_valid           (upd_valid),
    .io_update_ldpc            (upd_ldpc),
    .io_update_stpc            (upd_stpc),
    .io_csrCtrl_lvpred_timeout (lvpred_timeout)
  );

  SSIT_xs x (
    .clock                     (clk),
    .reset                     (rst),
    .io_ren_0                  (ren_0),
    .io_ren_1                  (ren_1),
    .io_raddr_0                (raddr_0),
    .io_raddr_1                (raddr_1),
    .io_update_valid           (upd_valid),
    .io_update_ldpc            (upd_ldpc),
    .io_update_stpc            (upd_stpc),
    .io_csrCtrl_lvpred_timeout (lvpred_timeout)
  );

  // ---- 影子数组探针（golden 侧逐项，重写侧 packed 一行）--------------------
  logic [N-1:0]       g_valid,  x_valid;
  logic [N-1:0][4:0]  g_ssid,   x_ssid;
  logic [N-1:0]       g_strict, x_strict;

  assign x_valid  = x.u_core.debug_valid;
  assign x_ssid   = x.u_core.debug_ssid;
  assign x_strict = x.u_core.debug_strict;

'''

TAIL = r'''
  // ---- 比对 ----------------------------------------------------------------
  // 在 negedge 比：此刻 posedge 的次态已经稳定，且与激励驱动（也在 negedge）互不
  // 依赖——比的全是 DUT 内部状态与子实例引脚，不读激励变量。
  always @(negedge clk) if (compare_on) begin
    // (a) valid_array 的全部输入引脚 = SSIT 对这块存储的“输出”
    `CHK("va.ren_0",   g.valid_array.io_ren_0,   x.u_core.valid_array.io_ren_0)
    `CHK("va.ren_1",   g.valid_array.io_ren_1,   x.u_core.valid_array.io_ren_1)
    `CHK("va.raddr_0", g.valid_array.io_raddr_0, x.u_core.valid_array.io_raddr_0)
    `CHK("va.raddr_1", g.valid_array.io_raddr_1, x.u_core.valid_array.io_raddr_1)
    `CHK("va.wen_0",   g.valid_array.io_wen_0,   x.u_core.valid_array.io_wen_0)
    `CHK("va.wen_1",   g.valid_array.io_wen_1,   x.u_core.valid_array.io_wen_1)
    `CHK("va.waddr_0", g.valid_array.io_waddr_0, x.u_core.valid_array.io_waddr_0)
    `CHK("va.waddr_1", g.valid_array.io_waddr_1, x.u_core.valid_array.io_waddr_1)
    `CHK("va.wdata_0", g.valid_array.io_wdata_0, x.u_core.valid_array.io_wdata_0)
    `CHK("va.wdata_1", g.valid_array.io_wdata_1, x.u_core.valid_array.io_wdata_1)
    // (b) 读回数据：两侧各有一份子存储，内容分叉就会在这里暴露
    `CHK("va.rdata_0", g.valid_array.io_rdata_0, x.u_core.valid_array.io_rdata_0)
    `CHK("va.rdata_1", g.valid_array.io_rdata_1, x.u_core.valid_array.io_rdata_1)

    `CHK("da.ren_0",          g.data_array.io_ren_0,          x.u_core.data_array.io_ren_0)
    `CHK("da.ren_1",          g.data_array.io_ren_1,          x.u_core.data_array.io_ren_1)
    `CHK("da.raddr_0",        g.data_array.io_raddr_0,        x.u_core.data_array.io_raddr_0)
    `CHK("da.raddr_1",        g.data_array.io_raddr_1,        x.u_core.data_array.io_raddr_1)
    `CHK("da.wen_0",          g.data_array.io_wen_0,          x.u_core.data_array.io_wen_0)
    `CHK("da.wen_1",          g.data_array.io_wen_1,          x.u_core.data_array.io_wen_1)
    `CHK("da.waddr_0",        g.data_array.io_waddr_0,        x.u_core.data_array.io_waddr_0)
    `CHK("da.waddr_1",        g.data_array.io_waddr_1,        x.u_core.data_array.io_waddr_1)
    `CHK("da.wdata_0_ssid",   g.data_array.io_wdata_0_ssid,   x.u_core.data_array.io_wdata_0_ssid)
    `CHK("da.wdata_0_strict", g.data_array.io_wdata_0_strict, x.u_core.data_array.io_wdata_0_strict)
    `CHK("da.wdata_1_ssid",   g.data_array.io_wdata_1_ssid,   x.u_core.data_array.io_wdata_1_ssid)
    `CHK("da.rdata_0_ssid",   g.data_array.io_rdata_0_ssid,   x.u_core.data_array.io_rdata_0_ssid)
    `CHK("da.rdata_0_strict", g.data_array.io_rdata_0_strict, x.u_core.data_array.io_rdata_0_strict)
    `CHK("da.rdata_1_ssid",   g.data_array.io_rdata_1_ssid,   x.u_core.data_array.io_rdata_1_ssid)

    // (c) SSIT 自己的寄存器
    `CHK("state",       g.state,            x.u_core.state)
    `CHK("resetCnt",    g.resetCounter,     x.u_core.reset_counter)
    `CHK("resetStep",   g.resetStepCounter, x.u_core.reset_step)
    `CHK("timeout_q",   g.REG,              x.u_core.timeout_q)
    `CHK("s1_valid",    g.s1_mempred_update_req_valid, x.u_core.s1_valid)
    `CHK("s1_ldpc",     g.s1_mempred_update_req_ldpc,  x.u_core.s1_ldpc)
    `CHK("s1_stpc",     g.s1_mempred_update_req_stpc,  x.u_core.s1_stpc)
    `CHK("s2_valid",    g.s2_mempred_update_req_valid, x.u_core.s2_valid)
    `CHK("s2_ldpc",     g.s2_ldSsidAllocate_value,     x.u_core.s2_ldpc)
    `CHK("s2_stpc",     g.s2_stSsidAllocate_value,     x.u_core.s2_stpc)
    `CHK("s2_ldAssign", g.s2_loadAssigned,   x.u_core.s2_load_assigned)
    `CHK("s2_stAssign", g.s2_storeAssigned,  x.u_core.s2_store_assigned)
    `CHK("s2_ldOldSsid",g.s2_loadOldSSID,    x.u_core.s2_load_old_ssid)
    `CHK("s2_stOldSsid",g.s2_storeOldSSID,   x.u_core.s2_store_old_ssid)
    `CHK("s2_ldStrict", g.s2_loadStrict,     x.u_core.s2_load_strict)

    // (d) 3×1024 影子数组（打包成向量比，一次三条）
    `CHK("debug_valid",  g_valid,  x_valid)
    `CHK("debug_ssid",   g_ssid,   x_ssid)
    `CHK("debug_strict", g_strict, x_strict)
  end

  // ---- 覆盖统计（全部从 golden 侧读，重写件错了也不会把统计一起带偏）--------
  longint cov_sel[4];              // s2 四种情形各出现多少次
  longint cov_same_pc     = 0;     // ldpc == stpc（同一项被两侧同时更新）
  longint cov_upd_in_flush = 0;    // 更新与冲刷同拍（写口 0 被抢，本拍冲刷丢失）
  longint cov_st_eaten_ld = 0;     // 写口 1 被「与写口 0 同址」压掉（同址来自 ldpc）
  longint cov_st_eaten_flush = 0;  // ★写口 1 被冲刷地址压掉★（只有 sel=10 时可能）
  longint cov_strict_set  = 0;     // 情形 4 且 ssid 本来就相同 → 置 strict
  longint cov_strict_fail = 0;     // 上一条且这条 load 的 strict 已经置着了
  longint cov_flush_done  = 0;     // 整表冲刷走完一轮
  longint cov_timeout     = 0;     // idle 里超时触发一次冲刷
  longint cov_read_preempt = 0;    // update 抢占 decode 读口
  longint cov_reset_pulse = 0;     // 中途异步复位次数
  longint cov_timeout_big = 0;     // lvpred_timeout >= 10（超时判据被移空的那一支）

  wire        gv   = g.s2_mempred_update_req_valid;
  wire [1:0]  gsel = {g.s2_loadAssigned, g.s2_storeAssigned};
  wire        g_wl = ~g.s2_loadAssigned | g.s2_storeAssigned;   // 写 load 侧
  wire        g_ws = ~g.s2_storeAssigned | g.s2_loadAssigned;   // 写 store 侧

  always @(negedge clk) if (compare_on) begin
    if (gv) begin
      cov_sel[gsel]++;
      if (g.s2_ldSsidAllocate_value == g.s2_stSsidAllocate_value) cov_same_pc++;
      if (g.state && g_wl) cov_upd_in_flush++;
      if (g_wl && g_ws &&
          g.s2_ldSsidAllocate_value == g.s2_stSsidAllocate_value) cov_st_eaten_ld++;
      if (!g_wl && g_ws && g.state &&
          g.resetStepCounter[9:0] == g.s2_stSsidAllocate_value) cov_st_eaten_flush++;
      if (gsel == 2'b11 && g.s2_loadOldSSID == g.s2_storeOldSSID) begin
        cov_strict_set++;
        if (g.s2_loadStrict) cov_strict_fail++;
      end
    end
    if (g.state && g.resetStepCounter == 11'h3FF) cov_flush_done++;
    if (!g.state && ((g.resetCounter[19:10] >> g.REG) & 10'h1)) cov_timeout++;
    if (upd_valid && (ren_0 || ren_1)) cov_read_preempt++;
    if (g.REG >= 5'd10) cov_timeout_big++;
  end

  // ---- 激励生成 ------------------------------------------------------------
  // PC 取值三段分布。中间那一段直接对准 golden 当前的冲刷指针：更新要两拍才走到
  // s2，所以取 +0..+4 覆盖对齐窗口——纯均匀随机的话 1/1024 的命中率在 20 万拍里
  // 只能凑出个位数次，那两个 hazard 等于没验。
  function automatic logic [9:0] rand_pc();
    int unsigned r = $urandom_range(0, 99);
    if (r < 25)      return 10'($urandom_range(0, 7));
    else if (r < 50) return 10'(g.resetStepCounter[9:0] + $urandom_range(0, 4));
    else             return 10'($urandom);
  endfunction

  task automatic drive_random();
    ren_0 = 1'($urandom_range(0, 1));
    ren_1 = 1'($urandom_range(0, 1));
    raddr_0 = rand_pc();
    raddr_1 = rand_pc();
    upd_valid = ($urandom_range(0, 99) < 25);
    upd_ldpc  = rand_pc();
    upd_stpc  = ($urandom_range(0, 99) < 25) ? upd_ldpc : rand_pc();
    // 偶尔换一次冲刷周期。多数时候取 0..3 的小值（保证 20 万拍里冲刷反复发生），
    // 少数时候取全 5 位随机：lvpred_timeout >= 10 时 `resetCounter[19:10] >> timeout`
    // 会把 10 位全移空、超时恒不成立，这一支也要走到，否则移位宽度抄错看不出来。
    if ($urandom_range(0, 999) < 5) begin
      lvpred_timeout = ($urandom_range(0, 99) < 80) ? 5'($urandom_range(0, 3))
                                                    : 5'($urandom);
    end
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    ren_0 = 1'b0; ren_1 = 1'b0; raddr_0 = '0; raddr_1 = '0;
    upd_valid = 1'b0; upd_ldpc = '0; upd_stpc = '0;
    lvpred_timeout = 5'h1F;   // 暖机期间关掉超时冲刷（移位 31 位后恒 0）

    rst = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) rst = 1'b0;

    // 暖机 A：让上电就位的 s_flush 把 valid_array 整表清完（1024 项），
    // 同时 ren 常 1 把子存储的读地址副本寄存器写成确定值。
    ren_0 = 1'b1; ren_1 = 1'b1;
    for (int i = 0; i < 1100; i++) begin
      @(negedge clk);
      raddr_0 = 10'(i);
      raddr_1 = 10'(N - 1 - i);
    end

    // 暖机 B + C：ldpc=stpc=i 逐项扫**两遍**。第一遍把 data_array 与三组影子数组
    // 写成确定值；第二遍让 s2_loadOldSSID/s2_storeOldSSID/s2_loadStrict 这三个
    // 「读回来的旧值」寄存器也拿到确定值（第一遍里它们读到的是写之前的随机内容，
    // 见文件头 C 段说明——漏掉这一遍，initreg=random 那轮会在头 3 拍报失配）。
    upd_valid = 1'b1;
    for (int pass = 0; pass < 2; pass++) begin
      for (int i = 0; i < N; i++) begin
        upd_ldpc = 10'(i);
        upd_stpc = 10'(i);
        raddr_0 = 10'(i);
        raddr_1 = 10'(i);
        @(negedge clk);
      end
    end
    upd_valid = 1'b0;
    repeat (8) @(negedge clk);

    compare_on = 1'b1;
    lvpred_timeout = 5'h0;

    // 主随机段（前半）
    for (int unsigned i = 0; i < NCYCLES / 2; i++) begin
      drive_random();
      @(negedge clk);
    end

    // 中途异步复位：复位域的针对性检验（见文件头）。
    upd_valid = 1'b0;
    @(negedge clk) rst = 1'b1;
    cov_reset_pulse++;
    repeat (3) @(posedge clk);
    @(negedge clk) rst = 1'b0;

    // 主随机段（后半）
    for (int unsigned i = 0; i < NCYCLES / 2; i++) begin
      drive_random();
      @(negedge clk);
    end

    $display("--- COVERAGE (每项必须 > 0，否则该机制没被激励到) ---");
    $display("  情形 00 两边都没 set  : %0d", cov_sel[0]);
    $display("  情形 01 只有 store 有 : %0d", cov_sel[1]);
    $display("  情形 10 只有 load  有 : %0d", cov_sel[2]);
    $display("  情形 11 两边都有      : %0d", cov_sel[3]);
    $display("  ldpc == stpc          : %0d", cov_same_pc);
    $display("  更新与冲刷同拍        : %0d", cov_upd_in_flush);
    $display("  写口1 被 ldpc 同址压掉: %0d", cov_st_eaten_ld);
    $display("  写口1 被冲刷地址压掉  : %0d", cov_st_eaten_flush);
    $display("  置 strict             : %0d", cov_strict_set);
    $display("  strict 已置还是撞了   : %0d", cov_strict_fail);
    $display("  整表冲刷走完一轮      : %0d", cov_flush_done);
    $display("  idle 超时触发冲刷     : %0d", cov_timeout);
    $display("  update 抢占读口       : %0d", cov_read_preempt);
    $display("  timeout>=10(移空那支)  : %0d", cov_timeout_big);
    $display("  中途异步复位          : %0d", cov_reset_pulse);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 &&
        cov_sel[0] > 0 && cov_sel[1] > 0 && cov_sel[2] > 0 && cov_sel[3] > 0 &&
        cov_same_pc > 0 && cov_upd_in_flush > 0 && cov_st_eaten_ld > 0 &&
        cov_st_eaten_flush > 0 && cov_strict_set > 0 && cov_strict_fail > 0 &&
        cov_flush_done > 0 && cov_timeout > 0 && cov_read_preempt > 0 &&
        cov_reset_pulse > 0 && cov_timeout_big > 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED (errors=%0d 或覆盖项为 0)", errors);
    $finish;
  end

endmodule
'''


def main():
    parts = [HEAD]
    parts.append('  // golden 侧影子数组：firtool 展平成 %d 个平坦名，只能逐条引。\n' % (3 * N))
    for i in range(N):
        parts.append('  assign g_valid[%d] = g.debug_valid_%d;\n' % (i, i))
    parts.append('\n')
    for i in range(N):
        parts.append('  assign g_ssid[%d] = g.debug_ssid_%d;\n' % (i, i))
    parts.append('\n')
    for i in range(N):
        parts.append('  assign g_strict[%d] = g.debug_strict_%d;\n' % (i, i))
    parts.append(TAIL)
    (HERE / 'tb.sv').write_text(''.join(parts))
    print('gen.py: wrote tb.sv (%d lines)' % len(''.join(parts).split('\n')))


if __name__ == '__main__':
    main()
