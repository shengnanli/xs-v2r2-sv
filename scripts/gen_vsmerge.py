#!/usr/bin/env python3
# gen_vsmerge.py —— 从 golden VSMergeBufferImp.sv 端口列表机械派生:
#   - VSMergeBufferImp_wrapper.sv (扁平端口 FM impl 顶层, 例化 xs_VSMergeBufferImp_core
#                                  + FreeList_1 + NewPipelineConnectPipe_27)
#   - variants_xs.sv              (UT 用, 顶层名 VSMergeBufferImp_xs, 同 wrapper 结构)
#   - tb.sv                       (双例化 golden vs _xs 逐拍比对)
#   - Makefile                    (AUX FM, 两侧 elaborate 2 子模块)
import re, os

XSSV   = "/home/eda/xs-env/xs-mb-merge"
GOLDEN = os.path.join(XSSV, "golden/chisel-rtl/VSMergeBufferImp.sv")
RTLDIR = os.path.join(XSSV, "rtl/memblock")
UTDIR  = os.path.join(XSSV, "verif/ut/VSMergeBufferImp")

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

# ---- pipelineConnect(NewPipelineConnectPipe_27)io_in payload 字段(核 pc_in_* 驱动)
PC_IN = [
  ('exceptionVec_3','pc_in_uop_exceptionVec_3'),('exceptionVec_6','pc_in_uop_exceptionVec_6'),
  ('exceptionVec_7','pc_in_uop_exceptionVec_7'),('exceptionVec_15','pc_in_uop_exceptionVec_15'),
  ('exceptionVec_19','pc_in_uop_exceptionVec_19'),('exceptionVec_23','pc_in_uop_exceptionVec_23'),
  ('trigger','pc_in_uop_trigger'),('fuOpType','pc_in_uop_fuOpType'),
  ('vecWen','pc_in_uop_vecWen'),('v0Wen','pc_in_uop_v0Wen'),('vlWen','pc_in_uop_vlWen'),
  ('flushPipe','pc_in_uop_flushPipe'),('vpu_vma','pc_in_uop_vpu_vma'),('vpu_vta','pc_in_uop_vpu_vta'),
  ('vpu_vsew','pc_in_uop_vpu_vsew'),('vpu_vlmul','pc_in_uop_vpu_vlmul'),('vpu_vm','pc_in_uop_vpu_vm'),
  ('vpu_vstart','pc_in_uop_vpu_vstart'),('vpu_vuopIdx','pc_in_uop_vpu_vuopIdx'),
  ('vpu_vmask','pc_in_uop_vpu_vmask'),('vpu_vl','pc_in_uop_vpu_vl'),('vpu_nf','pc_in_uop_vpu_nf'),
  ('vpu_veew','pc_in_uop_vpu_veew'),('pdest','pc_in_uop_pdest'),
  ('robIdx_flag','pc_in_uop_robIdx_flag'),('robIdx_value','pc_in_uop_robIdx_value'),
  ('debugInfo_enqRsTime','pc_in_uop_debugInfo_enqRsTime'),
  ('debugInfo_selectTime','pc_in_uop_debugInfo_selectTime'),
  ('debugInfo_issueTime','pc_in_uop_debugInfo_issueTime'),('replayInst','pc_in_uop_replayInst'),
]
# io_out payload -> 顶层 io_uopWriteback_0_bits_uop_* (直连)
PC_OUT_UOP = [
  'exceptionVec_3','exceptionVec_6','exceptionVec_7','exceptionVec_15','exceptionVec_19',
  'exceptionVec_23','trigger','fuOpType','vecWen','v0Wen','vlWen','flushPipe','vpu_vma',
  'vpu_vta','vpu_vsew','vpu_vlmul','vpu_vm','vpu_vstart','vpu_vuopIdx','vpu_vmask','vpu_vl',
  'vpu_nf','vpu_veew','pdest','robIdx_flag','robIdx_value','debugInfo_enqRsTime',
  'debugInfo_selectTime','debugInfo_issueTime','replayInst',
]

