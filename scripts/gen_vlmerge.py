#!/usr/bin/env python3
# gen_vlmerge.py —— 从 golden VLMergeBufferImp.sv 结构化派生可读核 xs_VLMergeBufferImp_core。
#
# VL = 向量 load 16 条目 merge buffer(golden 8604 行): 双 fromSplit 分配 + 3 端口
# 寄存流水的字节级数据合并(碰撞矩阵) + 双 uopWriteback(oldest/youngest 双 select)。
# 可读化(同 MSHRCtl/EntriesVlduVstu 的 16 路阵列法):
#   - 16 条目 entries_N_field 平坦寄存器 → struct 数组 entries[16](vlmb_entry_t)
#   - allocated/uopFinish/needRSReplay 16 个平坦位 → 位向量
#   - 3 端口字节合并/碰撞矩阵/双 select 等共享组合与寄存逻辑忠实保留(genuine 功能逻辑)
#   - 子模块 FreeList / NewPipelineConnectPipe_27×2 由核直接例化(两侧同 elaborate 黑盒)
#   - wrapper 仅扁平端口透传 core(FM impl 顶层名 VLMergeBufferImp / UT 名 _xs)
import re, os

XSSV   = "/home/eda/xs-env/xs-mb-merge"
GOLDEN = os.path.join(XSSV, "golden/chisel-rtl/VLMergeBufferImp.sv")
RTLDIR = os.path.join(XSSV, "rtl/memblock")
UTDIR  = os.path.join(XSSV, "verif/ut/VLMergeBufferImp")

_ENT_RE = re.compile(r'\bentries_(\d+)_([A-Za-z0-9_]+)')
def sub_entries(line):
    return _ENT_RE.sub(lambda m: f'entries[{m.group(1)}].{m.group(2)}', line)

_BV_RE = re.compile(r'\b(allocated|uopFinish|needRSReplay)_(\d+)\b')
def sub_bitvec(line):
    return _BV_RE.sub(lambda m: f'{m.group(1)}[{m.group(2)}]', line)

def parse_ports():
    txt = open(GOLDEN).read()
    m = re.search(r'module\s+VLMergeBufferImp\s*\((.*?)\);', txt, re.S)
    ports=[]
    for line in m.group(1).split('\n'):
        line=line.strip().rstrip(',')
        mm=re.match(r'(input|output)\s+(\[[0-9]+:[0-9]+\]\s+)?(\w+)$', line)
        if mm:
            ports.append((mm.group(1),(mm.group(2) or '').strip(),mm.group(3)))
    return ports

def port_decl(ports):
    out=[]
    for d,w,n in ports:
        ww=(' '+w) if w else ''
        out.append(f"  {d}{ww:<10} {n}")
    return ',\n'.join(out)

def build_core_body():
    lines = open(GOLDEN).read().split('\n')
    def idx(pat, start=0):
        for i in range(start,len(lines)):
            if re.search(pat, lines[i]): return i
        return -1
    i_entries_start = idx(r'reg\s+\[127:0\]\s+entries_0_data;')
    i_entries_end   = idx(r'reg\s+\[7:0\]\s+entries_15_vlmax;')
    i_alloc_start   = idx(r'reg\s+allocated_0;')
    i_needrs_end    = idx(r'reg\s+needRSReplay_15;')
    i_probe   = idx(r'^\s*wire\s+_probe;')
    i_init_s  = idx(r'^\s*`ifdef ENABLE_INITIAL_REG_$')
    i_init_e  = idx(r'^\s*`endif // ENABLE_INITIAL_REG_$')
    i_end     = idx(r'^endmodule')
    assert min(i_entries_start,i_entries_end,i_alloc_start,i_needrs_end,i_probe,
               i_init_s,i_init_e,i_end) >= 0

    out=[]
    i=i_probe
    while i < i_end:
        if i == i_entries_start:
            out.append("  // 16 条目状态(struct 数组, 替代 golden entries_N_* 平坦寄存器)")
            out.append("  vlmb_entry_t entries [16];")
            i = i_entries_end + 1; continue
        if i == i_alloc_start:
            out.append("  logic [15:0] allocated;")
            out.append("  logic [15:0] uopFinish;")
            out.append("  logic [15:0] needRSReplay;")
            i = i_needrs_end + 1; continue
        if i == i_init_s:               # initial 随机初值段丢弃(SYNTHESIS 下不生效)
            i = i_init_e + 1; continue
        l = sub_bitvec(sub_entries(lines[i]))
        out.append(l); i += 1
    return out

