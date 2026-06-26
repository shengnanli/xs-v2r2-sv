#!/usr/bin/env python3
"""
XSTile(tile 级:XSCore + L2 + tile 互联)生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
XSTile(src/main/scala/xiangshan/XSTile.scala,class XSTileImp)是 tile 顶层:
在已重写的单核 XSCore 之上绑定 L2 cache(L2Top)与中断缓冲(IntBuffer),
并把 tile 边界的 CHI 总线 / 中断 / TLB / trace / debug-topdown 全部拉直对外。
仅例化 3 个子模块并互联——
  core      (XSCore)   单核(前端+后端+访存,**已重写,本层 golden 黑盒**)
  l2top     (L2Top)    L2 cache + TileLink<->CHI 桥 + CLINT/PLIC/IMSIC 中断对接
  intBuffer (IntBuffer)中断单 bit 缓冲(beu local int 汇聚到 PLIC)
这 3 个子模块对本层都是 golden 黑盒(UT/FM 两侧共用)。

XSTile 本身**纯互联层**:Scala 里全是 `<>` / `:=` 连线(core<->l2 的 TileLink
client/ptw、中断分发、msiInfo/clintTime/reset_vector/hartId 经 l2 转发给 core、
trace/debug-topdown 透传)。golden XSTile.sv 全文实测:
  `_T_`/`_GEN_`/`inner_` 临时名 = 0,reg/always = 0,顶层时序 glue = 0;
  顶层组合 glue 也 = 0(没有任何带运算的引脚 rhs / 带运算的 assign)。
唯一的「顶层逻辑」是 2 条把 core 输出直连 io 的 assign(纯连线):
  assign io_debugTopDown_robHeadPaddr_valid = _core_io_debugTopDown_robHeadPaddr_valid;
  assign io_debugTopDown_robHeadPaddr_bits  = _core_io_debugTopDown_robHeadPaddr_bits;
即:本层比 XSCore 还薄(XSCore 尚有 3 处 BEU/pf 组合 glue,XSTile 一处都没有)。

子模块例化里有 2 个故意悬空的输入引脚(L2Top 的 io_l2_flush_en / io_power_down_en
写作 `(/* unused */)`),本脚本将其落成显式不连接 `( )`(SV 合法悬空端口)。

机械部分由本脚本生成(同 gen_xscore.py 套路):
  rtl/xstile/xstile_ports.svh   —— 可读核扁平端口表(与 golden XSTile 同名)
  rtl/xstile/xstile_decls.svh   —— 3 子模块黑盒输出/互联网声明(宽度从 golden 收割)
  rtl/xstile/xstile_inst.svh    —— 3 子模块黑盒例化 + 引脚连核内具名信号/互联网
  rtl/xstile/xstile_outassign.svh—— 顶层 io 输出 assign(直连子模块输出,纯连线)
  rtl/xstile/XSTile_wrapper.sv  —— golden 同名扁平 wrapper(FM/ST 用)
  rtl/xstile/xstile_blackbox_stubs.sv —— 3 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/XSTile/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}

可读核本体见 rtl/xstile/XSTile.sv,类型见 xstile_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/xstile"
UT = XSSV / "verif/ut/XSTile"
GSV = (GOLDEN / "XSTile.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_xstile.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")
# 引脚:.name (rhs) —— rhs 允许内含一层括号。
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")

# 子模块输出/互联网前缀(这些都是 wire,声明在 decls,inst 引脚直连)。
NET_RE = re.compile(r"\b_(?:core|l2top|intBuffer)_[A-Za-z0-9_]+\b")


# ----------------------------------------------------------------------------
# 引脚 rhs rewrite:XSTile 没有带运算的 glue,只需把悬空注释 `/* unused */`
# 落成合法悬空端口(空 rhs)。其余原样(纯互联网/io/常量)。
# ----------------------------------------------------------------------------
def rewrite_rhs(rhs):
    key = re.sub(r"\s+", " ", rhs.strip())
    if key == "" or key == "/* unused */":
        return ""  # 显式悬空端口 .pin ( )
    return key


def leftover_golden(rhs):
    """套壳门:rewrite 后不应残留任何 golden 临时名(_T_/_GEN_/inner_)。"""
    bad = []
    for t in _WORD.findall(rhs):
        if re.search(r"_GEN_\d|_T_\d", t) or (
                t.startswith("inner_") and not t.startswith("_inner_")):
            bad.append(t)
    return bad


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module XSTile\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden XSTile 同名扁平端口,供 FM/ST 对接)。",
         "// clock/reset 在核声明处单列,这里只列功能端口。"]
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d} {ww}{n},")
    for i in range(len(L) - 1, -1, -1):
        if L[i].endswith(","):
            L[i] = L[i][:-1]
            break
    (XC / "xstile_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取
# ----------------------------------------------------------------------------
def extract_instances():
    starts = [i for i, l in enumerate(LINES)
              if re.match(r"^  [A-Z][A-Za-z0-9_]+ +[a-z][A-Za-z0-9_]* +\($", l)]
    blocks = []
    for s in starts:
        e = s
        while not re.match(r"^  \);", LINES[e]):
            e += 1
        blocks.append((LINES[s], LINES[s:e + 1]))
    return blocks


def submodule_types():
    types = {}
    for head, _ in extract_instances():
        m = re.match(r"^  ([A-Z][A-Za-z0-9_]+) +([a-zA-Z_][A-Za-z0-9_]*) +\($", head)
        types.setdefault(m.group(1), []).append(m.group(2))
    return types


# ----------------------------------------------------------------------------
# 子模块互联网声明:从 golden wire 声明收割宽度
# ----------------------------------------------------------------------------
def _harvest_wire_widths():
    wm = {}
    for m in re.finditer(
            r"^  wire\s+(\[[\d:]+\](?:\[[\d:]+\])?\s+)?(_[A-Za-z0-9_]+);", GSV, re.M):
        wm[m.group(2)] = (m.group(1) or "").strip()
    return wm


def gen_decls(blocks, widths):
    """收集所有引脚/assign rhs 引用的互联网(_core_/_l2top_/_intBuffer_),声明之。"""
    used = set()
    for idt in NET_RE.findall(GSV):
        used.add(idt)
    to_decl = sorted(used)
    missing = [n for n in to_decl if n not in widths]
    L = [HDR,
         "// 3 子模块(core/l2top/intBuffer,golden 黑盒)输出/互联网声明,",
         "// 宽度从 golden wire 声明收割。由 xstile_inst.svh 绑定子模块输出引脚,",
         "// 互联直连 / outassign 消费。", ""]
    for n in to_decl:
        w = widths.get(n, "")
        L.append(f"  logic {w + ' ' if w else ''}{n};"
                 + ("" if w or n in widths else "   // 宽度未收割(按 1bit,请核对)"))
    (XC / "xstile_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(to_decl), missing=missing)


# ----------------------------------------------------------------------------
# gen_inst():3 子模块黑盒例化 + 引脚 rewrite
# ----------------------------------------------------------------------------
def gen_inst(blocks):
    L = [HDR,
         "// 3 子模块黑盒例化(XSCore/L2Top/IntBuffer)+ 引脚连核内具名信号。",
         "// 引脚 rhs:io_* 顶层端口 / _core_·_l2top_·_intBuffer_* 互联网 /",
         "// clock·reset 直连 / 常量 / 悬空端口(L2Top 的 flush_en/power_down_en)。", ""]
    leaks = 0
    unused = 0
    for head, lines in blocks:
        typ, inst = head.strip().split()[0], head.strip().split()[1]
        L.append(f"  {typ} {inst} (")
        pins = []
        for m in _PINRE.finditer("\n".join(lines)):
            pin = m.group(1)
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            nr = rewrite_rhs(rhs)
            if nr == "" and rhs != "":
                unused += 1
            bad = leftover_golden(nr)
            if bad:
                leaks += 1
                if leaks <= 8:
                    print(f"  LEAK {inst}.{pin}: {bad}")
            pins.append((pin, nr))
        for i, (pin, nr) in enumerate(pins):
            comma = "," if i < len(pins) - 1 else ""
            L.append(f"    .{pin} ({nr}){comma}")
        L.append("  );")
    (XC / "xstile_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks, unused=unused)


# ----------------------------------------------------------------------------
# xstile_outassign.svh:顶层 io 输出驱动(golden 末尾 assign io_=...)
# ----------------------------------------------------------------------------
def gen_outassign():
    assigns = re.findall(r"^  assign (io_\w+)\s*=\s*((?:[^;])*);", GSV, re.M)
    L = [HDR,
         "// 顶层 io 输出 assign:子模块黑盒输出直连顶层 io(XSTile 全是纯连线)。", ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        nr = rewrite_rhs(rhs)
        if leftover_golden(nr):
            leaks += 1
        L.append(f"  assign {lhs} = {nr};")
    (XC / "xstile_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# XSTile_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_XSTile_core。",
         "module XSTile(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_XSTile_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "XSTile_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 3 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
         "// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。", ""]
    for t in sorted(types):
        gf = GOLDEN / f"{t}.sv"
        if not gf.exists():
            L.append(f"// !! golden {t}.sv 缺失,跳过 stub")
            continue
        g = gf.read_text()
        m = re.search(rf"^module {re.escape(t)}\((.*?)\n\);", g, re.S | re.M)
        if not m:
            L.append(f"// !! 无法解析 {t} 端口,跳过")
            continue
        hdr = m.group(1)
        ports = []
        for line in hdr.splitlines():
            pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
            if pm:
                ports.append((pm.group(1),
                              int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        L.append(f"module {t}(")
        for i, (d, w, n) in enumerate(ports):
            comma = "," if i < len(ports) - 1 else ""
            ww = "" if w == 1 else f"[{w - 1}:0] "
            L.append(f"  {d}  {ww}{n}{comma}")
        L.append(");")
        for d, w, n in ports:
            if d == "output":
                L.append(f"  assign {n} = '0;")
        L.append("endmodule\n")
    (XC / "xstile_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# golden 叶子传递闭包(同 gen_xscore.py:-f 每文件一次,规避 -y 自包含 pkg 冲突)
# ----------------------------------------------------------------------------
_MODDEF = re.compile(r"^module\s+([A-Za-z_]\w*)\b", re.M)
_INSTREF = re.compile(r"^\s{2,}([A-Za-z_]\w*)\s+[\\A-Za-z_]\S*\s*\(", re.M)
_KW = {"if", "for", "case", "begin", "end", "assign", "wire", "reg", "logic",
       "always", "module", "endmodule", "input", "output", "inout", "parameter",
       "localparam", "generate", "endgenerate", "initial", "final", "function",
       "task", "package", "import", "typedef", "struct", "enum", "union",
       "genvar", "integer", "real", "supply0", "supply1", "tri", "wand", "wor",
       "posedge", "negedge", "else", "while", "repeat", "forever", "do",
       "return", "break", "continue", "fork", "join", "wait", "disable", "force",
       "release", "assert", "assume", "cover", "property", "sequence"}


def _golden_modfile_map():
    modfile = {}
    for f in sorted(GOLDEN.glob("*.sv")) + sorted(GOLDEN.glob("*.v")):
        try:
            txt = f.read_text(errors="ignore")
        except OSError:
            continue
        for m in _MODDEF.finditer(txt):
            modfile.setdefault(m.group(1), f)
    return modfile


def golden_closure(tops):
    modfile = _golden_modfile_map()
    seen, files, missing, stack = set(), set(), set(), list(tops)
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        f = modfile.get(mod)
        if not f:
            missing.add(mod)
            continue
        files.add(f)
        for m in _INSTREF.finditer(f.read_text(errors="ignore")):
            t = m.group(1)
            if t not in _KW and t not in seen and t in modfile:
                stack.append(t)
    return sorted(files), sorted(missing), len(seen - missing)


def gen_filelist(tops):
    rel = "../../../golden/chisel-rtl"
    files, missing, nmod = golden_closure(tops)
    L = ["// 自动生成:scripts/gen_xstile.py —— golden 叶子传递闭包文件列表(每文件一次)",
         f"// 顶: {' '.join(tops)};模块数={nmod};文件数={len(files)}",
         "// 用 -f 显式编译,规避 -y 对自包含 pkg+module 文件的重复声明冲突。"]
    for f in files:
        L.append(f"{rel}/{f.name}")
    (UT / "golden_filelist.f").write_text("\n".join(L) + "\n")
    return dict(nmod=nmod, nfiles=len(files), missing=missing)


# ----------------------------------------------------------------------------
# UT:tb.sv / variants_xs.sv / Makefile
# ----------------------------------------------------------------------------
def wdecl(w):
    return "" if w == 1 else f"[{w - 1}:0] "


def gen_ut(ports, types):
    UT.mkdir(parents=True, exist_ok=True)
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    ins = [p for p in pl if p[0] == "input"]
    outs = [p for p in pl if p[0] == "output"]

    # variants_xs.sv:XSTile_xs(golden 同名扁平端口)-> 核
    L = [HDR, "module XSTile_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_XSTile_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(L) + "\n")

    # tb.sv:双例化逐拍比对 golden 全部输出
    T = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for d, w, n in ins:
        T.append(f"  logic {wdecl(w)}{n};")
    for d, w, n in outs:
        T.append(f"  wire {wdecl(w)}g_{n};")
        T.append(f"  wire {wdecl(w)}i_{n};")
    T.append("")

    def conn(prefix_out):
        items = [".clock(clk)", ".reset(rst)"]
        for d, w, n in pl:
            if d == "input":
                items.append(f".{n}({n})")
            else:
                items.append(f".{n}({prefix_out}{n})")
        return ", ".join(items)

    T.append(f"  XSTile    u_g ({conn('g_')});")
    T.append(f"  XSTile_xs u_i ({conn('i_')});")
    T.append("")
    T.append(f"  bit reported [0:{len(outs) - 1}];")
    T.append("  int distinct_div = 0;")
    T.append("")
    # 随机驱动
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for d, w, n in ins:
        if n.endswith("_valid") or n.endswith("_ready"):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for d, w, n in ins:
        if w == 1:
            T.append(f"      {n} <= $urandom_range(0,1);")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        elif w <= 64:
            T.append(f"      {n} <= {{$urandom(), $urandom()}};")
        else:
            chunks = (w + 31) // 32
            cat = ", ".join(["$urandom()"] * chunks)
            T.append(f"      {n} <= {{{cat}}};")
    T.append("    end")
    T.append("  end")
    T.append("")
    # 比对(仅当 golden 输出非 X 才比,避开 flush-X/未驱动)
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for k, (d, w, n) in enumerate(outs):
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(!reported[{k}]) begin reported[{k}]=1; distinct_div++;")
        T.append(f"        $display(\"[DIV %0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end end")
    T.append("  end")
    T.append("")
    T.append("  initial begin")
    T.append("    if (!$value$plusargs(\"NCYCLES=%d\", NCYCLES)) NCYCLES = 200000;")
    T.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    T.append("    repeat (NCYCLES) @(posedge clk);")
    T.append(f"    $display(\"distinct_diverging_ports=%0d / %0d\", distinct_div, {len(outs)});")
    T.append("    $display(\"checks=%0d errors=%0d\", checks, errors);")
    T.append("    if (errors == 0 && checks > 1000) $display(\"TEST PASSED\"); "
             "else $display(\"TEST FAILED\");")
    T.append("    $finish;")
    T.append("  end")
    T.append("endmodule")
    (UT / "tb.sv").write_text("\n".join(T) + "\n")

    # Makefile —— 用 golden 叶子传递闭包文件列表(-f),规避 -y 自包含 pkg 冲突。
    sub_deps = " ".join(f"$(GOLDEN_RTL)/{t}.sv" for t in sorted(types))
    fm_ref = " ".join(f"{t}.sv" for t in sorted(types))
    txt = f"""# 自动生成:scripts/gen_xstile.py —— 勿手改
