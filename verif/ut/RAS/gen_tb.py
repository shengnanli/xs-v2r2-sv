#!/usr/bin/env python3
# 生成 RASStack 的 UT testbench：golden RASStack vs 手写 RASStack_xs 双例化，
# 随机激励逐拍比对所有输出。复位后跳过若干 warmup 拍（golden 同步无复位流水寄存器
# 在复位期保持随机初值，前几拍输出不可比）。
import sys

# (name, width)  width=1 表示标量
INPUTS = [
    ("io_spec_push_valid", 1),
    ("io_spec_pop_valid", 1),
    ("io_spec_push_addr", 50),
    ("io_s2_fire", 1),
    ("io_s3_fire", 1),
    ("io_s3_cancel", 1),
    ("io_s3_meta_ssp", 4),
    ("io_s3_meta_sctr", 3),
    ("io_s3_meta_TOSW_flag", 1),
    ("io_s3_meta_TOSW_value", 5),
    ("io_s3_meta_TOSR_flag", 1),
    ("io_s3_meta_TOSR_value", 5),
    ("io_s3_meta_NOS_flag", 1),
    ("io_s3_meta_NOS_value", 5),
    ("io_s3_missed_pop", 1),
    ("io_s3_missed_push", 1),
    ("io_s3_pushAddr", 50),
    ("io_commit_valid", 1),
    ("io_commit_push_valid", 1),
    ("io_commit_pop_valid", 1),
    ("io_commit_meta_TOSW_flag", 1),
    ("io_commit_meta_TOSW_value", 5),
    ("io_commit_meta_ssp", 4),
    ("io_redirect_valid", 1),
    ("io_redirect_isCall", 1),
    ("io_redirect_isRet", 1),
    ("io_redirect_meta_ssp", 4),
    ("io_redirect_meta_sctr", 3),
    ("io_redirect_meta_TOSW_flag", 1),
    ("io_redirect_meta_TOSW_value", 5),
    ("io_redirect_meta_TOSR_flag", 1),
    ("io_redirect_meta_TOSR_value", 5),
    ("io_redirect_meta_NOS_flag", 1),
    ("io_redirect_meta_NOS_value", 5),
    ("io_redirect_callAddr", 50),
]

OUTPUTS = [
    ("io_spec_pop_addr", 50),
    ("io_ssp", 4),
    ("io_sctr", 3),
    ("io_TOSR_flag", 1),
    ("io_TOSR_value", 5),
    ("io_TOSW_flag", 1),
    ("io_TOSW_value", 5),
    ("io_NOS_flag", 1),
    ("io_NOS_value", 5),
    ("io_spec_near_overflow", 1),
]


def decl(name, w):
    return f"  logic {name};" if w == 1 else f"  logic [{w-1}:0] {name};"


def wdecl(pre, name, w):
    return f"  wire {pre}{name};" if w == 1 else f"  wire [{w-1}:0] {pre}{name};"


def conn(name, sig):
    return f".{name}({sig})"


def main():
    L = []
    L.append("// 自动生成：gen_tb.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 60000;")
    L.append("  int unsigned WARMUP  = 8;   // 跳过复位后未稳定的若干拍")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0, cyc = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    for n, w in INPUTS:
        L.append(decl(n, w))
    for n, w in OUTPUTS:
        L.append(wdecl("g_", n, w))
        L.append(wdecl("i_", n, w))
    L.append("")
    # instantiations
    in_conns = ", ".join(conn(n, n) for n, _ in INPUTS)
    g_out = ", ".join(conn(n, "g_" + n) for n, _ in OUTPUTS)
    i_out = ", ".join(conn(n, "i_" + n) for n, _ in OUTPUTS)
    L.append(f"  RASStack    u_g (.clock(clk), .reset(rst), {in_conns}, {g_out});")
    L.append(f"  RASStack_xs u_i (.clock(clk), .reset(rst), {in_conns}, {i_out});")
    L.append("")
    # stimulus
    L.append("  // 随机激励：指针类输入约束到小范围，使 meta 合理（ssp/nsp<16, ptr value<32）")
    L.append("  always @(negedge clk) begin")
    L.append("    if (rst) begin")
    for n, w in INPUTS:
        L.append(f"      {n} <= '0;")
    L.append("    end else begin")
    # valids: keep them sparse-ish; mutual exclusivity not strictly required (both DUTs same)
    sparse = {
        "io_spec_push_valid": "($urandom_range(0,2)==0)",
        "io_spec_pop_valid": "($urandom_range(0,2)==0)",
        "io_s2_fire": "($urandom_range(0,1)==0)",
        "io_s3_fire": "($urandom_range(0,1)==0)",
        "io_s3_cancel": "($urandom_range(0,4)==0)",
        "io_s3_missed_pop": "($urandom_range(0,3)==0)",
        "io_s3_missed_push": "($urandom_range(0,3)==0)",
        "io_commit_valid": "($urandom_range(0,1)==0)",
        "io_commit_push_valid": "($urandom_range(0,3)==0)",
        "io_commit_pop_valid": "($urandom_range(0,3)==0)",
        "io_redirect_valid": "($urandom_range(0,6)==0)",
        "io_redirect_isCall": "($urandom_range(0,2)==0)",
        "io_redirect_isRet": "($urandom_range(0,2)==0)",
    }
    for n, w in INPUTS:
        if n in sparse:
            L.append(f"      {n} <= {sparse[n]};")
        elif w == 1:
            L.append(f"      {n} <= 1'($urandom);")
        elif w == 50:
            # small address space so retAddr matches happen (尾递归 ctr 路径被覆盖)
            L.append(f"      {n} <= 50'($urandom_range(0,15));")
        elif w == 5:  # ptr value: full 0..31
            L.append(f"      {n} <= 5'($urandom_range(0,31));")
        elif w == 4:  # ssp/nsp: 0..15
            L.append(f"      {n} <= 4'($urandom_range(0,15));")
        elif w == 3:  # sctr: 0..7
            L.append(f"      {n} <= 3'($urandom_range(0,7));")
        else:
            L.append(f"      {n} <= {w}'($urandom);")
    L.append("    end")
    L.append("  end")
    L.append("")
    # checker
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    cyc++;")
    L.append("    if (cyc > WARMUP) begin")
    L.append("      #4; checks++;")
    for n, w in OUTPUTS:
        L.append(f"      if (g_{n} !== i_{n}) begin errors++;")
        L.append(f'        if(errors<=30) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append("    end")
    L.append("  end")
    L.append("")
    L.append("  initial begin")
    L.append("    rst = 1; repeat (5) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    sys.stdout.write("\n".join(L) + "\n")


if __name__ == "__main__":
    main()
