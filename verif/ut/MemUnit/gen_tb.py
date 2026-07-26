#!/usr/bin/env python3
# 生成 MemUnit 的 UT testbench: golden MemUnit vs 手写 MemUnit_xs 双例化,
# 随机激励逐拍比对所有输出。两侧共用 golden FastArbiter_50/52 定义(单定义两实例, 无撞名)。
# 复位后跳过若干 warmup 拍(SYNTHESIS 下寄存器复位到 0, 两侧同构)。
import re

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/MemUnit.sv"
src = open(GOLDEN).read()
m = re.search(r'module MemUnit\((.*?)\n\);', src, re.S)
portblock = m.group(1)
INPUTS, OUTPUTS = [], []
for line in portblock.splitlines():
    line = line.strip().rstrip(',')
    mm = re.match(r'(input|output)\s+(?:\[(\d+):(\d+)\])?\s*([A-Za-z_][A-Za-z0-9_]*)$', line)
    if not mm: continue
    d = mm.group(1); hi = mm.group(2); nm = mm.group(4)
    if nm in ("clock","reset"): continue
    w = (int(hi)+1) if hi else 1
    (INPUTS if d=="input" else OUTPUTS).append((nm,w))

def decl(name,w): return f"logic [{w-1}:0] {name};" if w>1 else f"logic {name};"
def wdecl(name,w): return f"wire [{w-1}:0] {name};" if w>1 else f"wire {name};"
def port_map(names,prefix=""): return ",\n".join(f"    .{n}({prefix}{n})" for n in names)

lines=[]
lines.append("// 自动生成: gen_tb.py —— 勿手改")
lines.append("`timescale 1ns/1ps")
lines.append("module tb;")
lines.append("  int unsigned NCYCLES = 200000;")
lines.append("  int unsigned WARMUP  = 8;")
lines.append("  bit clk = 0, rst;")
lines.append("  int errors = 0, checks = 0, cyc = 0;")
lines.append("  always #5 clk = ~clk;")
lines.append("")
for n,w in INPUTS: lines.append("  "+decl(n,w))
for n,w in OUTPUTS:
    lines.append("  "+wdecl("g_"+n,w))
    lines.append("  "+wdecl("i_"+n,w))
lines.append("")
lines.append("  MemUnit dut_g (")
lines.append("    .clock(clk), .reset(rst),")
lines.append(port_map([n for n,_ in INPUTS])+",")
lines.append(port_map([n for n,_ in OUTPUTS],prefix="g_"))
lines.append("  );")
lines.append("")
lines.append("  MemUnit_xs dut_i (")
lines.append("    .clock(clk), .reset(rst),")
lines.append(port_map([n for n,_ in INPUTS])+",")
lines.append(port_map([n for n,_ in OUTPUTS],prefix="i_"))
lines.append("  );")
lines.append("")
# stimulus
lines.append("  task automatic drive_random();")
for n,w in INPUTS:
    if w<=32:
        lines.append(f"    {n} = $random;")
    else:
        chunks=(w+31)//32
        parts=",".join("$random" for _ in range(chunks))
        lines.append(f"    {n} = {{{parts}}};")