def gen_wrapper(ports, modname, fname):
    core = "xs_VSMergeBufferImp_core"
    # 核连接: 端口列表里凡是 core 也有的信号直连;不含 uopWriteback payload(pipe 直连)。
    core_direct = [n for _,_,n in ports
                   if not n.startswith('io_uopWriteback')
                   and n not in ('clock','reset')]
    conns = ["    .clock(clock), .reset(reset)"]
    for n in core_direct:
        conns.append(f"    .{n}({n})")
    # uopWriteback_0_ready -> pipe io_out_ready
    # 子模块 glue 网
    conns += [
      "    .allocateSlot(allocateSlot)",
      "    .doAllocate(doAllocate)",
      "    .freeMaskVec(freeMaskVec)",
      "    .validCount(validCount)",
      "    .pc_in_valid(pc_in_valid)",
      "    .pc_in_ready(pc_in_ready)",
      "    .pc_isFlush(pc_isFlush)",
      "    .pc_out_robIdx_flag(io_uopWriteback_0_bits_uop_robIdx_flag)",
      "    .pc_out_robIdx_value(io_uopWriteback_0_bits_uop_robIdx_value)",
    ]
    for _,pn in PC_IN:
        conns.append(f"    .{pn}({pn})")
    core_inst = f"  {core} u_core (\n" + ',\n'.join(conns) + "\n  );"

    # 子模块网声明
    nets = """  // 子模块 glue 网
  wire [3:0]   allocateSlot;
  wire         doAllocate;
  wire [15:0]  freeMaskVec;
  wire [4:0]   validCount;
  wire         pc_in_valid;
  wire         pc_in_ready;
  wire         pc_isFlush;"""
    for _,pn in PC_IN:
        # 位宽从 core 声明推(与 golden io_in 一致)
        pass
    pc_in_decl = []
    WIDTH = {'trigger':'[3:0]','fuOpType':'[8:0]','vpu_vsew':'[1:0]','vpu_vlmul':'[2:0]',
             'vpu_vstart':'[7:0]','vpu_vuopIdx':'[6:0]','vpu_vmask':'[127:0]','vpu_vl':'[7:0]',
             'vpu_nf':'[2:0]','vpu_veew':'[1:0]','pdest':'[7:0]','robIdx_value':'[7:0]',
             'debugInfo_enqRsTime':'[63:0]','debugInfo_selectTime':'[63:0]',
             'debugInfo_issueTime':'[63:0]'}
    for fld,pn in PC_IN:
        w = WIDTH.get(fld,'')
        pc_in_decl.append(f"  wire {w+' ' if w else ''}{pn};")
    nets += "\n" + "\n".join(pc_in_decl)

    # FreeList_1 例化
    freelist = """  FreeList_1 freeCount_freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (allocateSlot),
    .io_doAllocate_0   (doAllocate),
    .io_free           (freeMaskVec),
    .io_validCount     (validCount),
    .io_empty          (/* unused */)
  );"""

    # NewPipelineConnectPipe_27 例化
    pipe_conns = [
      "    .clock                                (clock)",
      "    .reset                                (reset)",
      "    .io_in_ready                          (pc_in_ready)",
      "    .io_in_valid                          (pc_in_valid)",
    ]
    # io_in_bits: 核驱动的接 pc_in_*, 未使用异常位/data/vdIdx 接常量(同 golden)
    IN_CONST = {
      'io_in_bits_uop_exceptionVec_4':"1'h0",'io_in_bits_uop_exceptionVec_5':"1'h0",
      'io_in_bits_uop_exceptionVec_13':"1'h0",'io_in_bits_uop_exceptionVec_21':"1'h0",
      'io_in_bits_data':"128'h0",'io_in_bits_vdIdx':"3'h0",'io_in_bits_vdIdxInField':"3'h0",
    }
    IN_MAP = {'io_in_bits_uop_'+fld: pn for fld,pn in PC_IN}
    pipe_ports = parse_ports(os.path.join(XSSV,"golden/chisel-rtl/NewPipelineConnectPipe_27.sv"),
                             "NewPipelineConnectPipe_27")
    for d,w,n in pipe_ports:
        if n in ('clock','reset','io_in_ready','io_in_valid'): continue
        if n == 'io_out_ready':
            pipe_conns.append(f"    .{n:<37}(io_uopWriteback_0_ready)"); continue
        if n == 'io_out_valid':
            pipe_conns.append(f"    .{n:<37}(io_uopWriteback_0_valid)"); continue
        if n == 'io_rightOutFire':
            pipe_conns.append(f"    .{n:<37}(io_uopWriteback_0_ready & io_uopWriteback_0_valid)"); continue
        if n == 'io_isFlush':
            pipe_conns.append(f"    .{n:<37}(pc_isFlush)"); continue
        if n in IN_CONST:
            pipe_conns.append(f"    .{n:<37}({IN_CONST[n]})"); continue
        if n in IN_MAP:
            pipe_conns.append(f"    .{n:<37}({IN_MAP[n]})"); continue
        # io_out_bits_*
        if n.startswith('io_out_bits_uop_'):
            fld = n[len('io_out_bits_uop_'):]
            if fld in PC_OUT_UOP:
                pipe_conns.append(f"    .{n:<37}(io_uopWriteback_0_bits_uop_{fld})"); continue
            else:
                pipe_conns.append(f"    .{n:<37}(/* unused */)"); continue
        if n.startswith('io_out_bits_'):
            fld = n[len('io_out_bits_'):]
            pipe_conns.append(f"    .{n:<37}(io_uopWriteback_0_bits_{fld})"); continue
        pipe_conns.append(f"    .{n:<37}(/* unused */)")
    pipe = "  NewPipelineConnectPipe_27 VMergebufferPipelineConnect0 (\n" + \
           ',\n'.join(pipe_conns) + "\n  );"

    tag = 'UT 变体' if modname.endswith('_xs') else 'FM impl 顶层'
    s = f"""// {modname} —— 扁平端口包装({tag}), 例化 xs_VSMergeBufferImp_core
// + FreeList_1 + NewPipelineConnectPipe_27(两侧同 elaborate 的 golden 子模块)。
// 机械生成 by gen_vsmerge.py, 勿手改。
module {modname}
  import xs_vsmergebuffer_pkg::*;
(
{port_decl(ports)}
);

{nets}

{core_inst}

{freelist}

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
    s = f"""// 自动生成 gen_vsmerge.py —— 勿手改。双例化 golden VSMergeBufferImp vs VSMergeBufferImp_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

