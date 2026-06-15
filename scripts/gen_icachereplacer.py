#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 ICacheReplacer 的 golden 同名包装层、UT _xs 变体、以及双例化 tb。
可读核 rtl/frontend/ICacheReplacer.sv（xs_ICacheReplacer_core）手写，不在此生成。

ICacheReplacer 端口（来自 golden/chisel-rtl/ICacheReplacer.sv）：
  clock, reset
  io_touch_0_valid, io_touch_0_bits_vSetIdx[7:0], io_touch_0_bits_way[1:0]
  io_touch_1_valid, io_touch_1_bits_vSetIdx[7:0], io_touch_1_bits_way[1:0]
  io_victim_vSetIdx_valid, io_victim_vSetIdx_bits[7:0]
  io_victim_way[1:0]   (output)
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
RTL  = os.path.join(HERE, "..", "rtl", "frontend")
UT   = os.path.join(HERE, "..", "verif", "ut", "ICacheReplacer")

# (name, msb_or_None_for_1bit, is_output)
INPUTS = [
    ("io_touch_0_valid",        None),
    ("io_touch_0_bits_vSetIdx", 7),
    ("io_touch_0_bits_way",     1),
    ("io_touch_1_valid",        None),
    ("io_touch_1_bits_vSetIdx", 7),
    ("io_touch_1_bits_way",     1),
    ("io_victim_vSetIdx_valid", None),
    ("io_victim_vSetIdx_bits",  7),
]
OUTPUTS = [
    ("io_victim_way", 1),
]

def width(msb):
    return "" if msb is None else "[%d:0] " % msb

def decl(kind, name, msb):
    return "  %s %s%s" % (kind, width(msb), name)

# ----------------------------------------------------------------------------
# _xs 变体（UT 用，无 golden 同名冲突）：例化可读核
# ----------------------------------------------------------------------------
def gen_xs():
    ports = []
    ports.append("  input  clock")
    ports.append("  input  reset")
    for n, m in INPUTS:
        ports.append("  input  %s%s" % (width(m), n))
    for n, m in OUTPUTS:
        ports.append("  output %s%s" % (width(m), n))
    body = []
    body.append("// 自动生成：scripts/gen_icachereplacer.py —— 勿手改")
    body.append("module ICacheReplacer_xs(")
    body.append(",\n".join(ports))
    body.append(");")
    body.append("  xs_ICacheReplacer_core #(.NUM_SETS(256), .NUM_WAYS(4)) u_core (")
    conn = [".clock(clock)", ".reset(reset)"]
    for n, _ in INPUTS + OUTPUTS:
        conn.append(".%s(%s)" % (n, n))
    body.append("    " + ",\n    ".join(conn))
    body.append("  );")
    body.append("endmodule")
    return "\n".join(body) + "\n"

# ----------------------------------------------------------------------------
# golden 同名包装层（FM 用）
# ----------------------------------------------------------------------------
def gen_wrapper():
    ports = []
    ports.append("  input        clock")
    ports.append("  input        reset")
    for n, m in INPUTS:
        ports.append("  input  %s%s" % (width(m), n))
    for n, m in OUTPUTS:
        ports.append("  output %s%s" % (width(m), n))
    body = []
    body.append("// 自动生成：scripts/gen_icachereplacer.py —— 勿手改")
    body.append("// golden 同名包装层：模块名 ICacheReplacer，端口与 golden 完全一致；")
    body.append("// 内部例化可读核 xs_ICacheReplacer_core（端口本就是 golden 扁平名）。")
    body.append("module ICacheReplacer(")
    body.append(",\n".join(ports))
    body.append(");")
    body.append("  xs_ICacheReplacer_core #(.NUM_SETS(256), .NUM_WAYS(4)) u_core (")
    conn = [".clock(clock)", ".reset(reset)"]
    for n, _ in INPUTS + OUTPUTS:
        conn.append(".%s(%s)" % (n, n))
    body.append("    " + ",\n    ".join(conn))
    body.append("  );")
    body.append("endmodule")
    return "\n".join(body) + "\n"

