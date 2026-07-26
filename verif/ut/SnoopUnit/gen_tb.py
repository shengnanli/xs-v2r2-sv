#!/usr/bin/env python3
# 生成 SnoopUnit 的 UT testbench: golden SnoopUnit vs 手写 SnoopUnit_xs 双例化,
# 随机激励逐拍比对所有输出。两侧共用 golden FastArbiter_50 定义(单定义两实例, 无撞名)。
# 复位后跳过若干 warmup 拍(SYNTHESIS 下寄存器复位到 0, 但两侧同构, warmup 保守)。
import sys

# (name, width)  width=1 表示标量
INPUTS = [
    ("io_in_valid", 1),
    ("io_in_bits_set", 12),
    ("io_in_bits_bank", 2),
    ("io_in_bits_tag", 28),
    ("io_in_bits_replSnp", 1),
    ("io_in_bits_snpVec_0", 1),
    ("io_in_bits_txnID", 12),
    ("io_in_bits_chiOpcode", 7),
    ("io_in_bits_retToSrc", 1),
    ("io_out_ready", 1),
    ("io_ack_valid", 1),
    ("io_ack_bits_txnID", 12),
    ("io_ack_bits_opcode", 7),
]
# 16 路 respInfo
for i in range(16):
    INPUTS += [
        (f"io_respInfo_{i}_valid", 1),
        (f"io_respInfo_{i}_bits_set", 12),
        (f"io_respInfo_{i}_bits_tag", 28),
        (f"io_respInfo_{i}_bits_opcode", 7),
        (f"io_respInfo_{i}_bits_reqID", 12),
        (f"io_respInfo_{i}_bits_w_compack", 1),
    ]

OUTPUTS = [
    ("io_out_valid", 1),
    ("io_out_bits_set", 12),
    ("io_out_bits_bank", 2),
    ("io_out_bits_tag", 28),
    ("io_out_bits_snpVec_0", 1),
    ("io_out_bits_txnID", 12),
    ("io_out_bits_fwdNID", 11),
    ("io_out_bits_fwdTxnID", 12),
    ("io_out_bits_chiOpcode", 7),
    ("io_out_bits_retToSrc", 1),
    ("io_out_bits_doNotGoToSD", 1),
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
    # input regs
    for n, w in INPUTS:
        lines.append("  " + decl(n, w))
    # output wires (g_ / i_)
    for n, w in OUTPUTS:
        lines.append("  " + wdecl("g_" + n, w))
        lines.append("  " + wdecl("i_" + n, w))
    lines.append("")

    # golden instance
    lines.append("  SnoopUnit dut_g (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="g_"))
    lines.append("  );")
    lines.append("")
    # impl instance
    lines.append("  SnoopUnit_xs dut_i (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="i_"))
    lines.append("  );")
    lines.append("")

    # stimulus
    lines.append("  // 随机激励: 对每个输入独立取随机值; 部分字段偏置以覆盖控制路径")
    lines.append("  task automatic drive_random();")
    for n, w in INPUTS:
        if w <= 32:
            lines.append(f"    {n} = $random;")
        else:
            chunks = (w + 31) // 32
            parts = ",".join("$random" for _ in range(chunks))
            lines.append(f"    {n} = {{{parts}}};")
    # bias: ack opcode toward 2 (completion), respInfo opcodes toward matching set,
    # io_out_ready mostly high to exercise dequeue/flow
    lines.append("    // 偏置: 使控制路径更常被触发")
    lines.append("    if (($random & 1) == 0) io_ack_bits_opcode = 7'h2;")
    lines.append("    if (($random & 3) != 0) io_out_ready = 1'b1;")
    lines.append("    // 让部分 respInfo 与入站任务同地址且合法 opcode 以触发 canFlow / initReady")
    for i in range(16):
        lines.append(f"    if (($random & 7) == 0) begin")
        lines.append(f"      io_respInfo_{i}_valid = 1'b1;")
        lines.append(f"      io_respInfo_{i}_bits_set = io_in_bits_set;")
        lines.append(f"      io_respInfo_{i}_bits_tag = io_in_bits_tag;")
        lines.append(f"      io_respInfo_{i}_bits_w_compack = 1'b0;")
        lines.append(f"      case ($random & 3) 0: io_respInfo_{i}_bits_opcode = 7'h26; 1: io_respInfo_{i}_bits_opcode = 7'h7; default: io_respInfo_{i}_bits_opcode = 7'hC; endcase")
        lines.append(f"    end")
    lines.append("    io_in_bits_replSnp = ($random & 1) ? 1'b1 : io_in_bits_replSnp;")
    lines.append("  endtask")
    lines.append("")

    # compare
    lines.append("  task automatic check_outputs();")
    lines.append("    checks++;")
    conds = []
    for n, _ in OUTPUTS:
        conds.append(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    lines += conds
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
