#!/usr/bin/env python3
"""
Slice(L2 cache slice 主体装配层)生成器。

== 重写原则(从 Scala/CoupledL2 设计意图,杜绝 golden 套壳)==
Slice(CoupledL2 仓库 src/main/scala/coupledL2/Slice.scala)是 L2 cache **一个 bank**
的完整流水装配:北侧接 L1/core 集群的 TileLink 五通道(io_in_a/b/c/d/e),南侧接
CHI 桥(io_out_tx_*/io_out_rx_*),内部把请求仲裁、主流水、目录、数据阵列、MSHR 控制、
各通道 sink/source/tx/rx 队列拼成一条真正的 cache 流水线,并对外吐出 dirResult /
prefetch train/resp / l1Hint / perf / error。

子模块(18 种类型 / 18 个实例,**本层全部 golden 黑盒**,UT/FM 两侧共用):
  RequestArb   reqArb     请求仲裁(A/B/C/replay -> s1/s2/s3 流水入口,目录读发起)
  MainPipe_1   mainPipe   主流水(s1~s3:目录命中判定/读改写/发 release/refill/grant)
  Directory    directory  目录(tag/meta SRAM + 替换算法,本 bank 的 snoop filter)
  DataStorage  dataStorage数据阵列(ECC data SRAM 读写)
  MSHRCtl      mshrCtl    MSHR 控制(miss/probe 状态机阵列 + 任务下发,含 16 个 MSHR)
  RequestBuffer reqBuf    A 通道请求缓冲(阻塞冲突 set/way 的请求)
  SinkA        sinkA      A 通道接收(acquire/get/prefetch 入口)
  SinkC        sinkC      C 通道接收(release/probeAck + 写 refill/release buffer)
  GrantBuffer  grantBuf   D 通道发射缓冲(grant/grantData/releaseAck,含 sink id 管理)
  TXREQ/TXDAT/TXRSP        CHI 发送三通道(req/dat/rsp flit 组装下发)
  RXSNP/RXDAT/RXRSP        CHI 接收三通道(snoop/dat/rsp flit 拆解上送)
  MSHRBuffer/MSHRBuffer_1  refillBuf/releaseBuf(refill/release 数据缓冲)
  L2Slice      mbistPl    MBIST 自测流水分发(SRAM 内建自测,接 boreChildrenBd_bore_*)

== 本层(顶层 glue)==
golden Slice.sv 全文 10019 行,firtool 实测**无 `_T_<n>`/`_GEN_<n>` 匿名临时名**;
逻辑 = 子模块例化 + 互联布线 + 极少量打拍/探针,共四块:
  (1) MBIST bore 改名:wire bd_X = boreChildrenBd_bore_X;(9 条,纯连线,喂 mbistPl);
  (2) error/perf 打拍流水(本层唯二时序 glue,两个 always):
        · 异步复位块:mainPipe releaseBufResp_s3_valid 打一拍 + io_error_valid 打一拍;
        · 同步块:    io_error_bits 打一拍 + 11 路 perf 事件各 2 级 RegNext(s1->s2)。
      golden 把第二级 RegNext 命名为 `io_perf_<N>_value_REG_1`(`_REG_<数字>` 触套壳
      闸门),本脚本**重写为具名两级流水** perf_<N>_value_s1 / perf_<N>_value_s2;
  (3) dontTouch 探针:assign _probe_<k> = <子模块输出>;(4 条,死端,综合丢弃);
  (4) 顶层 io 输出 assign:dirResult/error/perf 直连打拍寄存 / 子模块输出网 + bore 回吐。

机械部分由本脚本生成(同 gen_l2top.py 套路):
  rtl/l2/slice_ports.svh      —— 可读核扁平端口表(与 golden Slice 同名,465 端口)
  rtl/l2/slice_decls.svh      —— 子模块黑盒输出/互联网声明(宽度从 golden wire 收割)
  rtl/l2/slice_glue.svh       —— 顶层 glue:MBIST 改名 + error/perf 打拍(perf 具名重写)
  rtl/l2/slice_inst.svh       —— 18 子模块黑盒例化 + 引脚连核内具名信号/互联网
  rtl/l2/slice_outassign.svh  —— 顶层 io 输出 + 探针 + bore 回吐 assign
  rtl/l2/Slice_wrapper.sv     —— golden 同名扁平 wrapper(FM/ST 用)
  rtl/l2/slice_blackbox_stubs.sv —— 18 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/Slice/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}

可读核本体见 rtl/l2/Slice.sv,类型/参数见 slice_pkg.sv。

注:Slice_1/Slice_2/Slice_3 与 Slice 仅差 sliceId(0/1/2/3)+ 子模块变体名
(Directory/Directory_1、DataStorage/DataStorage_1、L2Slice/L2Slice_1);Slice_4 是
OpenLLC home-node slice(完全不同模块)。本脚本聚焦基准 Slice(sliceId=0)。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/l2"
UT = XSSV / "verif/ut/Slice"
GSV = (GOLDEN / "Slice.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_slice.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)\n"

# ----------------------------------------------------------------------------
# FM 子模块边界(codex_0036 裁定):
#   BLACKBOX_GREEN = Slice 直接例化的 13 个已证 305 SIGNOFF_PASS 子(assembly
#     depends_on):两侧都不给 golden 源 → hdlin_unresolved_modules=black_box 同名
#     配对为对称黑盒(只证本层 glue,子模块各自已 signoff)。allow/Slice.json 声明。
#   ELAB_SUBS = 3 个非 305 逻辑子(DataStorage/RequestBuffer/RXSNP)+ 另 2 个同类非
#     305 逻辑叶(MSHRBuffer/MSHRBuffer_1)。**禁黑盒**:golden RTL 及其递归子链两侧
#     全 elaborate 受验,仅最底层厂商 SRAM 宏 array_18_ext 黑盒(与 ICacheDataArray 同法)。
# ----------------------------------------------------------------------------
BLACKBOX_GREEN = [
    "Directory", "GrantBuffer", "L2Slice", "MSHRCtl", "MainPipe_1",
    "RXDAT", "RXRSP", "RequestArb", "SinkA", "SinkC",
    "TXDAT", "TXREQ", "TXRSP",
]
ELAB_SUBS = ["DataStorage", "RequestBuffer", "RXSNP", "MSHRBuffer", "MSHRBuffer_1"]
# 厂商存储宏(vendor SRAM leaf):两侧都不给 → 对称黑盒边界(唯一 elaborate 例外)。
VENDOR_BB = ["array_18_ext"]

_WORD = re.compile(r"[A-Za-z_]\w*")
# 引脚:.name (rhs) —— rhs 允许内含一层括号。
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")


# ----------------------------------------------------------------------------
# perf 二级流水具名重写:golden `io_perf_<N>_value_REG_1`(_REG_<数字>,触套壳闸门)
#   -> perf_<N>_value_s2;`io_perf_<N>_value_REG` -> perf_<N>_value_s1。
# (这两级 reg 只喂 io_perf 输出 assign,不被任何子模块引脚引用,改名安全。)
# ----------------------------------------------------------------------------
def rename_perf(text):
    text = re.sub(r"io_perf_(\d+)_value_REG_1", r"perf_\1_value_s2", text)
    text = re.sub(r"io_perf_(\d+)_value_REG\b", r"perf_\1_value_s1", text)
    return text


# ----------------------------------------------------------------------------
# 套壳闸门:rewrite 后代码区(去注释)不应残留任何匿名临时名 / 双数字索引端口名。
# ----------------------------------------------------------------------------
_BADRE = re.compile(r"io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE")


def gate_scan(text):
    out = []
    for ln in text.splitlines():
        code = re.sub(r"//.*$", "", ln)
        for m in _BADRE.finditer(code):
            out.append((ln.strip()[:90], m.group(0)))
    return out


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module Slice\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden Slice 同名扁平端口,供 FM/ST 对接)。",
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
    (XC / "slice_ports.svh").write_text("\n".join(L) + "\n")
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
# 子模块互联网声明:收割所有「不带初值」的 wire 声明。
#   · _<inst>_io_*        子模块输出网(占绝大多数);
#   · bd_outdata/bd_ack   mbistPl 对上 MBIST 返回;
#   · childBd[_1]_*       mbistPl 对下级 SRAM MBIST 流水的控制/返回网;
#   · _probe / _probe_<k> dontTouch 探针网(_probe = reqBuf.io_hasMergeA,死端)。
#  带初值(wire X = Y;)的 bore 改名归 glue,不在 decls。
# ----------------------------------------------------------------------------
def gen_decls():
    decls = []
    for m in re.finditer(
            r"^  wire\s+(\[[\d:]+\]\s+)?([A-Za-z_][A-Za-z0-9_]*);$", GSV, re.M):
        w = (m.group(1) or "").strip()
        decls.append((w, m.group(2)))
    L = [HDR,
         "// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "//   _<inst>_io_*  : 子模块输出网;bd_*/childBd_* : MBIST 自测流水互联网;",
         "//   _probe[_k]    : dontTouch 探针网(死端,综合丢弃)。", ""]
    for w, n in decls:
        L.append(f"  logic {w + ' ' if w else ''}{n};")
    (XC / "slice_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(decls))


# ----------------------------------------------------------------------------
# 顶层 glue:MBIST bore 改名 + error/perf 打拍(perf 具名重写)。
# ----------------------------------------------------------------------------
def gen_glue():
    # (1) MBIST bore 改名:wire [..] bd_X = boreChildrenBd_bore_X;
    renames = re.findall(
        r"^  (wire\s+(?:\[[\d:]+\]\s+)?\w+ = boreChildrenBd_bore_\w+;)$", GSV, re.M)
    # (2) reg 声明(全部) + 两个 always 块(异步复位 / 同步打拍),perf 具名重写。
    reg_decls = [l for l in LINES if re.match(r"^  reg ", l)]
    a1s = next(i for i, l in enumerate(LINES)
               if l.strip() == "always @(posedge clock or posedge reset) begin")
    a1e = next(i for i in range(a1s, len(LINES))
               if LINES[i].strip() == "end // always @(posedge, posedge)")
    a2s = next(i for i in range(a1e, len(LINES))
               if LINES[i].strip() == "always @(posedge clock) begin")
    a2e = next(i for i in range(a2s, len(LINES))
               if LINES[i].strip() == "end // always @(posedge)")
    reg_block = rename_perf("\n".join(reg_decls)).splitlines()
    a1 = LINES[a1s:a1e + 1]                          # 异步复位块无 perf,原样
    a2 = rename_perf("\n".join(LINES[a2s:a2e + 1])).splitlines()

    L = [HDR,
         "// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,perf 二级流水重命名)=====",
         "// (1) MBIST bore 改名:把对外 boreChildrenBd_bore_* 端口改名喂 mbistPl(纯连线)。",
         ""]
    for r in renames:
        L.append(f"  {r}")
    L.append("")
    L.append("  // (2) error/perf 打拍流水(本层唯二时序 glue):")
    L.append("  //     · 异步复位块:releaseBufResp_s3_valid / io_error_valid 各打一拍;")
    L.append("  //     · 同步块:    io_error_bits 打一拍 + 11 路 perf 事件 2 级 RegNext。")
    L.append("  //   golden 第二级 RegNext 名为 io_perf_<N>_value_REG_1(_REG_<数字>,触")
    L.append("  //   套壳闸门),此处重写为具名两级 perf_<N>_value_s1 -> perf_<N>_value_s2。")
    L.extend(reg_block)
    L.extend(a1)
    L.extend(a2)
    (XC / "slice_glue.svh").write_text("\n".join(L) + "\n")
    return dict(renames=len(renames), regs=len(reg_decls),
                a1=len(a1), a2=len(a2))


# ----------------------------------------------------------------------------
# 18 子模块黑盒例化 + 引脚 rewrite(纯机械,引脚 rhs 无匿名临时名)。
# ----------------------------------------------------------------------------
def rewrite_rhs(rhs):
    key = re.sub(r"\s+", " ", rhs.strip())
    if key == "" or key == "/* unused */":
        return ""  # 显式悬空端口 .pin ( )
    return key


def gen_inst(blocks):
    L = [HDR,
         "// 18 子模块黑盒例化 + 引脚连核内具名信号/互联网。",
         "// 引脚 rhs:io_* 顶层端口 / _<inst>_io_* 子模块输出网 / bd_*·childBd_* MBIST 网 /",
         "// clock·reset 直连 / 常量 / 打拍寄存(*_REG) / 悬空端口(/* unused */)。", ""]
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
            pins.append((pin, nr))
        for i, (pin, nr) in enumerate(pins):
            comma = "," if i < len(pins) - 1 else ""
            L.append(f"    .{pin} ({nr}){comma}")
        L.append("  );")
    (XC / "slice_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), unused=unused)


# ----------------------------------------------------------------------------
# slice_outassign.svh:顶层 io 输出 + dontTouch 探针 + bore 回吐 assign。
#   LHS = io_* / _probe* / boreChildrenBd_*。perf 二级流水重命名。
# ----------------------------------------------------------------------------
def gen_outassign():
    assigns = re.findall(
        r"^  assign ((?:io_|_probe|boreChildrenBd_)\w*)\s*=\s*(.*?);", GSV,
        re.M | re.S)
    L = [HDR,
         "// 顶层 io 输出 assign + dontTouch 探针(_probe_<k>,死端)+ MBIST bore 回吐。",
         "// 多为子模块输出网 / 打拍寄存直连;io_dirResult_valid 含一处与运算门控。", ""]
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        L.append(f"  assign {lhs} = {rename_perf(rhs)};")
    (XC / "slice_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns))


# ----------------------------------------------------------------------------
# Slice_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_Slice_core。",
         "module Slice(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_Slice_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "Slice_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs(空体,所有 output 驱 0)—— 仅备快速 elaborate,UT/FM 用 golden 真定义
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 18 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
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
        ports = []
        for line in m.group(1).splitlines():
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
    (XC / "slice_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


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


def elab_closure():
    """FM 两侧 elaborate 的 golden 文件名列表 = ELAB_SUBS 的传递闭包,
    去掉厂商 _ext 宏(VENDOR_BB, 两侧黑盒)。递归到黑盒 green child 即停(它们作
    assembly 黑盒,不进 elaborate 闭包)。返回 (elab_names, bb_ext_names)。"""
    modfile = _golden_modfile_map()
    stop = set(BLACKBOX_GREEN)              # 遇 green child 停止递归(黑盒)
    seen, elab, bb, stack = set(), set(), set(), list(ELAB_SUBS)
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        if mod in stop:                     # green 305 child: 黑盒, 不 elaborate
            continue
        f = modfile.get(mod)
        if not f:
            continue
        if f.name.endswith("_ext.v") or mod in VENDOR_BB:
            bb.add(f.name)                  # 厂商宏: 黑盒边界(不 elaborate)
            continue
        elab.add(f.name)
        for m in _INSTREF.finditer(f.read_text(errors="ignore")):
            t = m.group(1)
            if t not in _KW and t not in seen and t in modfile:
                stack.append(t)
    return sorted(elab), sorted(bb)


def gen_filelist(tops):
    rel = "../../../golden/chisel-rtl"
    files, missing, nmod = golden_closure(tops)
    L = ["// 自动生成:scripts/gen_slice.py —— golden 叶子传递闭包文件列表(每文件一次)",
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

    # variants_xs.sv:Slice_xs(golden 同名扁平端口)-> 可读核
    L = [HDR, "module Slice_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_Slice_core u_core (")
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

    T.append(f"  Slice    u_g ({conn('g_')});")
    T.append(f"  Slice_xs u_i ({conn('i_')});")
    T.append("")
    T.append(f"  bit reported [0:{len(outs) - 1}];")
    T.append("  int distinct_div = 0;")
    T.append("")
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
    # FM 边界(codex_0036):
    #   ELAB = 3 非 305 逻辑子(DataStorage/RequestBuffer/RXSNP)+ 同类 MSHRBuffer[_1]
    #          的 golden 递归子链(两侧 elaborate 受验,厂商 array_18_ext 除外)。
    #   BLACKBOX_GREEN = 13 已证 305 SIGNOFF_PASS 子:两侧都不给源 →
    #          hdlin_unresolved_modules=black_box 对称黑盒(assembly depends_on)。
    elab_files, bb_ext = elab_closure()
    fm_ref = " ".join(elab_files)           # 两侧 elaborate 的 golden 文件(相对名)
    elab_srcs = " ".join(f"$(GOLDEN_RTL)/{f}" for f in elab_files)
    txt = f"""# 自动生成:scripts/gen_slice.py —— 勿手改
