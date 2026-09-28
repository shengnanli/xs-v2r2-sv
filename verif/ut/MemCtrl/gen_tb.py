#!/usr/bin/env python3
"""MemCtrl UT tb 生成器：golden MemCtrl 与 MemCtrl_xs 双例化、层次探针比对。
两个目标（MemCtrl、WaitTable）都没有输出端口，比对对象只能是寄存器：
  MemCtrl 自己的 7 个打拍寄存器 + waittable 的 1024 项表/resetCounter/timeout 寄存器。
ssit 两侧例化同一份已签核可读件（RTL_GOLDEN_DEPS），不在此比对。
用法: python3 gen_tb.py [--check]
"""
import sys, pathlib
N = 1024
L = []
A = L.append
A("""// 自动生成：verif/ut/MemCtrl/gen_tb.py —— 勿手改（make gencheck 校验）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  int cov_timeout = 0, cov_upd_in_timeout = 0, cov_reset_pulse = 0, cov_sat = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;

  logic [4:0] lvpred_timeout;
  logic       upd_valid;
  logic [9:0] upd_waddr, upd_ldpc, upd_stpc;
  logic       ren_0, ren_1;
  logic [9:0] raddr_0, raddr_1;

  MemCtrl g (.clock(clk), .reset(rst), .io_csrCtrl_lvpred_timeout(lvpred_timeout),
    .io_memPredUpdate_valid(upd_valid), .io_memPredUpdate_waddr(upd_waddr),
    .io_memPredUpdate_ldpc(upd_ldpc), .io_memPredUpdate_stpc(upd_stpc),
    .io_mdpFoldPcVecVld_0(ren_0), .io_mdpFoldPcVecVld_1(ren_1),
    .io_mdpFlodPcVec_0(raddr_0), .io_mdpFlodPcVec_1(raddr_1));
  MemCtrl_xs i (.clock(clk), .reset(rst), .io_csrCtrl_lvpred_timeout(lvpred_timeout),
    .io_memPredUpdate_valid(upd_valid), .io_memPredUpdate_waddr(upd_waddr),
    .io_memPredUpdate_ldpc(upd_ldpc), .io_memPredUpdate_stpc(upd_stpc),
    .io_mdpFoldPcVecVld_0(ren_0), .io_mdpFoldPcVecVld_1(ren_1),
    .io_mdpFlodPcVec_0(raddr_0), .io_mdpFlodPcVec_1(raddr_1));

  // 折叠 PC：一半集中在 0..15（让同一项反复更新到饱和 11），一半全随机。
  function automatic logic [9:0] rand_pc();
    return ($urandom_range(0, 1)) ? 10'($urandom_range(0, 15)) : 10'($urandom);
  endfunction
  task automatic drive_random();
    ren_0 = 1'($urandom_range(0, 1)); ren_1 = 1'($urandom_range(0, 1));
    raddr_0 = rand_pc(); raddr_1 = rand_pc();
    upd_valid = ($urandom_range(0, 99) < 30);
    upd_waddr = rand_pc(); upd_ldpc = rand_pc();
    upd_stpc  = ($urandom_range(0, 99) < 25) ? upd_ldpc : rand_pc();
    // 偶尔换衰减周期：多数取 0..3（20 万拍内反复超时），少数全随机（>=10 移空那支）。
    if ($urandom_range(0, 999) < 5)
      lvpred_timeout = ($urandom_range(0, 99) < 80) ? 5'($urandom_range(0, 3)) : 5'($urandom);
  endtask

  `define CMP(NAME, GS, IS) \\
    if (GS !== IS) begin errors++; if (errors <= 40) $display("[%0t] %s g=%h i=%h", $time, NAME, GS, IS); end

  // 比对窗口：复位撤销后第 2 拍起（7 个无复位打拍寄存器在第 1 拍被写定）。
  always @(negedge clk) if (!rst && cyc > 2) begin
    #4; checks++;
    `CMP("ssit_update_valid",      g.ssit_io_update_REG_valid,             i.u_core.ssit_update_q_valid)
    `CMP("ssit_update_ldpc",       g.ssit_io_update_REG_ldpc,              i.u_core.ssit_update_q_ldpc)
    `CMP("ssit_update_stpc",       g.ssit_io_update_REG_stpc,              i.u_core.ssit_update_q_stpc)
    `CMP("waittable_update_valid", g.waittable_io_update_REG_valid,        i.u_core.waittable_update_q_valid)
    `CMP("waittable_update_waddr", g.waittable_io_update_REG_waddr,        i.u_core.waittable_update_q_waddr)
    `CMP("ssit_timeout",           g.ssit_io_csrCtrl_REG_lvpred_timeout,   i.u_core.ssit_timeout_q)
    `CMP("waittable_timeout",      g.waittable_io_csrCtrl_REG_lvpred_timeout, i.u_core.waittable_timeout_q)
    `CMP("wt.resetCounter",        g.waittable.resetCounter,               i.u_core.waittable.u_core.resetCounter)
    `CMP("wt.REG",                 g.waittable.REG,                        i.u_core.waittable.u_core.timeout_q)""")
for k in range(N):
    A(f'    `CMP("wt.data_{k}", g.waittable.data_{k}, i.u_core.waittable.u_core.data[{k}])')
A("""    if (g.waittable._GEN_9[0]) begin cov_timeout++; if (g.waittable_io_update_REG_valid) cov_upd_in_timeout++; end
    if (g.waittable.data_3 == 2'b11) cov_sat++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    ren_0 = 0; ren_1 = 0; raddr_0 = 0; raddr_1 = 0;
    upd_valid = 0; upd_waddr = 0; upd_ldpc = 0; upd_stpc = 0;
    lvpred_timeout = 5'h0;
    rst = 1'b1; repeat (4) @(posedge clk); @(negedge clk) rst = 1'b0;
    for (int unsigned n = 0; n < NCYCLES / 2; n++) begin drive_random(); @(negedge clk); end
    // 中途异步复位：data/resetCounter 有复位、7 个打拍寄存器与 REG 没有 —— 复位域检验。
    upd_valid = 0; @(negedge clk) rst = 1'b1; cov_reset_pulse++;
    repeat (3) @(posedge clk); @(negedge clk) rst = 1'b0;
    for (int unsigned n = 0; n < NCYCLES / 2; n++) begin drive_random(); @(negedge clk); end
    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  超时整表清零        : %0d", cov_timeout);
    $display("  更新与清零同拍      : %0d", cov_upd_in_timeout);
    $display("  计数器饱和到 11     : %0d", cov_sat);
    $display("  中途异步复位        : %0d", cov_reset_pulse);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_timeout > 0 && cov_upd_in_timeout > 0 && cov_sat > 0)
      $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
text = "\n".join(L)
out = pathlib.Path(__file__).with_name("tb.sv")
if "--check" in sys.argv:
    sys.exit(0 if out.exists() and out.read_text() == text else 1)
out.write_text(text); print("wrote", out)