# ----------------------------------------------------------------------------
# 双例化 tb：随机激励 touch（命中/refill 路由）+ 读 victim，逐拍比对全部输出
# ----------------------------------------------------------------------------
def gen_tb():
    L = []
    L.append("// 自动生成：scripts/gen_icachereplacer.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 20000;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    # input regs
    for n, m in INPUTS:
        L.append("  logic %s%s;" % (width(m), n))
    # outputs g/i
    for n, m in OUTPUTS:
        L.append("  wire %sg_%s;" % (width(m), n))
        L.append("  wire %si_%s;" % (width(m), n))
    L.append("")
    # instantiations
    def inst(mod, u, pre):
        conn = [".clock(clk)", ".reset(rst)"]
        for n, _ in INPUTS:
            conn.append(".%s(%s)" % (n, n))
        for n, _ in OUTPUTS:
            conn.append(".%s(%s_%s)" % (n, pre, n))
        return "  %s %s (%s);" % (mod, u, ", ".join(conn))
    L.append(inst("ICacheReplacer",    "u_g", "g"))
    L.append(inst("ICacheReplacer_xs", "u_i", "i"))
    L.append("")
    # stimulus
    L.append("  always @(negedge clk) begin")
    L.append("    if (rst) begin")
    L.append("      io_touch_0_valid <= 1'b0;")
    L.append("      io_touch_1_valid <= 1'b0;")
    L.append("      io_victim_vSetIdx_valid <= 1'b0;")
    L.append("    end else begin")
    # 混合激励：一半周期模拟取指跨 vSet 边界（touch0 偶 / touch1=偶+1 奇），
    # 另一半周期两条 touch 地址完全独立随机——后者覆盖 golden 的非对称 bank 路由
    # （bank0 选择子用 touch0[0]、bank1 选择子用 touch1[0]）及两条 touch 同 bank、
    # 窄缩到同一组（含与 refill touch 同拍命中同组的多次折叠）等所有边角。
    L.append("      logic [7:0] base;")
    L.append("      base = {7'($urandom), 1'b0};")
    L.append("      io_touch_0_valid <= ($urandom_range(0,1)==0);")
    L.append("      io_touch_1_valid <= ($urandom_range(0,1)==0);")
    L.append("      io_touch_0_bits_way <= 2'($urandom);")
    L.append("      io_touch_1_bits_way <= 2'($urandom);")
    L.append("      if ($urandom_range(0,1)==0) begin")
    L.append("        // 取指跨边界：相邻偶/奇组")
    L.append("        io_touch_0_bits_vSetIdx <= base;")
    L.append("        io_touch_1_bits_vSetIdx <= base + 8'd1;")
    L.append("      end else begin")
    L.append("        // 完全独立随机（含同奇偶、同组冲突）")
    L.append("        io_touch_0_bits_vSetIdx <= 8'($urandom);")
    L.append("        io_touch_1_bits_vSetIdx <= ($urandom_range(0,3)==0) ? base")
    L.append("                                                            : 8'($urandom);")
    L.append("      end")
    L.append("      // victim 查询：随机 set（含奇偶），valid 随机 → 覆盖延迟 refill touch；")
    L.append("      // 偏向小地址以提高与 touch 命中同组的概率")
    L.append("      io_victim_vSetIdx_valid <= ($urandom_range(0,1)==0);")
    L.append("      io_victim_vSetIdx_bits <= ($urandom_range(0,2)==0) ? base")
    L.append("                                                         : 8'($urandom);")
    L.append("    end")
    L.append("  end")
    L.append("")
    # checking
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for n, _ in OUTPUTS:
        L.append("    if (g_%s !== i_%s) begin errors++;" % (n, n))
        L.append("      if(errors<=30) $display(\"[%%0t] %s g=%%h i=%%h\", $time, g_%s, i_%s); end" % (n, n, n))
    L.append("  end")
    L.append("")
    # run control
    L.append("  initial begin")
    L.append("    rst = 1'b1;")
    L.append("    repeat (5) @(negedge clk);")
    L.append("    rst = 1'b0;")
    L.append("    repeat (NCYCLES) @(negedge clk);")
    L.append("    if (errors == 0) $display(\"TEST PASSED  checks=%0d errors=%0d\", checks, errors);")
    L.append("    else             $display(\"TEST FAILED  checks=%0d errors=%0d\", checks, errors);")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    return "\n".join(L) + "\n"

def main():
    os.makedirs(UT, exist_ok=True)
    with open(os.path.join(RTL, "ICacheReplacer_wrapper.sv"), "w") as f:
        f.write(gen_wrapper())
    with open(os.path.join(UT, "variants_xs.sv"), "w") as f:
        f.write(gen_xs())
    with open(os.path.join(UT, "tb.sv"), "w") as f:
        f.write(gen_tb())
    print("generated: ICacheReplacer_wrapper.sv, variants_xs.sv, tb.sv")

if __name__ == "__main__":
    main()