MODULE = Slice

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/slice_pkg.sv \\
           $(RTL_DIR)/l2/Slice.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 Slice.sv + 18 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/Slice.sv

# ----------------------------------------------------------------------------
# FM 子模块边界(codex_0036 修正裁定):
#   ELAB_SRCS = 3 非 305 逻辑子(DataStorage/RequestBuffer/RXSNP)+ 同类
#     MSHRBuffer/MSHRBuffer_1 的 golden 递归闭包({len(elab_files)} 文件)。两侧
#     (ref + impl WRAPPER_SRCS)同源 elaborate,SRAM 模板/MBIST/仲裁/队列逻辑全受验;
#     唯一黑盒边界 = 厂商 SRAM 宏 {" ".join(bb_ext) if bb_ext else "(无)"}(两侧都不给源)。
#   13 已证 305 SIGNOFF_PASS 子(SinkA/SinkC/GrantBuffer/TX*/RXDAT/RXRSP/Directory/
#     RequestArb/MainPipe_1/MSHRCtl/L2Slice)**不列**在此 → 两侧 unresolved →
#     hdlin_unresolved_modules=black_box 同名对称黑盒(assembly depends_on;
#     allow/Slice.json 声明; assembly_depends.tsv 记依赖闭包)。
# ----------------------------------------------------------------------------
ELAB_SRCS = {elab_srcs}

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次 elaborate 上述非 305 逻辑子链。
WRAPPER_SRCS = $(RTL_DIR)/l2/Slice_wrapper.sv $(ELAB_SRCS)
FM_VARIANTS = Slice
FM_REF_DEPS_Slice = {fm_ref}

