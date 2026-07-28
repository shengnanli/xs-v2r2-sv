#!/usr/bin/env python3
# 生成 MemExeUnit 的 UT testbench: golden MemExeUnit vs 手写 MemExeUnit_xs 双例化,
# 随机激励逐拍比对所有输出。两侧共用 golden Std 子模块定义(单定义两实例, 无撞名)。
# MemExeUnit 是纯组合透传壳(无 clock/reset), 每拍打随机激励并即刻比对组合输出。
import sys

# (name, width)  width=1 表示标量
INPUTS = [
    ("io_in_valid", 1),
    ("io_in_bits_uop_fuType", 35),
    ("io_in_bits_uop_fuOpType", 9),
    ("io_in_bits_uop_robIdx_value", 8),
    ("io_in_bits_uop_sqIdx_flag", 1),
    ("io_in_bits_uop_sqIdx_value", 6),
    ("io_in_bits_src_0", 64),
    ("io_out_ready", 1),
]

OUTPUTS = [
    ("io_in_ready", 1),
    ("io_out_valid", 1),
    ("io_out_bits_uop_fuType", 35),
    ("io_out_bits_uop_fuOpType", 9),
    ("io_out_bits_uop_robIdx_value", 8),
    ("io_out_bits_uop_sqIdx_flag", 1),
    ("io_out_bits_uop_sqIdx_value", 6),
    ("io_out_bits_data", 64),
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
    lines.append("  bit clk = 0;")
    lines.append("  int errors = 0, checks = 0, cyc = 0;")
    lines.append("  always #5 clk = ~clk;")
    lines.append("")
    # input regs
    for n, w in INPUTS:
        lines.append("  " + decl(n, w))
    # output wires (g_ / i_)
    for n, w in OUTPUTS:
        lines.append("  " + wdecl("g_" + n, w))
        lines.append("  " + wdecl("i_" + n, w))
    lines.append("")

    # golden instance (no clock/reset — pure combinational)
    lines.append("  MemExeUnit dut_g (")
    ins = port_map([n for n, _ in INPUTS])
    outs_g = port_map([n for n, _ in OUTPUTS], prefix="g_")
    lines.append(ins + ",")
    lines.append(outs_g)
    lines.append("  );")
    lines.append("")
    # impl instance
    lines.append("  MemExeUnit_xs dut_i (")
    outs_i = port_map([n for n, _ in OUTPUTS], prefix="i_")
    lines.append(ins + ",")
    lines.append(outs_i)
    lines.append("  );")
    lines.append("")

    # stimulus
    lines.append("  task automatic drive_random();")
    for n, w in INPUTS:
        if w <= 32:
            lines.append(f"    {n} = $random;")
        else:
            chunks = (w + 31) // 32
            parts = ",".join("$random" for _ in range(chunks))
            lines.append(f"    {n} = {{{parts}}};")
    lines.append("  endtask")
    lines.append("")

    # compare
    lines.append("  task automatic check_outputs();")
    lines.append("    checks++;")
    for n, _ in OUTPUTS:
        lines.append(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    lines.append("  endtask")
    lines.append("")

    lines.append("  initial begin")
    for n, _ in INPUTS:
        lines.append(f"    {n} = '0;")
    lines.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    lines.append("      @(negedge clk);")
    lines.append("      drive_random();")
    lines.append("      #1;")  # let combinational settle
    lines.append("      check_outputs();")
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