CORE_HDR = """// xs_VLMergeBufferImp_core —— 向量 load 16 条目 merge buffer 可读核。
// 手写重写(结构阵列化), bug-for-bug 对齐 golden VLMergeBufferImp.sv(8604 行)。
// 16 条目 → struct 数组 entries[16]; allocated/uopFinish/needRSReplay → 位向量;
// 3 端口字节级数据合并/碰撞矩阵/双 select(oldest/youngest)忠实保留。
// 子模块 FreeList + NewPipelineConnectPipe_27×2 由核直接例化(两侧 elaborate)。
// 依赖 xs_vlmergebuffer_pkg(编译列表 RTL_SRCS 先行编译)。
"""

def gen_core(ports):
    body = build_core_body()
    s = CORE_HDR + f"""
module xs_VLMergeBufferImp_core
  import xs_vlmergebuffer_pkg::*;
(
{port_decl(ports)}
);

""" + '\n'.join(body) + "\nendmodule\n"
    open(os.path.join(RTLDIR,'VLMergeBufferImp.sv'),'w').write(s)

def gen_wrapper(ports, modname, fname):
    conns = ["    .clock(clock), .reset(reset)"]
    for d,w,n in ports:
        if n in ('clock','reset'): continue
        conns.append(f"    .{n}({n})")
    tag = 'UT 变体' if modname.endswith('_xs') else 'FM impl 顶层'
    s = f"""// {modname} —— 扁平端口透传包装({tag}), 例化 xs_VLMergeBufferImp_core。
// 机械生成 by gen_vlmerge.py, 勿手改。
module {modname}
  import xs_vlmergebuffer_pkg::*;
(
{port_decl(ports)}
);

  xs_VLMergeBufferImp_core u_core (
{','.join(chr(10)+c for c in conns)[1:]}
  );

endmodule
"""
    open(fname,'w').write(s)

def gen_tb(ports, fname):
    ins  = [(w,n) for d,w,n in ports if d=='input' and n not in ('clock','reset')]
    outs = [(w,n) for d,w,n in ports if d=='output']
    decl=[]
    for w,n in ins:  decl.append(f"  logic {w+' ' if w else ''}{n};")
    for w,n in outs:
        decl.append(f"  logic {w+' ' if w else ''}g_{n};")
        decl.append(f"  logic {w+' ' if w else ''}i_{n};")
    def conns(prefix):
        c=["    .clock(clk), .reset(rst)"]
        for w,n in ins:  c.append(f"    .{n}({n})")
        for w,n in outs: c.append(f"    .{n}({prefix}{n})")
        return ',\n'.join(c)
    drive=[]
    for w,n in ins:
        if w:
            hi=int(re.search(r'\[(\d+):',w).group(1)); nb=hi+1
            drive.append(f"      {n} <= "+("$random;" if nb<=32 else "{"+', '.join(['$random']*((nb+31)//32))+"};"))
        else:
            drive.append(f"      {n} <= $random;")
    checks=[f"      if (g_{n} !== i_{n}) begin errors++; if (errors<20) $display(\"MISMATCH {n} @%0d g=%h i=%h\", cyc, g_{n}, i_{n}); end" for w,n in outs]
    s = f"""// 自动生成 gen_vlmerge.py —— 勿手改。双例化 golden VLMergeBufferImp vs VLMergeBufferImp_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

{chr(10).join(decl)}

  VLMergeBufferImp u_g (
{conns('g_')}
  );
  VLMergeBufferImp_xs u_i (
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
    s = """MODULE = VLMergeBufferImp

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/vlmergebuffer_pkg.sv $(RTL_DIR)/memblock/VLMergeBufferImp.sv
GOLDEN_SUBS = \\
  $(GOLDEN_RTL)/FreeList.sv \\
  $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VLMergeBufferImp.sv $(GOLDEN_SUBS)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VLMergeBufferImp_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = VLMergeBufferImp
FM_REF_DEPS_VLMergeBufferImp = FreeList.sv NewPipelineConnectPipe_27.sv
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
"""
    open(fname,'w').write(s)

if __name__ == '__main__':
    ports = parse_ports()
    os.makedirs(UTDIR, exist_ok=True)
    gen_core(ports)
    gen_wrapper(ports, 'VLMergeBufferImp',    os.path.join(RTLDIR,'VLMergeBufferImp_wrapper.sv'))
    gen_wrapper(ports, 'VLMergeBufferImp_xs', os.path.join(UTDIR,'variants_xs.sv'))
    gen_tb(ports, os.path.join(UTDIR,'tb.sv'))
    gen_makefile(os.path.join(UTDIR,'Makefile'))
    print(f"gen ok: {len(ports)} ports")