{chr(10).join(decl)}

  VSMergeBufferImp u_g (
{conns('g_')}
  );
  VSMergeBufferImp_xs u_i (
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
    s = """MODULE = VSMergeBufferImp

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_VSMergeBufferImp_core(+ pkg) + 扁平端口包装 VSMergeBufferImp(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vsmergebuffer_pkg.sv $(RTL_DIR)/memblock/VSMergeBufferImp.sv
# golden 子模块闭包(FreeList_1 分配器 + NewPipelineConnectPipe_27 打拍), 两侧同 elaborate
GOLDEN_SUBS = \\
  $(GOLDEN_RTL)/FreeList_1.sv \\
  $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/VSMergeBufferImp.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VSMergeBufferImp_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VSMergeBufferImp 顶层 glue; 2 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = VSMergeBufferImp
FM_REF_DEPS_VSMergeBufferImp = FreeList_1.sv NewPipelineConnectPipe_27.sv

# 子模块含同构表项/流水寄存器, 关合并同值重复寄存器 pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
"""
    open(fname,'w').write(s)

if __name__ == '__main__':
    ports = parse_ports(GOLDEN, "VSMergeBufferImp")
    os.makedirs(UTDIR, exist_ok=True)
    gen_wrapper(ports, 'VSMergeBufferImp',    os.path.join(RTLDIR,'VSMergeBufferImp_wrapper.sv'))
    gen_wrapper(ports, 'VSMergeBufferImp_xs', os.path.join(UTDIR,'variants_xs.sv'))
    gen_tb(ports, os.path.join(UTDIR,'tb.sv'))
    gen_makefile(os.path.join(UTDIR,'Makefile'))
    print(f"gen ok: {len(ports)} ports")
