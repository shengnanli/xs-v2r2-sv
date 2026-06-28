#!/usr/bin/env python3
"""
OpenLLC(L3 CHI home node / Last-Level Cache)装配层生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
OpenLLC(openLLC/src/main/scala/openLLC/OpenLLC.scala,class OpenLLC)是香山外挂的
**独立 L3 缓存 IP**:一个 CHI 协议的 home node。它把若干 LLC slice(cache 流水 + 目录
+ 数据 + snoop filter)与一圈 CHI 互联/链路器件拼起来,北侧接 core 集群(RN,Request
Node,经 CHI),南侧接内存(SN,Subordinate Node,NoSnp 端口)。

本层是**纯互联壳 + 单一打拍寄存器**——除了 io_l3Miss 的一拍寄存(RegNext)外没有任何
数据通路逻辑。golden OpenLLC.sv 全文实测:`_T_<n>`/`_GEN_<n>`/`_REG_<编号>` 匿名临时名
= 0;reg 仅 1 个(io_l3Miss_REG,具名);always 块仅 1 个;assign 仅 3 条;带运算的
引脚 rhs = 0(1983 个引脚全是 io_* 端口 / _<inst>_io_* 互联网 / clock / reset 直连,
无任何拼接/位选/常量/悬空)。即本层逻辑 = 互联布线 + 1 拍 l3Miss 汇聚寄存。

子模块(8 种类型 / 11 个实例,本层全部 golden 黑盒,UT/FM 两侧共用):
  Slice_4          ×4   LLC slice(cache 流水:RequestArb/MainPipe/Directory/
                        DataStorage/MSHR/snoop filter),banks=4 每 bank 一个。
  RNXbar           ×1   RN 侧 CHI 交叉开关:把各 RN 的 cacheable 请求按地址路由到 slice。
  SNXbar           ×1   SN 侧 CHI 交叉开关:把各 slice 的访存请求汇聚到内存侧。
  MMIODiverger     ×1   按地址把每个 RN 的流量分流为 cacheable(进 rnXbar/slice)与
                        uncacheable(MMIO,绕过缓存直送 mmioMerger)。
  MMIOMerger       ×1   把 cacheable(snXbar 出)与 uncacheable(MMIO)两路合并送 SN。
  RNLinkMonitor    ×1   RN 侧 CHI 链路层监视(linkactive 握手 / lcredit 信用流控)。
  SNLinkMonitor    ×1   SN 侧 CHI 链路层监视。
  TopDownMonitor_1 ×1   性能/调试监视(读各 slice 的 msStatus,产生 debugTopDown.addrMatch)。

连接拓扑(见 Scala class OpenLLC):
  io.rn(i) <-> rnLinkMonitor <-> mmioDiverger.in(i)
  mmioDiverger.out.cache(i) -> rnXbar.in(i);  rnXbar.out(i) <-> slices(i).in
  slices(i).snpMask -> rnXbar.snpMasks(i);     slices(i).out -> snXbar.in(i)
  snXbar.out -> mmioMerger.in.cache;  mmioDiverger.out.uncache -> mmioMerger.in.uncache
  mmioMerger.out -> snLinkMonitor.in <-> io.sn
  topDown 读 slices.msStatus -> io.debugTopDown.addrMatch
  io.l3Miss = RegNext(OR(slices.l3Miss))   <-- 本层唯一时序 glue

机械部分由本脚本生成(同 gen_l2top.py 套路):
  rtl/l2/openllc_ports.svh    —— 可读核扁平端口表(与 golden OpenLLC 同名)
  rtl/l2/openllc_decls.svh    —— 子模块黑盒输出/互联网声明(宽度从 golden 收割)
  rtl/l2/openllc_glue.svh     —— 顶层 glue:io_l3Miss_REG 一拍汇聚寄存(唯一时序逻辑)
  rtl/l2/openllc_inst.svh     —— 11 子模块黑盒例化 + 引脚连核内具名信号/互联网
  rtl/l2/openllc_outassign.svh—— 顶层 io 输出 assign(3 条:probe/addrMatch/l3Miss)
  rtl/l2/OpenLLC_wrapper.sv   —— golden 同名扁平 wrapper(FM/ST 用)
  rtl/l2/openllc_blackbox_stubs.sv —— 8 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/OpenLLC/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}

可读核本体见 rtl/l2/OpenLLC.sv,类型/参数见 openllc_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/l2"
UT = XSSV / "verif/ut/OpenLLC"
GSV = (GOLDEN / "OpenLLC.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_openllc.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")
# 引脚:.name (rhs) —— rhs 允许内含一层括号。
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")


# ----------------------------------------------------------------------------
# 套壳门:rewrite 后不应残留任何 golden 匿名临时名(_T_<n> / _GEN_<n> / _REG_<n>)。
# ----------------------------------------------------------------------------
def leftover_golden(rhs):
    bad = []
    for t in _WORD.findall(rhs):
        if re.search(r"_GEN_\d|_T_\d|_REG_\d", t):
            bad.append(t)
    return bad


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module OpenLLC\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden OpenLLC 同名扁平端口,供 FM/ST 对接)。",
         "// clock/reset 在核声明处单列,这里只列功能端口。",
         "//   io_rn_0_*       北侧 CHI RN 端口(接 core 集群,tx=core->LLC, rx=LLC->core)",
         "//   io_sn_*         南侧 CHI SN 端口(NoSnp,接内存)",
         "//   io_debugTopDown_* 调试/性能监视接口",
         "//   io_l3Miss       L3 整体 miss 指示(各 slice miss 汇聚一拍)"]
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d} {ww}{n},")
    for i in range(len(L) - 1, -1, -1):
        if L[i].endswith(","):
            L[i] = L[i][:-1]
            break
    (XC / "openllc_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取(head 形如 `  Type  inst (`)
# ----------------------------------------------------------------------------
def extract_instances():
    starts = [i for i, l in enumerate(LINES)
              if re.match(r"^  [A-Z][A-Za-z0-9_]+ +[a-zA-Z_][A-Za-z0-9_]* +\($", l)]
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
# 子模块互联网声明:从 golden wire 声明收割宽度。
#   OpenLLC 的 wire 声明全部是「不带初值」的 _<inst>_io_* 子模块输出网(+ _probe),
#   无任何改名/直通(无 `wire X = Y`)。整段原样收割宽度。
# ----------------------------------------------------------------------------
def gen_decls():
    decls = []
    for m in re.finditer(
            r"^  wire\s+(\[[\d:]+\](?:\[[\d:]+\])?\s+)?(_[A-Za-z0-9_]+);$",
            GSV, re.M):
        w = (m.group(1) or "").strip()
        decls.append((w, m.group(2)))
    L = [HDR,
         "// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "//   _<inst>_io_*  : 子模块输出引脚网(slice/xbar/linkmon/mmio 之间的 CHI 互联);",
         "//   _probe        : difftest/dontTouch 探针(_topDown 的 addrMatch 镜像)。",
         "// 由 openllc_inst.svh 绑定子模块输出引脚,互联直连 / outassign 消费。", ""]
    for w, n in decls:
        L.append(f"  logic {w + ' ' if w else ''}{n};")
    (XC / "openllc_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(decls))


# ----------------------------------------------------------------------------
# 顶层 glue:io_l3Miss_REG 一拍汇聚寄存(本层唯一时序逻辑)。
#   io.l3Miss := RegNext(Cat(slices.map(_.io.l3Miss)).orR)
#   从 reg 声明行起、到 always 块赋值语句结束(以 `;` 收尾)止,整段原样搬运。
# ----------------------------------------------------------------------------
def gen_glue():
    reg_start = next(i for i, l in enumerate(LINES)
                     if re.match(r"^  reg .*io_l3Miss_REG;", l))
    # always 块为单条非阻塞赋值(无 begin/end),延伸到首个以 `;` 收尾的行。
    j = reg_start + 1
    assert LINES[j].lstrip().startswith("always")
    while not LINES[j].rstrip().endswith(";"):
        j += 1
    seq_block = LINES[reg_start:j + 1]

    L = [HDR,
         "// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,原样保留)=====",
         "// 本层唯一时序逻辑:io.l3Miss := RegNext(OR(各 slice 的 l3Miss))。",
         "// 4 个 slice 的 l3Miss 按位或后打一拍寄存,作为 L3 整体 miss 指示输出。", ""]
    leaks = 0
    for ln in seq_block:
        L.append(ln)
        if leftover_golden(ln):
            leaks += 1
    (XC / "openllc_glue.svh").write_text("\n".join(L) + "\n")
    return dict(seq_lines=len(seq_block), leaks=leaks)


# ----------------------------------------------------------------------------
# gen_inst():11 子模块黑盒例化 + 引脚 rewrite。
#   引脚 rhs:io_* 顶层端口 / _<inst>_io_* 互联网 / clock·reset 直连。全部无运算、无悬空。
# ----------------------------------------------------------------------------
def rewrite_rhs(rhs):
    key = re.sub(r"\s+", " ", rhs.strip())
    if key == "" or key == "/* unused */":
        return ""  # 显式悬空端口 .pin ( )
    return key


def gen_inst(blocks):
    L = [HDR,
         "// 11 子模块黑盒例化(8 种类型)+ 引脚连核内具名信号/互联网。",
         "// 引脚 rhs:io_* 顶层端口 / _<inst>_io_* 互联网 / clock·reset 直连(无运算/无悬空)。", ""]
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
    (XC / "openllc_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks, unused=unused)


# ----------------------------------------------------------------------------
# openllc_outassign.svh:顶层 io 输出驱动 + probe assign(共 3 条)。
#   assign _probe = _topDown_..._addrMatch_0;            (difftest 探针,内部 dontTouch)
#   assign io_debugTopDown_addrMatch_0 = _topDown_...;   (topDown 输出直通)
#   assign io_l3Miss = io_l3Miss_REG;                    (打拍后的 l3Miss 输出)
# ----------------------------------------------------------------------------
def gen_outassign():
    assigns = re.findall(r"^  assign (_probe|io_\w+)\s*=\s*(.*?);",
                         GSV, re.M | re.S)
    L = [HDR,
         "// 顶层 io 输出 assign + probe(共 3 条,全部纯连线无运算)。",
         "//   _probe                      : difftest/dontTouch 探针(topDown.addrMatch 镜像);",
         "//   io_debugTopDown_addrMatch_0 : topDown 输出直通;",
         "//   io_l3Miss                   : 打拍后的 l3Miss 输出。", ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        if leftover_golden(rhs):
            leaks += 1
        L.append(f"  assign {lhs} = {rhs};")
    (XC / "openllc_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# OpenLLC_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_OpenLLC_core。",
         "module OpenLLC(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_OpenLLC_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "OpenLLC_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs(空体,所有 output 驱 0)—— 仅备快速 elaborate,UT/FM 用 golden 真定义
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 8 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
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
    (XC / "openllc_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# golden 叶子传递闭包(同 gen_l2top.py:-f 每文件一次,规避 -y 自包含 pkg 冲突)
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
    L = ["// 自动生成:scripts/gen_openllc.py —— golden 叶子传递闭包文件列表(每文件一次)",
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

    # variants_xs.sv:OpenLLC_xs(golden 同名扁平端口)-> 核
    L = [HDR, "module OpenLLC_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_OpenLLC_core u_core (")
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

    T.append(f"  OpenLLC    u_g ({conn('g_')});")
    T.append(f"  OpenLLC_xs u_i ({conn('i_')});")
    T.append("")
    T.append(f"  bit reported [0:{len(outs) - 1}];")
    T.append("  int distinct_div = 0;")
    T.append("")
    # 随机驱动
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for d, w, n in ins:
        if n.endswith("_valid") or n.endswith("_ready") or n.endswith("flitv") \
                or n.endswith("lcrdv") or n.endswith("flitpend"):
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
    txt = f"""# 自动生成:scripts/gen_openllc.py —— 勿手改
MODULE = OpenLLC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/openllc_pkg.sv \\
           $(RTL_DIR)/l2/OpenLLC.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 OpenLLC.sv + 8 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/OpenLLC.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = {sub_deps}

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/l2/OpenLLC_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = OpenLLC
FM_REF_DEPS_OpenLLC = {fm_ref}

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
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
    d = gen_decls()
    print(f"[decls] {d['nets']} interconnect nets")
    g = gen_glue()
    print(f"[glue] {g['seq_lines']} seq lines (1 always: l3Miss RegNext), "
          f"golden-temp leaks={g['leaks']}")
    blocks = extract_instances()
    r = gen_inst(blocks)
    print(f"[inst] {r['insts']} instances, golden-temp leaks={r['leaks']}, "
          f"unused(dangling) pins={r['unused']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io output/probe assigns, golden-temp leaks={oa['leaks']}")
    gen_wrapper(ps)
    gen_stubs(types)
    fl = gen_filelist(["OpenLLC"])
    print(f"[filelist] golden closure: {fl['nmod']} modules, {fl['nfiles']} files"
          + (f", MISSING={fl['missing'][:10]}" if fl['missing'] else ", missing=0"))
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
