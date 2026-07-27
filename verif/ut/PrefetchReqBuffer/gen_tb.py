#!/usr/bin/env python3
# 生成 PrefetchReqBuffer 的 UT testbench: golden PrefetchReqBuffer vs 手写
# PrefetchReqBuffer_xs 双例化, 随机激励逐拍比对所有输出。两侧共用 golden
# RRArbiterInit_12/_13 定义(单定义两实例, 无撞名)。
# 复位后跳过 WARMUP 拍(SYNTHESIS 下寄存器复位到 0, 两侧同构)。
#
# 覆盖策略: 入站请求 vaddr/base/source/needT 取小域随机值 → 大量重复地址,
# 令 s0_conflict_prev / s0_match(合并去重)与 alloc(填满 16 槽后丢弃)频繁触发;
# tlb resp 混合 miss/hit/excp/pbmt-uncache 以覆盖 tlb_fired / miss_first_replay /
# miss_drop / exp_drop 路径; io_out_ready 多为高以触发 pf_fired 出队。
import sys

INPUTS = [
    ("io_in_req_valid", 1),
    ("io_in_req_bits_full_vaddr", 50),
    ("io_in_req_bits_base_vaddr", 44),
    ("io_in_req_bits_needT", 1),
    ("io_in_req_bits_source", 7),
    ("io_tlb_req_resp_valid", 1),
    ("io_tlb_req_resp_bits_paddr_0", 48),
    ("io_tlb_req_resp_bits_pbmt", 2),
    ("io_tlb_req_resp_bits_miss", 1),
    ("io_tlb_req_resp_bits_excp_0_gpf_ld", 1),
    ("io_tlb_req_resp_bits_excp_0_pf_ld", 1),
    ("io_tlb_req_resp_bits_excp_0_af_ld", 1),
    ("io_tlb_req_pmp_resp_ld", 1),
    ("io_tlb_req_pmp_resp_mmio", 1),
    ("io_out_req_ready", 1),
]

OUTPUTS = [
    ("io_tlb_req_req_valid", 1),
    ("io_tlb_req_req_bits_vaddr", 50),
    ("io_tlb_req_req_bits_cmd", 3),
    ("io_tlb_req_req_bits_kill", 1),
    ("io_tlb_req_req_bits_no_translate", 1),
    ("io_out_req_valid", 1),
    ("io_out_req_bits_tag", 33),
    ("io_out_req_bits_set", 9),
    ("io_out_req_bits_vaddr", 44),
    ("io_out_req_bits_needT", 1),
    ("io_out_req_bits_source", 7),
]


def decl(name, w):
    return f"logic [{w-1}:0] {name};" if w > 1 else f"logic {name};"


def wdecl(name, w):
    return f"wire [{w-1}:0] {name};" if w > 1 else f"wire {name};"


def port_map(names, prefix=""):
    return ",\n".join(f"    .{n}({prefix}{n})" for n in names)


def main():
    lines = []
    lines.append("// 自动生成: gen_tb.py —— 勿手改")
    lines.append("`timescale 1ns/1ps")
    lines.append("module tb;")
    lines.append("  int unsigned NCYCLES = 200000;")
    lines.append("  int unsigned WARMUP  = 8;")
    lines.append("  bit clk = 0, rst;")
    lines.append("  int errors = 0, checks = 0, cyc = 0;")
    lines.append("  always #5 clk = ~clk;")
    lines.append("")
    for n, w in INPUTS:
        lines.append("  " + decl(n, w))
    for n, w in OUTPUTS:
        lines.append("  " + wdecl("g_" + n, w))
        lines.append("  " + wdecl("i_" + n, w))
    lines.append("")

    # golden instance
    lines.append("  PrefetchReqBuffer dut_g (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="g_"))
    lines.append("  );")
    lines.append("")
    # impl instance
    lines.append("  PrefetchReqBuffer_xs dut_i (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="i_"))
    lines.append("  );")
    lines.append("")

    # stimulus
    lines.append("  // 随机激励: 小地址域 → 频繁去重/合并/填满; tlb resp 覆盖 miss/hit/excp")
    lines.append("  task automatic drive_random();")
    lines.append("    io_in_req_valid = ($random & 3) != 0; // 3/4 概率有请求")
    lines.append("    // 小地址域(低 5 位块号 + 固定高位) → 频繁命中已有条目 / 相邻拍冲突")
    lines.append("    io_in_req_bits_full_vaddr = {44'h0, ($random & 5'h1F), 1'b0};")
    lines.append("    io_in_req_bits_base_vaddr = {40'h0, ($random & 4'hF)};")
    lines.append("    io_in_req_bits_needT      = $random;")
    lines.append("    io_in_req_bits_source     = $random & 7'h3;")
    lines.append("    // tlb resp: 混合 miss / hit / 各类异常")
    lines.append("    io_tlb_req_resp_valid = ($random & 1);")
    lines.append("    io_tlb_req_resp_bits_paddr_0 = {$random, $random} & 48'hFFFF;")
    lines.append("    io_tlb_req_resp_bits_pbmt = $random & 3;")
    lines.append("    io_tlb_req_resp_bits_miss = ($random & 3) == 0; // 1/4 miss")
    lines.append("    io_tlb_req_resp_bits_excp_0_gpf_ld = ($random & 15) == 0;")
    lines.append("    io_tlb_req_resp_bits_excp_0_pf_ld  = ($random & 15) == 0;")
    lines.append("    io_tlb_req_resp_bits_excp_0_af_ld  = ($random & 15) == 0;")
    lines.append("    io_tlb_req_pmp_resp_ld   = ($random & 15) == 0;")
    lines.append("    io_tlb_req_pmp_resp_mmio = ($random & 15) == 0;")
    lines.append("    io_out_req_ready = ($random & 3) != 0; // 出队多为高")
    lines.append("  endtask")
    lines.append("")

    # compare
    lines.append("  task automatic check_outputs();")
    lines.append("    checks++;")
    for n, _ in OUTPUTS:
        lines.append(
            f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) "
            f"$display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    lines.append("  endtask")
    lines.append("")

    lines.append("  initial begin")
    lines.append("    rst = 1'b1;")
    for n, _ in INPUTS:
        lines.append(f"    {n} = '0;")
    lines.append("    repeat (6) @(posedge clk);")
    lines.append("    @(negedge clk); rst = 1'b0;")
    lines.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    lines.append("      @(negedge clk);")
    lines.append("      drive_random();")
    lines.append("      @(posedge clk);")
    lines.append("      #1;")
    lines.append("      if (cyc >= WARMUP) check_outputs();")
    lines.append("    end")
    lines.append("    if (errors == 0)")
    lines.append("      $display(\"TEST PASSED: checks=%0d errors=0\", checks);")
    lines.append("    else")
    lines.append("      $display(\"TEST FAILED: checks=%0d errors=%0d\", checks, errors);")
    lines.append("    $finish;")
    lines.append("  end")
    lines.append("endmodule")

    with open("tb.sv", "w") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote tb.sv")


if __name__ == "__main__":
    main()
