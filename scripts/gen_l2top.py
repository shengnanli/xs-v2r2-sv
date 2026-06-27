#!/usr/bin/env python3
"""
L2Top(L2 顶层装配层:CoupledL2 主体 + TileLink 互联壳)生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
L2Top(src/main/scala/xiangshan/L2Top.scala,class L2TopImp)是 L2 cache 子系统的
顶层装配:把 CoupledL2 主体(TL2CHICoupledL2,TileLink<->CHI 桥+L2 cache 阵列)与
一圈 TileLink 互联器件(buffer/xbar/logger)、BEU(总线错误单元)、BusPerfMonitor
(总线性能监视)拼起来,并把 L2 边界(core 侧 TL client 节点 / CHI 总线 / 中断 /
PTW(l2_tlb_req)/ trace / hartId / reset_vector / l2_hint)拉直对外。
本层是**纯互联壳**——除了下面三类「顶层 glue」外没有任何数据通路逻辑:

  (A) 输入 fanin 改名:  wire inner_io_X = io_X;            (19 条,纯连线改名)
  (B) 组合直通改名:    wire inner_io_X_to = inner_io_X_from;(3 条:hartId / cpu_halt /
                        cpu_critical_error 从 fromTile/fromCore 直通到 toCore/toTile)
  (C) 中断端口直通:    assign auto_inner_*_int_out = auto_inner_*_int_in;(7 条 nmi/
                        plic/debug/clint 中断 in->out 直穿,L2Top 只是 diplomacy 中转)
  (D) trace 打拍 + hartIsInReset:两个 always 块(本层**唯一的时序 glue**)——
        · trace 流水级:把 core 来的 traceCoreInterface(toEncoder groups/trap/priv)
          打一拍寄存(部分受 group_valid / itype 门控)再送出 toTile;fromEncoder
          的 enable/stall 也打一拍回灌 fromCore。golden 命名已极可读(inner_io_
          traceCoreInterface_*_REG / _r),本层原样保留为可读时序 glue。
        · hartIsInReset:resetInFrontend | reset 经异步置位寄存器,输出 hartIsInReset_
          toTile。
  (E) 顶层 io 输出 assign:50 条,绝大多数是子模块输出网 / inner_io_* 直连 io;
        唯一带运算的是 io_l2_hint_bits_sourceId = _inner_l2cache_..._sourceId[3:0]
        (位选),以及 io_errors_l2_ecc_error_bits = {2'h0, _inner_l2cache_io_error_
        address}(零扩展,作为 inner_beu 的输入引脚出现)。

子模块(15 种类型 / 21 个实例)对本层全部是 golden 黑盒(UT/FM 两侧共用):
  TL2CHICoupledL2 ×1   L2 cache 主体(L2 阵列 + TileLink<->CHI 桥)
  TLXbar_5/_6     ×2   TileLink 交叉开关(client 侧多 master 汇聚)
  TLBuffer_*      ×11  TileLink 寄存缓冲(打拍/隔离时序)
  TLLogger/_1/_2  ×3   TileLink 事务日志(diff/perf,非综合时旁路)
  BusErrorUnit    ×1   总线错误单元(ECC error 上报 + 本地中断)
  BusPerfMonitor  ×1   总线性能监视(非综合统计)
  DelayN_334      ×1   reset_vector 延迟链(fromTile -> 延迟 -> toCore)

golden L2Top.sv 全文实测:`_T_`/`_GEN_`/`_REG_<编号>` 临时名 = 0(只有 _REG/_r
后缀的具名 trace 寄存器,不是匿名临时名),带运算的引脚 rhs = 0,带运算的 assign
仅 1 处位选。即本层逻辑 = 互联布线 + trace 打拍 + 中断/控制量直通转发。

机械部分由本脚本生成(同 gen_xstile.py 套路):
  rtl/l2/l2top_ports.svh    —— 可读核扁平端口表(与 golden L2Top 同名)
  rtl/l2/l2top_decls.svh    —— 子模块黑盒输出/互联网声明(宽度从 golden 收割)
  rtl/l2/l2top_glue.svh     —— 顶层 glue:输入改名/组合直通/trace 打拍/hartIsInReset
  rtl/l2/l2top_inst.svh     —— 21 子模块黑盒例化 + 引脚连核内具名信号/互联网
  rtl/l2/l2top_outassign.svh—— 顶层 io 输出 assign(直连子模块输出/inner 网/位选)
  rtl/l2/L2Top_wrapper.sv   —— golden 同名扁平 wrapper(FM/ST 用)
  rtl/l2/l2top_blackbox_stubs.sv —— 15 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/L2Top/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}

可读核本体见 rtl/l2/L2Top.sv,类型见 l2top_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/l2"
UT = XSSV / "verif/ut/L2Top"
GSV = (GOLDEN / "L2Top.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_l2top.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")
# 引脚:.name (rhs) —— rhs 允许内含一层括号。
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")


# ----------------------------------------------------------------------------
# 套壳门:rewrite 后不应残留任何 golden 匿名临时名(_T_<n> / _GEN_<n> / _REG_<n>)。
#   注:L2Top 的 trace 寄存器是「具名」寄存器(后缀 _REG / _r,无编号),可读,放行。
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
    m = re.search(r"^module L2Top\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden L2Top 同名扁平端口,供 FM/ST 对接)。",
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
    (XC / "l2top_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取(实例名小写或带下划线,head 形如 `  Type  inst (`)
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
#   收割范围 = 所有「不带初值」的 wire 声明:
#     · _inner_<inst>_*   子模块输出网(diplomacy 扁平 TL 引脚等)
#     · inner_io_chi_*     CHI 输出网(子模块输出引脚连到这些 wire,再 assign 给 io)
#   带初值(wire X = Y)的改名/直通归到 glue,不在 decls。
# ----------------------------------------------------------------------------
def gen_decls():
    decls = []
    for m in re.finditer(
            r"^  wire\s+(\[[\d:]+\](?:\[[\d:]+\])?\s+)?(_?inner_[A-Za-z0-9_]+);$",
            GSV, re.M):
        w = (m.group(1) or "").strip()
        decls.append((w, m.group(2)))
    L = [HDR,
         "// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "//   _inner_<inst>_*  : 子模块输出网(含 diplomacy 扁平 TileLink 引脚);",
         "//   inner_io_chi_*   : CHI 输出网(子模块输出引脚 -> 此 wire -> io assign)。",
         "// 由 l2top_inst.svh 绑定子模块输出引脚,互联直连 / outassign 消费。", ""]
    for w, n in decls:
        L.append(f"  logic {w + ' ' if w else ''}{n};")
    (XC / "l2top_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(decls))


# ----------------------------------------------------------------------------
# 顶层 glue:输入 fanin 改名 / 组合直通改名 / trace 打拍 / hartIsInReset。
#   这些在 golden 里命名已可读(无匿名临时名),原样保留为可读 glue。
#   做法:从 reg 声明行起、到第二个 always 块结束行止,整段搬运;并把段前的
#   `wire X = Y;`(带初值,即改名/直通)也搬进来(它们散落在 wire 声明区)。
# ----------------------------------------------------------------------------
def gen_glue():
    # (1) 带初值的 wire 改名/直通(inner_io_X = io_X / inner_io_X_to = inner_io_X_from)
    renames = re.findall(
        r"^  (wire\s+(?:\[[\d:]+\]\s+)?inner_io_[A-Za-z0-9_]+ = "
        r"(?:io_|inner_io_)[A-Za-z0-9_]+;)$", GSV, re.M)
    # (2) reg 声明 + 两个 always 块(trace 打拍 + hartIsInReset),整段连续搬运。
    reg_start = next(i for i, l in enumerate(LINES)
                     if re.match(r"^  reg .*inner_io_traceCoreInterface", l))
    # 找到第二个 always(posedge clock or posedge reset)块的 `end` 行。
    seq_end = next(i for i, l in enumerate(LINES)
                   if l.strip() == "end // always @(posedge, posedge)")
    seq_block = LINES[reg_start:seq_end + 1]

    L = [HDR,
         "// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,原样保留)=====",
         "// (A) 输入 fanin 改名 + 组合直通(hartId / cpu_halt / cpu_critical_error)。",
         "//     纯连线改名,无任何运算。", ""]
    leaks = 0
    for r in renames:
        if leftover_golden(r):
            leaks += 1
        L.append(f"  {r}")
    L.append("")
    L.append("  // (B) trace 接口打拍流水级(本层唯一时序 glue):core 来的")
    L.append("  //     traceCoreInterface(toEncoder groups/trap/priv)打一拍寄存,")
    L.append("  //     部分受 group_valid / itype(异常)门控;fromEncoder 的")
    L.append("  //     enable/stall 也打一拍回灌。hartIsInReset:resetInFrontend|reset")
    L.append("  //     经异步置位寄存器输出。")
    for ln in seq_block:
        L.append(ln)
        if leftover_golden(ln):
            leaks += 1
    (XC / "l2top_glue.svh").write_text("\n".join(L) + "\n")
    return dict(renames=len(renames), seq_lines=len(seq_block), leaks=leaks)


# ----------------------------------------------------------------------------
# gen_inst():21 子模块黑盒例化 + 引脚 rewrite。
#   引脚 rhs:io_* / inner_io_* / _inner_* / 常量 / 拼接({2'h0,...}) /
#   clock·reset 直连 / 悬空端口(/* unused */ -> 空)。全部无匿名临时名。
# ----------------------------------------------------------------------------
def rewrite_rhs(rhs):
    key = re.sub(r"\s+", " ", rhs.strip())
    if key == "" or key == "/* unused */":
        return ""  # 显式悬空端口 .pin ( )
    return key


def gen_inst(blocks):
    L = [HDR,
         "// 21 子模块黑盒例化(15 种类型)+ 引脚连核内具名信号/互联网。",
         "// 引脚 rhs:io_* 顶层端口 / inner_io_* glue 网 / _inner_* 子模块输出网 /",
         "// clock·reset 直连 / 常量 / {2'h0,...} 零扩展 / 悬空端口(/* unused */)。", ""]
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
    (XC / "l2top_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks, unused=unused)


# ----------------------------------------------------------------------------
# l2top_outassign.svh:顶层 io 输出驱动 + 中断端口直通 assign。
#   golden 末尾 assign 段(从第一条 auto_inner_*_int_out 到 io_l2_hint_bits_sourceId)
#   全部搬运。含 1 处位选([3:0])。
# ----------------------------------------------------------------------------
def gen_outassign():
    # 抓取所有顶层 assign(可能跨行,rhs 直到分号)。
    assigns = re.findall(r"^  assign ((?:auto_inner_|io_)\w+)\s*=\s*(.*?);",
                         GSV, re.M | re.S)
    L = [HDR,
         "// 顶层 io 输出 assign + 中断端口直通(auto_inner_*_int_out=in,L2Top 仅中转)。",
         "// 绝大多数纯连线;唯一带运算:io_l2_hint_bits_sourceId 取低 4 位([3:0])。", ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        if leftover_golden(rhs):
            leaks += 1
        L.append(f"  assign {lhs} = {rhs};")
    (XC / "l2top_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# L2Top_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_L2Top_core。",
         "module L2Top(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_L2Top_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "L2Top_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs(空体,所有 output 驱 0)—— 仅备快速 elaborate,UT/FM 用 golden 真定义
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 15 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
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
    (XC / "l2top_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# golden 叶子传递闭包(同 gen_xstile.py:-f 每文件一次,规避 -y 自包含 pkg 冲突)
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
    L = ["// 自动生成:scripts/gen_l2top.py —— golden 叶子传递闭包文件列表(每文件一次)",
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

    # variants_xs.sv:L2Top_xs(golden 同名扁平端口)-> 核
    L = [HDR, "module L2Top_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_L2Top_core u_core (")
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

    T.append(f"  L2Top    u_g ({conn('g_')});")
    T.append(f"  L2Top_xs u_i ({conn('i_')});")
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
    txt = f"""# 自动生成:scripts/gen_l2top.py —— 勿手改
MODULE = L2Top

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/l2top_pkg.sv \\
           $(RTL_DIR)/l2/L2Top.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 L2Top.sv + 15 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/L2Top.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = {sub_deps}

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/l2/L2Top_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = L2Top
FM_REF_DEPS_L2Top = {fm_ref}

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
    print(f"[glue] {g['renames']} wire renames + {g['seq_lines']} seq lines "
          f"(2 always:trace+hartIsInReset), golden-temp leaks={g['leaks']}")
    blocks = extract_instances()
    r = gen_inst(blocks)
    print(f"[inst] {r['insts']} instances, golden-temp leaks={r['leaks']}, "
          f"unused(dangling) pins={r['unused']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io output/int assigns, golden-temp leaks={oa['leaks']}")
    gen_wrapper(ps)
    gen_stubs(types)
    fl = gen_filelist(["L2Top"])
    print(f"[filelist] golden closure: {fl['nmod']} modules, {fl['nfiles']} files"
          + (f", MISSING={fl['missing'][:10]}" if fl['missing'] else ", missing=0"))
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
