#!/usr/bin/env python3
# gen_vfofbuffer.py —— 从 golden VfofBuffer.sv 端口列表机械派生:
#   - VfofBuffer_wrapper.sv (扁平端口包装, FM impl 侧顶层名 VfofBuffer, 例化 xs_VfofBuffer_core)
#   - variants_xs.sv        (UT 用, 顶层名 VfofBuffer_xs, 例化 xs_VfofBuffer_core)
#   - tb.sv                 (双例化 golden VfofBuffer vs VfofBuffer_xs 逐拍比对)
#   - Makefile              (AUX FM 格式)
import re, os, sys

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/VfofBuffer.sv"
RTLDIR = "/home/eda/xs-env/xs-mb-groupB/rtl/memblock"
UTDIR  = "/home/eda/xs-env/xs-mb-groupB/verif/ut/VfofBuffer"

def parse_ports(path):
    txt = open(path).read()
    m = re.search(r'module\s+VfofBuffer\s*\((.*?)\);', txt, re.S)
    body = m.group(1)
    ports = []
    for line in body.split('\n'):
        line = line.strip().rstrip(',')
        if not line: continue
        mm = re.match(r'(input|output)\s+(\[[0-9]+:[0-9]+\]\s+)?(\w+)$', line)
        if mm:
            d = mm.group(1); w = (mm.group(2) or '').strip(); n = mm.group(3)
            ports.append((d, w, n))
    return ports

def port_decl(ports):
    lines = []
    for d,w,n in ports:
        ww = (' '+w) if w else ''
        lines.append(f"  {d}{ww:<10} {n}")
    return ',\n'.join(lines)

def inst(ports, core):
    lines = [f"  {core} u_core ("]
    conns = [f"    .{n:<44}({n})" for _,_,n in ports]
    lines.append(',\n'.join(conns))
    lines.append("  );")
    return '\n'.join(lines)

def gen_wrapper(ports, modname, fname):
    s = f"""// {modname} —— 扁平端口包装({'UT 变体' if modname.endswith('_xs') else 'FM impl 顶层'}), 例化 xs_VfofBuffer_core。
// 机械生成 by gen_vfofbuffer.py, 勿手改。
module {modname}
  import xs_vfofbuffer_pkg::*;
(
{port_decl(ports)}
);

{inst(ports, 'xs_VfofBuffer_core')}

endmodule
"""
    open(fname,'w').write(s)

def gen_tb(ports, fname):
    # golden top = VfofBuffer, impl top = VfofBuffer_xs
    ins  = [(w,n) for d,w,n in ports if d=='input' and n not in ('clock','reset')]
    outs = [(w,n) for d,w,n in ports if d=='output']
    decl = []
    for w,n in ins:  decl.append(f"  logic {w+' ' if w else ''}{n};")
    for w,n in outs:
        decl.append(f"  logic {w+' ' if w else ''}g_{n};")
        decl.append(f"  logic {w+' ' if w else ''}i_{n};")
    def conns(prefix):
        c = ["    .clock(clk), .reset(rst)"]
        for w,n in ins:  c.append(f"    .{n}({n})")
        for w,n in outs: c.append(f"    .{n}({prefix}{n})")
        return ',\n'.join(c)
    drive = []
    for w,n in ins:
        if w:
            hi = int(re.search(r'\[(\d+):',w).group(1))
            nbits = hi+1
            if nbits <= 32:
                drive.append(f"      {n} <= $random;")
            else:
                parts = ', '.join(['$random']*((nbits+31)//32))
                drive.append(f"      {n} <= {{{parts}}};")
        else:
            drive.append(f"      {n} <= $random;")
    checks = []
    for w,n in outs:
        checks.append(f"      if (g_{n} !== i_{n}) begin errors++; "
                      f"if (errors<20) $display(\"MISMATCH {n} @%0d g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    s = f"""// 自动生成 gen_vfofbuffer.py —— 勿手改。双例化 golden VfofBuffer vs VfofBuffer_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

{chr(10).join(decl)}

  VfofBuffer u_g (
{conns('g_')}
  );
  VfofBuffer_xs u_i (
{conns('i_')}
  );

  initial begin
    rst = 1;
    // 初值
{chr(10).join('    '+n+' = 0;' for w,n in ins)}
    repeat (WARMUP) @(posedge clk);
    rst = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
{chr(10).join(drive)}
      @(posedge clk);
      #1;
      if (cyc > 2) begin
        checks++;
{chr(10).join(checks)}
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=0", checks);
    else             $display("TEST FAILED checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
"""
    open(fname,'w').write(s)

def gen_makefile(fname):
    s = """MODULE = VfofBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_VfofBuffer_core(+ pkg) + 扁平端口包装 VfofBuffer(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vfofbuffer_pkg.sv $(RTL_DIR)/memblock/VfofBuffer.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 VfofBuffer
WRAPPER_SRCS = $(RTL_DIR)/memblock/VfofBuffer_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/VfofBuffer.sv
# UT 变体(impl 顶层改名 VfofBuffer_xs 与 golden 双例化)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VfofBuffer 顶层, 无依赖(自包含单条目缓冲, 0 子模块 0 黑盒)
FM_VARIANTS = VfofBuffer

include ../../../scripts/ut_common.mk

# golden VfofBuffer 含 `ifndef SYNTHESIS 断言(LogUtils assert); UT 随机激励会触发,
# 定义 SYNTHESIS 关掉(同时关随机初值注入, 两侧复位到 0 后同构)。
VCS += +define+SYNTHESIS
"""
    open(fname,'w').write(s)

if __name__ == '__main__':
    ports = parse_ports(GOLDEN)
    os.makedirs(UTDIR, exist_ok=True)
    gen_wrapper(ports, 'VfofBuffer',    os.path.join(RTLDIR,'VfofBuffer_wrapper.sv'))
    gen_wrapper(ports, 'VfofBuffer_xs', os.path.join(UTDIR,'variants_xs.sv'))
    gen_tb(ports, os.path.join(UTDIR,'tb.sv'))
    gen_makefile(os.path.join(UTDIR,'Makefile'))
    print(f"gen ok: {len(ports)} ports")