# merge_duplicated_registers=false(非放宽——比较点增多 45290→45366): elaborate 的
# chosenQ(Queue1_ChosenQBundle)无 reset ram 中 task_channel[2] 恒 0 位, merge=true 下
# ref/impl 常数折叠深度不对称(ref 折掉 ram_reg[4]、impl 留 DFF0X)→ reqArb 黑盒输入
# io_sinkA_bits_channel[2] 假失配。关 merge 令各寄存器按名对称保留→逐位比对→消失配。
FM_MERGE_DUP = false

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
    print(f"[glue] {g['renames']} bore renames + {g['regs']} reg decls + "
          f"{g['a1']}+{g['a2']} always lines (error/perf 打拍)")
    blocks = extract_instances()
    r = gen_inst(blocks)
    print(f"[inst] {r['insts']} instances, unused(dangling) pins={r['unused']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io/probe/bore assigns")
    gen_wrapper(ps)
    gen_stubs(types)
    fl = gen_filelist(["Slice"])
    print(f"[filelist] golden closure: {fl['nmod']} modules, {fl['nfiles']} files"
          + (f", MISSING={fl['missing'][:10]}" if fl['missing'] else ", missing=0"))
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")

    # 套壳闸门自检:核 + 各 svh 去注释后不得残留匿名临时名 / 双数字索引端口名。
    blob = ""
    for fn in ("slice_decls.svh", "slice_glue.svh", "slice_inst.svh",
               "slice_outassign.svh", "slice_ports.svh"):
        blob += (XC / fn).read_text() + "\n"
    hits = gate_scan(blob)
    if hits:
        print(f"[GATE] !! {len(hits)} 套壳闸门命中:")
        for s, m in hits[:12]:
            print(f"   <{m}>  {s}")
    else:
        print("[GATE] OK —— 去注释代码区 _T_/_GEN_/_REG_<n>/双数字端口名/RANDOMIZE = 0")


if __name__ == "__main__":
    main()
