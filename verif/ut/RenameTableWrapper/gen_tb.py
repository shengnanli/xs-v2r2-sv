#!/usr/bin/env python3
# 生成 RenameTableWrapper 的 UT tb: 双例化 golden RenameTableWrapper(u_g) 与
# RenameTableWrapper_xs(u_i, 例化可读核), 随机激励, 比对全部输出端口。
import re

GOLD = "/home/eda/xs-env/G0-canonical/golden-rtl/RenameTableWrapper.sv"
OUT  = "/tmp/xs-signoff-cb-children2/verif/ut/RenameTableWrapper/tb.sv"

lines = open(GOLD).read().split("\n")
ms = next(i for i,l in enumerate(lines) if l.startswith("module RenameTableWrapper("))
pe = next(i for i in range(ms, len(lines)) if lines[i].startswith(");"))

inputs, outputs = [], []   # (name, width)  width=0 表示 1 位
for l in lines[ms+1:pe]:
    m = re.match(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)", l)
    if not m: continue
    d, hi, lo, nm = m.groups()
    w = (int(hi)-int(lo)+1) if hi is not None else 1
    (inputs if d=="input" else outputs).append((nm, w))

# clock/reset 不算激励
drv = [(n,w) for n,w in inputs if n not in ("clock","reset")]

o = []
o.append('`timescale 1ns/1ps')
o.append('// 生成: gen_tb.py —— 勿手改。双例化 golden RenameTableWrapper vs _xs, 比对全部输出。')
o.append('module tb;')
o.append('  int unsigned NCYCLES = 200000;')
o.append('  int unsigned WARMUP  = 8;')
o.append('  bit clk = 0, rst;')
o.append('  int errors = 0, checks = 0, cyc = 0;')
o.append('  always #5 clk = ~clk;')
o.append('')
# 输入信号
for n,w in drv:
    decl = "logic " + (f"[{w-1}:0] " if w>1 else "") + n + ";"
    o.append("  " + decl)
# 输出对(g/i)
for n,w in outputs:
    wd = f"[{w-1}:0] " if w>1 else ""
    o.append(f"  wire {wd}g_{n}; wire {wd}i_{n};")
o.append('')
# 例化 helper
def inst(mod, inst_name, out_prefix):
    conns = ["    .clock(clk)", "    .reset(rst)"]
    for n,w in drv:
        conns.append(f"    .{n}({n})")
    for n,w in outputs:
        conns.append(f"    .{n}({out_prefix}_{n})")
    return f"  {mod} {inst_name} (\n" + ",\n".join(conns) + "\n  );"
o.append(inst("RenameTableWrapper", "u_g", "g"))
o.append(inst("RenameTableWrapper_xs", "u_i", "i"))
o.append('')
# 随机激励
o.append('  always @(negedge clk) begin')
o.append('    if (rst) begin')
for n,w in drv:
    o.append(f"      {n} <= '0;")
o.append('    end else begin')
for n,w in drv:
    if w == 1:
        o.append(f"      {n} <= ($urandom_range(0,1));")
    else:
        o.append(f"      {n} <= {w}'($urandom);")
o.append('    end')
o.append('  end')
o.append('')
# 比对
o.append('  task automatic chk(input string nm, input logic [63:0] g, input logic [63:0] i);')
o.append('    if (g !== i) begin errors++;')
o.append('      if (errors<=40) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end')
o.append('  endtask')
o.append('')
o.append('  always @(negedge clk) if (!rst) begin')
o.append('    cyc++;')
o.append('    if (cyc > WARMUP) begin')
o.append('      #4; checks++;')
for n,w in outputs:
    o.append(f'      chk("{n}", 64\'(g_{n}), 64\'(i_{n}));')
o.append('    end')
o.append('  end')
o.append('')
o.append('  initial begin')
o.append('    rst = 1; repeat (5) @(posedge clk); rst = 0;')
o.append('    repeat (NCYCLES) @(posedge clk);')
o.append('    $display("checks=%0d errors=%0d", checks, errors);')
o.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
o.append('    $finish;')
o.append('  end')
o.append('endmodule')

open(OUT, "w").write("\n".join(o) + "\n")
print(f"inputs(drv)={len(drv)} outputs={len(outputs)}  -> {OUT}")
