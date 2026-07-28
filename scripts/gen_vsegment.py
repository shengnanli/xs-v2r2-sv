#!/usr/bin/env python3
# gen_vsegment.py —— 从 golden VSegmentUnit.sv 端口列表机械派生:
#   - VSegmentUnit_wrapper.sv (扁平端口 FM impl 顶层, 例化 xs_VSegmentUnit_core
#                              + VSegmentTrigger + NewPipelineConnectPipe_31)
#   - variants_xs.sv          (UT 用, 顶层名 VSegmentUnit_xs, 同 wrapper 结构)
#   - tb.sv                   (双例化 golden vs _xs 逐拍比对)
#   - Makefile                (AUX FM, 两侧 elaborate 2 子模块)
import re, os

XSSV   = os.environ.get("XSSV_HOME", "/home/eda/xs-env/xs-vsegment")
GOLDEN = os.path.join(XSSV, "golden/chisel-rtl/VSegmentUnit.sv")
RTLDIR = os.path.join(XSSV, "rtl/memblock")
UTDIR  = os.path.join(XSSV, "verif/ut/VSegmentUnit")

def parse_ports(path, mod):
    txt = open(path).read()
    m = re.search(r'module\s+'+mod+r'\s*\((.*?)\);', txt, re.S)
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

# 顶层 io_sbuffer_bits_* <- pipe io_out_bits_*(直连, 不经核)
SBUF_OUT = ['vaddr','data','mask','addr','vecValid']

def gen_wrapper(ports, modname, fname):
    core = "xs_VSegmentUnit_core"
    # 核连接: 顶层端口凡是核也有的直连(去掉 sbuffer io_out / trigger csr 直传项由核吃)。
    # 核不含: io_sbuffer_valid / io_sbuffer_bits_* (pipe 直连);
    #         io_fromCsrTrigger_* (直接进 segmentTrigger, 核不用)。
    core_skip = set(['clock','reset'])
    for f in SBUF_OUT: core_skip.add('io_sbuffer_bits_'+f)
    core_skip.add('io_sbuffer_valid')
    csr_ports = [n for _,_,n in ports if n.startswith('io_fromCsrTrigger_')]
    for n in csr_ports: core_skip.add(n)
    core_direct = [n for _,_,n in ports if n not in core_skip]

    conns = ["    .clock(clock), .reset(reset)"]
    for n in core_direct:
        conns.append(f"    .{n}({n})")
    # 子模块 glue
    conns += [
      "    .seg_trig_action(seg_trig_action)",
      "    .seg_trig_vaddr(seg_trig_vaddr)",
      "    .seg_trig_memType(seg_trig_memType)",
      "    .pc_in_ready(pc_in_ready)",
      "    .pc_out_valid(pc_out_valid)",
      "    .pc_in_valid(pc_in_valid)",
      "    .pc_in_bits_vaddr(pc_in_bits_vaddr)",
      "    .pc_in_bits_data(pc_in_bits_data)",
      "    .pc_in_bits_mask(pc_in_bits_mask)",
      "    .pc_in_bits_addr(pc_in_bits_addr)",
      "    .pc_in_bits_vecValid(pc_in_bits_vecValid)",
      "    .pc_rightOutFire(pc_rightOutFire)",
    ]
    core_inst = f"  {core} u_core (\n" + ',\n'.join(conns) + "\n  );"

    nets = """  // 子模块 glue 网
  wire [3:0]   seg_trig_action;
  wire [49:0]  seg_trig_vaddr;
  wire         seg_trig_memType;
  wire         pc_in_ready;
  wire         pc_out_valid;
  wire         pc_in_valid;
  wire [49:0]  pc_in_bits_vaddr;
  wire [127:0] pc_in_bits_data;
  wire [15:0]  pc_in_bits_mask;
  wire [47:0]  pc_in_bits_addr;
  wire         pc_in_bits_vecValid;
  wire         pc_rightOutFire;"""

    # VSegmentTrigger 例化: csr trigger 端口直连, vaddr/memType/action 接 glue。
    trig_conns = []
    for _,_,n in ports:
        if n.startswith('io_fromCsrTrigger_'):
            fld = n[len('io_fromCsrTrigger_'):]
            trig_conns.append(f"    .tdataVec_io_fromCsrTrigger_{fld}({n})")
    trig_conns.append("    .tdataVec_io_fromLoadStore_vaddr(seg_trig_vaddr)")
    trig_conns.append("    .tdataVec_io_toLoadStore_triggerAction(seg_trig_action)")
    trig_conns.append("    .tdataVec_io_memType(seg_trig_memType)")
    trig = "  VSegmentTrigger segmentTrigger (\n" + ',\n'.join(trig_conns) + "\n  );"

    # NewPipelineConnectPipe_31 例化: io_in 由核 pc_in_* 驱, io_out -> 顶层 io_sbuffer_*。
    pipe = f"""  NewPipelineConnectPipe_31 VSegmentUnitPipelineConnect (
    .clock                (clock),
    .reset                (reset),
    .io_in_ready          (pc_in_ready),
    .io_in_valid          (pc_in_valid),
    .io_in_bits_vaddr     (pc_in_bits_vaddr),
    .io_in_bits_data      (pc_in_bits_data),
    .io_in_bits_mask      (pc_in_bits_mask),
    .io_in_bits_addr      (pc_in_bits_addr),
    .io_in_bits_vecValid  (pc_in_bits_vecValid),
    .io_out_ready         (io_sbuffer_ready),
    .io_out_valid         (pc_out_valid),
    .io_out_bits_vaddr    (io_sbuffer_bits_vaddr),
    .io_out_bits_data     (io_sbuffer_bits_data),
    .io_out_bits_mask     (io_sbuffer_bits_mask),
    .io_out_bits_addr     (io_sbuffer_bits_addr),
    .io_out_bits_vecValid (io_sbuffer_bits_vecValid),
    .io_rightOutFire      (pc_rightOutFire)
  );
  assign io_sbuffer_valid = pc_out_valid;"""

    tag = 'UT 变体' if modname.endswith('_xs') else 'FM impl 顶层'
    s = f"""// {modname} —— 扁平端口包装({tag}), 例化 xs_VSegmentUnit_core
// + VSegmentTrigger + NewPipelineConnectPipe_31(两侧同 elaborate 的 golden 子模块)。
// 机械生成 by gen_vsegment.py, 勿手改。
module {modname}
  import xs_vsegmentunit_pkg::*;
(
{port_decl(ports)}
);

{nets}

{core_inst}

{trig}

{pipe}

endmodule
"""
    open(fname,'w').write(s)

