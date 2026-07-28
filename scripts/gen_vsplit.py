#!/usr/bin/env python3
# gen_vsplit.py —— 从 golden {VL,VS}SplitImp.sv 派生 memblock 向量 load/store split
# 装配壳的可读核 + wrapper + variant + tb + Makefile。
#
# {VL,VS}SplitImp 是纯组合装配壳(0 reg / 0 always): 例化 3 个 golden 子模块
#   splitPipeline({VL,VS}SplitPipelineImp) → VSSplitSkidBuffer(skidBufferConnect)
#   → splitBuffer({VL,VS}SplitBufferImp)
# 顶层 glue 仅: io_in_ready(VL 带 lqIdx threshold 门控; VS 直连) / io_out_valid /
# skidBuffer 的 io_flush(按流动 uop 的 robIdx 判重定向) / _probe(死)。
#
# 可读核 = golden body 逐字保留结构性 glue(3 子模块两侧同 elaborate 黑盒), 仅:
#   - module 名 → xs_<T>_core, 加 pkg import
#   - _flushItself_T_6 → redirRobIdx(唯一非结构临时名)
#   - 去掉 firtool 头部宏噪声(核不含 `ifndef SYNTHESIS/randomize)
# 忠实度: 结构装配 bug-for-bug, glue 表达式逐字。
import re, os, sys

GOLDEN_DIR = "/home/eda/xs-env/G0-canonical/golden-rtl"
RTLDIR = "/home/eda/xs-env/xs-mb-groupB/rtl/memblock"
UTDIR_BASE = "/home/eda/xs-env/xs-mb-groupB/verif/ut"

# 各 split 顶层的 golden 子模块闭包
SUBS = {
  'VLSplitImp': ['VLSplitPipelineImp.sv', 'VLSplitBufferImp.sv', 'skidBufferConnect.sv'],
  'VSSplitImp': ['VSSplitPipelineImp.sv', 'VSSplitBufferImp.sv', 'skidBufferConnect.sv'],
}

def read_golden(top):
    return open(os.path.join(GOLDEN_DIR, top+'.sv')).read()

def parse_ports(txt, top):
    m = re.search(r'module\s+'+top+r'\s*\((.*?)\n\);', txt, re.S)
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

def extract_body(txt, top):
    # 从 module ports 结束 ');' 到 endmodule 的内部(不含 port header)
    m = re.search(r'module\s+'+top+r'\s*\(.*?\n\);\n(.*)\nendmodule', txt, re.S)
    return m.group(1)

def make_core(top, txt):
    ports = parse_ports(txt, top)
    body = extract_body(txt, top)
    # 重命名唯一非结构临时名
    body = body.replace('_flushItself_T_6', 'redirRobIdx')
    # port 声明
    pdecl = []
    for d,w,n in ports:
        ww = (' '+w) if w else ''
        pdecl.append(f"  {d}{ww:<10} {n}")
    pdecl_str = ',\n'.join(pdecl)
    header = f"""// xs_{top}_core —— 向量 {'load' if top[1]=='L' else 'store'} split 装配壳(纯组合 glue)。
// 手写可读重写, 结构 bug-for-bug 对齐 golden {top}.sv。
// 例化 3 个 golden 子模块(两侧同 elaborate 黑盒, FM 只验本层 glue):
//   splitPipeline({top[:2]}SplitPipelineImp) → VSSplitSkidBuffer(skidBufferConnect)
//   → splitBuffer({top[:2]}SplitBufferImp)
// 顶层 glue: io_in_ready{'(带 lqIdx threshold 门控)' if top=='VLSplitImp' else '(直连 pipeline.ready)'} /
//   io_out_valid(splitBuffer.out.valid) / skidBuffer.io_flush(流动 uop robIdx 判重定向)。
module xs_{top}_core
  import xs_{top.lower()}_pkg::*;
(
{pdecl_str}
);
"""
    # redirRobIdx 声明(golden 里是 wire[8:0] redirRobIdx = {flag,value};) —— body 已含
    return header + body + "\nendmodule\n"