lines.append("    // 偏置: 使控制路径更常被触发")
# alloc valids biased on
lines.append("    if (($random & 3) != 0) io_txreq_ready = 1'b1;")
lines.append("    if (($random & 3) != 0) io_txdat_ready = 1'b1;")
# snRxrsp opcode toward {4,5,6}; rnRxdat resp toward DataResp
lines.append("    case ($random & 3) 0: io_snRxrsp_bits_opcode = 7'h4; 1: io_snRxrsp_bits_opcode = 7'h5; 2: io_snRxrsp_bits_opcode = 7'h6; default: ; endcase")
# alloc chiOpcode toward WriteBackFull 0x1D so entries actually issue TXDAT/free
lines.append("    if (($random & 1) == 0) io_fromMainPipe_alloc_s4_bits_task_chiOpcode = 7'h1D;")
lines.append("    if (($random & 1) == 0) io_fromMainPipe_alloc_s6_bits_task_chiOpcode = 7'h1D;")
# s4 opcode toward ReadNoSnp 0x4 (for conflict/bypass) sometimes
lines.append("    if (($random & 7) == 0) io_fromMainPipe_alloc_s4_bits_task_chiOpcode = 7'h4;")
# rnRxdat resp DataResp (resp[2]=1) sometimes
lines.append("    if (($random & 1) == 0) io_rnRxdat_bits_resp = io_rnRxdat_bits_resp | 3'h4;")
# make respInfo opcodes hit blockByResp set {7,26}
for i in range(16):
    lines.append(f"    if (($random & 7) == 0) begin io_respInfo_{i}_bits_w_snpRsp = 1'b1; io_respInfo_{i}_bits_w_compdata = 1'b0; io_respInfo_{i}_bits_opcode = ($random & 1) ? 7'h7 : 7'h26; end")
# bias reqID/txnID to a small space to create matches across channels
lines.append("    io_rnRxdat_bits_txnID = io_rnRxdat_bits_txnID & 12'h1F;")
lines.append("    io_rnRxrsp_bits_txnID = io_rnRxrsp_bits_txnID & 12'h1F;")
lines.append("    io_snRxrsp_bits_txnID = io_snRxrsp_bits_txnID & 12'h1F;")
lines.append("    io_fromMainPipe_alloc_s4_bits_task_reqID = io_fromMainPipe_alloc_s4_bits_task_reqID & 12'h1F;")
lines.append("    io_fromMainPipe_alloc_s6_bits_task_reqID = io_fromMainPipe_alloc_s6_bits_task_reqID & 12'h1F;")
# bias set/tag small so conflict/bypass paths hit
lines.append("    io_urgentRead_bits_set = io_urgentRead_bits_set & 12'h7;")
lines.append("    io_fromMainPipe_alloc_s4_bits_task_set = io_fromMainPipe_alloc_s4_bits_task_set & 12'h7;")
lines.append("    io_fromMainPipe_alloc_s6_bits_task_set = io_fromMainPipe_alloc_s6_bits_task_set & 12'h7;")
lines.append("    io_urgentRead_bits_tag = io_urgentRead_bits_tag & 28'h3;")
lines.append("    io_fromMainPipe_alloc_s4_bits_task_tag = io_fromMainPipe_alloc_s4_bits_task_tag & 28'h3;")
lines.append("    io_fromMainPipe_alloc_s6_bits_task_tag = io_fromMainPipe_alloc_s6_bits_task_tag & 28'h3;")
lines.append("  endtask")
lines.append("")
lines.append("  task automatic check_outputs();")
lines.append("    checks++;")
for n,_ in OUTPUTS:
    lines.append(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=30) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
lines.append("  endtask")
lines.append("")
lines.append("  initial begin")
lines.append("    rst = 1'b1;")
for n,_ in INPUTS: lines.append(f"    {n} = '0;")
lines.append("    repeat (6) @(posedge clk);")
lines.append("    @(negedge clk); rst = 1'b0;")
lines.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
lines.append("      @(negedge clk);")
lines.append("      drive_random();")
lines.append("      @(posedge clk);")
lines.append("      #1;")
lines.append("      if (cyc >= WARMUP) check_outputs();")
lines.append("    end")
lines.append("    if (errors == 0) $display(\"TEST PASSED: checks=%0d errors=0\", checks);")
lines.append("    else $display(\"TEST FAILED: checks=%0d errors=%0d\", checks, errors);")
lines.append("    $finish;")
lines.append("  end")
lines.append("endmodule")
open("tb.sv","w").write("\n".join(lines)+"\n")
print(f"wrote tb.sv: {len(INPUTS)} inputs, {len(OUTPUTS)} outputs")