MODULE = XSTile

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xstile/xstile_pkg.sv \\
           $(RTL_DIR)/xstile/XSTile.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSTile.sv + 3 子模块(XSCore/L2Top/IntBuffer)的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSTile.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = {sub_deps}

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化 3 子模块。
WRAPPER_SRCS = $(RTL_DIR)/xstile/XSTile_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = XSTile
FM_REF_DEPS_XSTile = {fm_ref}

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstile
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable
"""
    (UT / "Makefile").write_text(txt)
    return len(ins), len(outs)


def main():
    XC.mkdir(parents=True, exist_ok=True)
    UT.mkdir(parents=True, exist_ok=True)
    ps = top_ports()
    gen_ports(ps)
    types = submodule_types()
    print(f"ports: {len(ps)}  submodule types: {len(types)}  instances: "
          f"{sum(len(v) for v in types.values())}")
    blocks = extract_instances()
    widths = _harvest_wire_widths()
    d = gen_decls(blocks, widths)
    print(f"[decls] {d['nets']} interconnect nets, missing-width={len(d['missing'])}"
          + (": " + ", ".join(d["missing"][:8]) if d["missing"] else ""))
    r = gen_inst(blocks)
    print(f"[inst] {r['insts']} instances, golden-temp leaks={r['leaks']}, "
          f"unused(dangling) pins={r['unused']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io output assigns, golden-temp leaks={oa['leaks']}")
    gen_wrapper(ps)
    gen_stubs(types)
    fl = gen_filelist(sorted(types))
    print(f"[filelist] golden closure: {fl['nmod']} modules, {fl['nfiles']} files"
          + (f", MISSING={fl['missing'][:10]}" if fl['missing'] else ", missing=0"))
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