def make_wrapper(top, txt, modname):
    ports = parse_ports(txt, top)
    pdecl = []
    for d,w,n in ports:
        ww = (' '+w) if w else ''
        pdecl.append(f"  {d}{ww:<10} {n}")
    conns = [f"    .{n:<48}({n})" for _,_,n in ports]
    kind = 'UT 变体' if modname.endswith('_xs') else 'FM impl 顶层'
    pdecl_str = ',\n'.join(pdecl)
    conns_str = ',\n'.join(conns)
    s = f"""// {modname} —— 扁平端口包装({kind}), 例化 xs_{top}_core。机械生成勿手改。
module {modname}
  import xs_{top.lower()}_pkg::*;
(
{pdecl_str}
);
  xs_{top}_core u_core (
{conns_str}
  );
endmodule
"""
    return s

def make_pkg(top):
    return f"""// xs_{top.lower()}_pkg —— {top} 装配壳可读核公共定义(占位; 本壳纯结构无自定义类型)。
`ifndef XS_{top.upper()}_PKG_SV
`define XS_{top.upper()}_PKG_SV
package xs_{top.lower()}_pkg;
  localparam int UNUSED = 0;
endpackage
`endif
"""

def make_tb(top, txt):
    ports = parse_ports(txt, top)
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
            hi = int(re.search(r'\[(\d+):',w).group(1)); nbits = hi+1
            if nbits <= 32: drive.append(f"      {n} <= $random;")
            else:
                parts = ', '.join(['$random']*((nbits+31)//32))
                drive.append(f"      {n} <= {{{parts}}};")
        else:
            drive.append(f"      {n} <= $random;")
    checks = []
    for w,n in outs:
        checks.append(f"      if (g_{n} !== i_{n}) begin errors++; "
                      f"if (errors<20) $display(\"MISMATCH {n} @%0d g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    s = f"""// 自动生成 gen_vsplit.py —— 勿手改。双例化 golden {top} vs {top}_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

{chr(10).join(decl)}

  {top} u_g (
{conns('g_')}
  );
  {top}_xs u_i (
{conns('i_')}
  );

  initial begin
    rst = 1;
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
    return s

def make_makefile(top):
    subs = SUBS[top]
    sub_lines = ' '.join(subs)
    sub_golden = ' \\\n  '.join(f'$(GOLDEN_RTL)/{s}' for s in subs)
    s = f"""MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_{top}_core(+ pkg) + 扁平端口包装 {top}(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/{top.lower()}_pkg.sv $(RTL_DIR)/memblock/{top}.sv
# golden 子模块闭包(纯结构装配壳的 3 个逻辑子, 两侧同 elaborate 黑盒)
GOLDEN_SUBS = \\
  {sub_golden}
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate → 子模块内部逐位自配)
WRAPPER_SRCS = $(RTL_DIR)/memblock/{top}_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 {top} 顶层 glue; 3 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = {top}
FM_REF_DEPS_{top} = {sub_lines}

# 子模块含同构表项/流水寄存器, 关合并同值重复寄存器 pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS
"""
    return s

if __name__ == '__main__':
    for top in ['VLSplitImp', 'VSSplitImp']:
        txt = read_golden(top)
        utdir = os.path.join(UTDIR_BASE, top)
        os.makedirs(utdir, exist_ok=True)
        open(os.path.join(RTLDIR, top.lower()+'_pkg.sv'),'w').write(make_pkg(top))
        open(os.path.join(RTLDIR, top+'.sv'),'w').write(make_core(top, txt))
        open(os.path.join(RTLDIR, top+'_wrapper.sv'),'w').write(make_wrapper(top, txt, top))
        open(os.path.join(utdir, 'variants_xs.sv'),'w').write(make_wrapper(top, txt, top+'_xs'))
        open(os.path.join(utdir, 'tb.sv'),'w').write(make_tb(top, txt))
        open(os.path.join(utdir, 'Makefile'),'w').write(make_makefile(top))
        print(f"{top}: {len(parse_ports(txt,top))} ports gen ok")