def gen_tb(ports, fname):
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
    s = f"""// 自动生成 gen_vsegment.py —— 勿手改。双例化 golden VSegmentUnit vs VSegmentUnit_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

{chr(10).join(decl)}

  VSegmentUnit u_g (
{conns('g_')}
  );
  VSegmentUnit_xs u_i (
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
    open(fname,'w').write(s)

def gen_makefile(fname):
    s = """MODULE = VSegmentUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_VSegmentUnit_core(+ pkg) + 扁平端口包装 VSegmentUnit(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vsegmentunit_pkg.sv $(RTL_DIR)/memblock/VSegmentUnit.sv
# golden 子模块闭包(VSegmentTrigger 触发比较 + NewPipelineConnectPipe_31 打拍), 两侧同 elaborate
GOLDEN_SUBS = \\
  $(GOLDEN_RTL)/VSegmentTrigger.sv \\
  $(GOLDEN_RTL)/NewPipelineConnectPipe_31.sv
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/VSegmentUnit.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VSegmentUnit_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VSegmentUnit 顶层 glue; 2 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = VSegmentUnit
FM_REF_DEPS_VSegmentUnit = VSegmentTrigger.sv NewPipelineConnectPipe_31.sv

FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
"""
    open(fname,'w').write(s)

if __name__ == '__main__':
    ports = parse_ports(GOLDEN, "VSegmentUnit")
    os.makedirs(UTDIR, exist_ok=True)
    gen_wrapper(ports, 'VSegmentUnit',    os.path.join(RTLDIR,'VSegmentUnit_wrapper.sv'))
    gen_wrapper(ports, 'VSegmentUnit_xs', os.path.join(UTDIR,'variants_xs.sv'))
    gen_tb(ports, os.path.join(UTDIR,'tb.sv'))
    gen_makefile(os.path.join(UTDIR,'Makefile'))
    print(f"gen ok: {len(ports)} ports")
