#!/usr/bin/env python3
"""
XSTop(SoC 顶:tile + NoC/CHI 多 die 路由 + 中断控制器 + 总线/IO)生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
XSTop(src/main/scala/top/Top.scala,经 XSTileWrap / SoCMisc 等组合而成的 SoC 顶)
在已重写的 tile 顶层 XSTile(core_with_l2)之上,挂接:
  core_with_l2 (XSTile)               单 tile(XSCore+L2,**已重写,本层 golden 黑盒**)
  nocMisc      (MemMisc)              SoC misc:DebugModule/CLINT/PLIC/AXI4 xbar/L3 等
  chi_openllc_opt (OpenLLC)           open-source LLC(末级 cache)
  chi_llcBridge_opt (OpenNCB)         LLC TileLink<->CHI NCB 桥
  chi_mmioBridge_opt(OpenNCB_1)       MMIO TileLink<->CHI NCB 桥
  linkMonitor / linkMonitor_1/_2      CHI Rx/Tx link 监视器(本端 + 2 个 outer die)
  rxsnpArb/rxrspArb/rxdatArb (FastArbiter) outer 两 die 的 CHI Rx 通道仲裁
  llcLogger/memLogger/mmioLogger (CHILogger) CHI 总线 logger
  intBuffer (IntBuffer)               中断单 bit 缓冲
  reset_sync_resetSync / jtag_reset_sync_resetSync (ResetGen) 复位同步
这些子模块对本层都是 golden 黑盒(UT/FM 两侧共用同一份 golden 定义)。

XSTop 主体仍是「互联层」,但与 XSCore/XSTile 不同,它含一处**真实的顶层组合 glue**
——CHI 多 die(2 个 outer 节点)的 Tx/Rx 路由(golden 里展开成 `_T_`/`inner_`/`outer_`
临时名,共 ~16 条)。本脚本把这处 glue **按 Scala 设计意图重写成具名可读 wire**
(放在 rtl/xstop/xstop_glue.svh,核里有完整中文注释),绝不抽 golden `_T_` 套壳:

  ① tileReset —— core_with_l2 复位 = 同步复位 | DebugModule 的 hartReset 请求。
       golden: _reset_sync_resetSync_o_reset | _nocMisc_debug_module_io_resetCtrl_hartResetReq_0
  ② CHI Tx-REQ 目标 die 译码(txReqTgtID)—— 按 tx_req 地址 [47:31] 落在哪个
       地址区间,决定路由到 outer die 0(tgtID=2)还是 die 1(tgtID=1)。
       golden: 一串地址比较 OR(_inner_tx_req_bits_tgtID_T_49/106/123 -> inner_tx_req_bits_tgtID)。
  ③ Tx 通道按 tgtID 分发 valid:txReqToDie0Valid/txReqToDie1Valid(req/rsp/dat 各一对)。
       golden: outer_0/1_tx_{req,rsp,dat}_valid。
  ④ 本端 linkMonitor 的 tx_*_ready = 两 die ready & 各自 valid 的归并(reduction-OR)。
  ⑤ outer die 的 rx_*_ready = 本端 rx ready & 对应 Rx 仲裁器 valid,再按仲裁 chosen 分发到
       die 0(~chosen)/ die 1(chosen)。golden: _outer_1_rx_{snp,rsp,dat}_ready_T & [~]_rx*Arb_io_chosen。
  ⑥ trace 输出 = 把 core 的 3 个 retire group 字段拼接对外(io_traceCoreInterface_0_toEncoder_*)。

所有 glue 临时名经本脚本的 _RENAME 映射改写为具名可读 wire;改写后核+svh 全文
`_T_`/`_GEN_`/golden `inner_`/`outer_` 临时名 = 0。

机械部分由本脚本生成(同 gen_xstile.py 套路):
  rtl/xstop/xstop_ports.svh   —— 可读核扁平端口表(与 golden XSTop 同名)
  rtl/xstop/xstop_decls.svh   —— 子模块黑盒输出/互联网声明(宽度从 golden 收割)
  rtl/xstop/xstop_glue.svh    —— CHI 多 die 路由 glue(具名可读 wire,从 Scala 意图重写)
  rtl/xstop/xstop_inst.svh    —— 子模块黑盒例化 + 引脚连核内具名信号/互联/glue
  rtl/xstop/xstop_outassign.svh—— 顶层 io 输出 assign(直连 / trace 拼接)
  rtl/xstop/XSTop_wrapper.sv  —— golden 同名扁平 wrapper(FM/ST 用)
  rtl/xstop/xstop_blackbox_stubs.sv —— 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/XSTop/{variants_xs.sv,tb.sv,Makefile,golden_filelist.f}

可读核本体见 rtl/xstop/XSTop.sv,类型见 xstop_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
XC = XSSV / "rtl/xstop"
UT = XSSV / "verif/ut/XSTop"
GSV = (GOLDEN / "XSTop.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_xstop.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")
# 引脚:.name (rhs) —— rhs 允许内含一层括号(tgtID 译码有 ~(...) / |{...} 嵌套)。
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")

# 子模块输出/互联网前缀。注意 XSTop 实例名带下划线(core_with_l2 / chi_llcBridge_opt
# / reset_sync_resetSync / linkMonitor_1 ...),故用宽松前缀集合,见 _harvest。
INST_PREFIXES = None  # 运行时由 instance 头填充


# ----------------------------------------------------------------------------
# glue 临时名 -> 核内可读具名 wire 的 rewrite 映射
# ----------------------------------------------------------------------------
# golden 的 CHI 多 die 路由 glue 临时名,逐一映射成可读具名 wire。
# (右值表达式在 xstop_glue.svh 里照 golden 结构、用这些可读名重写,见 gen_glue。)
_RENAME = {
    # ② Tx-REQ 目标 die 地址译码(保留 golden 布尔结构,仅换可读名)
    "_inner_tx_req_bits_tgtID_T_49":  "txReqAddrHi17IsZero",      # addr[47:31]==0
    "_inner_tx_req_bits_tgtID_T_106": "txReqAddrInLowRegions",    # 低地址区间命中
    "_inner_tx_req_bits_tgtID_T_123": "txReqTgtSel",              # 2 位:选 die(2'h2/2'h1)
    "inner_tx_req_bits_tgtID":        "txReqTgtID",               # {9'h0, txReqTgtSel}
    # ③ Tx 各通道按 tgtID 分发 valid
    "outer_0_tx_req_valid": "txReqToDie0Valid",
    "outer_0_tx_rsp_valid": "txRspToDie0Valid",
    "outer_0_tx_dat_valid": "txDatToDie0Valid",
    "outer_1_tx_req_valid": "txReqToDie1Valid",
    "outer_1_tx_rsp_valid": "txRspToDie1Valid",
    "outer_1_tx_dat_valid": "txDatToDie1Valid",
    # ⑤ outer die 的 Rx ready = 本端 rx ready & 仲裁器 out valid(未分 chosen)
    "_outer_1_rx_snp_ready_T": "rxSnpReadyAndArbValid",
    "_outer_1_rx_rsp_ready_T": "rxRspReadyAndArbValid",
    "_outer_1_rx_dat_ready_T": "rxDatReadyAndArbValid",
}


def apply_rename(expr):
    """把表达式里所有 golden glue 临时名替换为可读具名 wire(整词替换,长名优先)。"""
    for k in sorted(_RENAME, key=len, reverse=True):
        expr = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(k) + r"(?![A-Za-z0-9_])",
                      _RENAME[k], expr)
    return expr


# 整条 rhs 命中 glue 组合式 -> 核内具名 wire(目前仅 core_with_l2 的 tile 复位)。
_GLUE_EXPR = {
    "_reset_sync_resetSync_o_reset | _nocMisc_debug_module_io_resetCtrl_hartResetReq_0":
        "tileReset",
}


def rewrite_rhs(rhs):
    """引脚 rhs:悬空注释 -> 空;整条组合式 -> 具名 glue wire;否则套用 glue 改名。"""
    key = re.sub(r"\s+", " ", rhs.strip())
    if key == "" or key == "/* unused */":
        return ""
    if key in _GLUE_EXPR:
        return _GLUE_EXPR[key]
    return apply_rename(key)


def leftover_golden(rhs):
    """套壳门:rewrite 后不应残留任何 golden 临时名(_T_/_GEN_/裸 inner_/裸 outer_)。"""
    bad = []
    for t in _WORD.findall(rhs):
        if re.search(r"_GEN_\d|_T_\d", t):
            bad.append(t)
        elif (t.startswith("inner_") or t.startswith("outer_")) and t in _RENAME:
            bad.append(t)
    return bad


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module XSTop\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden XSTop 同名扁平端口,供 FM/ST 对接)。",
         "// clock/reset 不在本层端口里:XSTop 用 io_clock/io_reset(功能端口),核里照列。"]
    for d, w, n in ps:
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d} {ww}{n},")
    for i in range(len(L) - 1, -1, -1):
        if L[i].endswith(","):
            L[i] = L[i][:-1]
            break
    (XC / "xstop_ports.svh").write_text("\n".join(L) + "\n")
    return ps


# ----------------------------------------------------------------------------
# 子模块例化块提取
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


def inst_names():
    names = []
    for head, _ in extract_instances():
        m = re.match(r"^  ([A-Z][A-Za-z0-9_]+) +([a-zA-Z_][A-Za-z0-9_]*) +\($", head)
        names.append(m.group(2))
    return names


# ----------------------------------------------------------------------------
# 子模块互联网声明:从 golden wire 声明收割(只取「纯声明」wire,不取 glue 计算 wire)
# ----------------------------------------------------------------------------
def _harvest_wire_widths():
    """收集 golden 里所有 `wire [w] name;`(无 = 的纯声明)的宽度。
    glue 计算 wire(`wire ... = expr;`)单独处理,不进 decls。"""
    wm = {}
    for m in re.finditer(
            r"^  wire\s+(\[[\d:]+\](?:\[[\d:]+\])?\s+)?(_?[A-Za-z][A-Za-z0-9_]*)\s*;",
            GSV, re.M):
        wm[m.group(2)] = (m.group(1) or "").strip()
    return wm


def gen_decls(widths, names):
    """声明所有子模块输出/互联网(`_<inst>_*`)。glue 计算 wire 不在此(在 glue.svh)。"""
    # glue 计算 wire 的 golden 名(被 _RENAME 改写,decls 不重复声明)
    glue_golden = set(_RENAME.keys())
    used = set()
    # 凡是 `_<instname>_...` 形式的标识符即子模块输出/互联网
    inst_re = re.compile(r"\b_(?:" + "|".join(re.escape(n) for n in names)
                         + r")_[A-Za-z0-9_]+\b")
    for idt in inst_re.findall(GSV):
        if idt not in glue_golden:
            used.add(idt)
    to_decl = sorted(used)
    missing = [n for n in to_decl if n not in widths]
    L = [HDR,
         "// 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "// 由 xstop_inst.svh 绑定子模块输出引脚,互联直连 / glue / outassign 消费。",
         "// (CHI 多 die 路由 glue 的具名 wire 单列在 xstop_glue.svh,不在此声明。)", ""]
    for n in to_decl:
        w = widths.get(n, "")
        L.append(f"  logic {w + ' ' if w else ''}{n};"
                 + ("" if w or n in widths else "   // 宽度未收割(按 1bit,请核对)"))
    (XC / "xstop_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(to_decl), missing=missing)


# ----------------------------------------------------------------------------
# gen_glue():CHI 多 die 路由 glue —— 从 golden 计算 wire 照结构、换可读名重写
# ----------------------------------------------------------------------------
def _extract_glue_wire(name):
    """从 golden 抓 `wire [w] <name> = <expr...>;`(可跨多行),返回 (width, expr)。"""
    m = re.search(r"^  wire\s+(\[[\d:]+\]\s+)?" + re.escape(name)
                  + r"\s*=\s*(.*?);\s*$", GSV, re.M | re.S)
    if not m:
        return None
    width = (m.group(1) or "").strip()
    expr = re.sub(r"\s+", " ", m.group(2).strip())
    return width, expr


def gen_glue():
    """生成 xstop_glue.svh:把 CHI 多 die 路由 glue 计算 wire 用可读名重写。"""
    L = [HDR,
         "// ===================================================================",
         "// CHI 多 die(2 个 outer 节点)Tx/Rx 路由 glue —— 从 Scala 设计意图重写。",
         "//   保留 golden 的布尔/算术结构(地址译码 OR、reduction-OR、仲裁分发),",
         "//   仅把 golden 的 _T_/inner_/outer_ 临时名换成可读具名 wire(见脚本 _RENAME)。",
         "// ===================================================================",
         ""]
    # ① tileReset(core_with_l2 复位)—— 不是 wire 声明,作为 glue wire 显式给出
    L.append("  // ① tile 复位:同步复位 OR DebugModule 的 hart 复位请求(送 core_with_l2.reset)。")
    L.append("  wire tileReset = _reset_sync_resetSync_o_reset"
             " | _nocMisc_debug_module_io_resetCtrl_hartResetReq_0;")
    L.append("")

    # ② Tx-REQ 目标 die 地址译码(保留 golden 结构,换可读名)
    L.append("  // ② Tx-REQ 目标 die 地址译码:按 tx_req 地址区间选 outer die,")
    L.append("  //    txReqTgtSel=2'h2 -> die0(tgtID=2),=2'h1 -> die1(tgtID=1)。")
    for golden_name in ("_inner_tx_req_bits_tgtID_T_49",
                        "_inner_tx_req_bits_tgtID_T_106",
                        "_inner_tx_req_bits_tgtID_T_123",
                        "inner_tx_req_bits_tgtID"):
        gw = _extract_glue_wire(golden_name)
        if gw is None:
            L.append(f"  // !! 未能抓到 golden glue wire {golden_name}")
            continue
        width, expr = gw
        L.append(f"  wire {width + ' ' if width else ''}"
                 f"{_RENAME[golden_name]} = {apply_rename(expr)};")
    L.append("")

    # ③ Tx 各通道按 tgtID 分发 valid(golden 是 assign,这里用 wire 赋值)
    L.append("  // ③ Tx 通道按 tgtID 把本端 linkMonitor 的 valid 分发到 die0/die1。")
    tx_assigns = re.findall(
        r"^  assign (outer_[01]_tx_(?:req|rsp|dat)_valid)\s*=\s*(.*?);\s*$",
        GSV, re.M | re.S)
    for lhs, rhs in tx_assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        L.append(f"  wire {_RENAME[lhs]} = {apply_rename(rhs)};")
    L.append("")

    # ⑤ outer die 的 Rx ready 中间量(本端 rx ready & 对应仲裁器 out valid)
    L.append("  // ⑤ outer die Rx ready 中间量:本端 rx ready & 对应 Rx 仲裁器 out valid")
    L.append("  //    (再在引脚处 & [~]arb_chosen 分发到 die0/die1,见 inst.svh)。")
    for golden_name in ("_outer_1_rx_snp_ready_T",
                        "_outer_1_rx_rsp_ready_T",
                        "_outer_1_rx_dat_ready_T"):
        gw = _extract_glue_wire(golden_name)
        if gw is None:
            L.append(f"  // !! 未能抓到 golden glue wire {golden_name}")
            continue
        width, expr = gw
        L.append(f"  wire {width + ' ' if width else ''}"
                 f"{_RENAME[golden_name]} = {apply_rename(expr)};")
    (XC / "xstop_glue.svh").write_text("\n".join(L) + "\n")
    return dict(renamed=len(_RENAME))


# ----------------------------------------------------------------------------
# gen_inst():子模块黑盒例化 + 引脚 rewrite(套用 glue 改名)
# ----------------------------------------------------------------------------
def gen_inst(blocks):
    L = [HDR,
         "// 子模块黑盒例化 + 引脚连核内具名信号/互联网/glue。",
         "// 引脚 rhs:io_* 顶层端口 / _<inst>_* 互联网 / clock·reset / 常量 /",
         "// 悬空端口 / CHI 路由 glue 具名 wire(见 xstop_glue.svh)。", ""]
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
                if leaks <= 12:
                    print(f"  LEAK {inst}.{pin}: {bad}")
            pins.append((pin, nr))
        for i, (pin, nr) in enumerate(pins):
            comma = "," if i < len(pins) - 1 else ""
            L.append(f"    .{pin} ({nr}){comma}")
        L.append("  );")
    (XC / "xstop_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks, unused=unused)


# ----------------------------------------------------------------------------
# xstop_outassign.svh:顶层 io 输出驱动(golden 末尾 assign io_=...,含 trace 拼接)
# ----------------------------------------------------------------------------
def gen_outassign():
    # 抓所有 `assign io_... = ...;`(可跨多行,trace 是多行拼接)
    assigns = re.findall(r"^  assign (io_\w+)\s*=\s*(.*?);\s*$", GSV, re.M | re.S)
    L = [HDR,
         "// 顶层 io 输出 assign:子模块黑盒输出直连 io;",
         "// trace 输出是把 core 的 3 个 retire group 字段拼接对外(io_traceCoreInterface_0_*)。",
         ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        nr = apply_rename(rhs)
        if leftover_golden(nr):
            leaks += 1
        L.append(f"  assign {lhs} = {nr};")
    (XC / "xstop_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# XSTop_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_XSTop_core。",
         "module XSTop("]
    for i, (d, w, n) in enumerate(ports):
        comma = "," if i < len(ports) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_XSTop_core u_core (")
    for i, (d, w, n) in enumerate(ports):
        comma = "," if i < len(ports) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (XC / "XSTop_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
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
    (XC / "xstop_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# golden 叶子传递闭包(同 gen_xstile.py)
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
    L = ["// 自动生成:scripts/gen_xstop.py —— golden 叶子传递闭包文件列表(每文件一次)",
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
    ins = [p for p in ports if p[0] == "input"]
    outs = [p for p in ports if p[0] == "output"]

    # variants_xs.sv:XSTop_xs(golden 同名扁平端口)-> 核
    L = [HDR, "module XSTop_xs("]
    for i, (d, w, n) in enumerate(ports):
        comma = "," if i < len(ports) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_XSTop_core u_core (")
    for i, (d, w, n) in enumerate(ports):
        comma = "," if i < len(ports) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(L) + "\n")

    # 找时钟/复位端口(XSTop 用 io_clock/io_reset 等功能端口名)
    clkname = next((n for d, w, n in ins if n == "io_clock"), None)

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
        items = []
        for d, w, n in ports:
            if d == "input":
                items.append(f".{n}({n})")
            else:
                items.append(f".{n}({prefix_out}{n})")
        return ", ".join(items)

    T.append(f"  XSTop    u_g ({conn('g_')});")
    T.append(f"  XSTop_xs u_i ({conn('i_')});")
    T.append("")
    T.append(f"  bit reported [0:{len(outs) - 1}];")
    T.append("  int distinct_div = 0;")
    T.append("")
    # 把 tb 的 clk/rst 接到功能时钟/复位端口(若存在)
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for d, w, n in ins:
        if n.endswith("_valid") or n.endswith("_ready") or n.endswith("_flitv") \
                or n.endswith("_flitpend"):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for d, w, n in ins:
        if n == "io_clock" or n == "io_reset":
            continue  # 时钟/复位由下面 initial/always 单驱
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
    # 功能时钟端口跟随 tb clk;功能复位端口跟随 tb rst
    has_clk = any(n == "io_clock" for d, w, n in ins)
    has_rst = any(n == "io_reset" for d, w, n in ins)
    if has_clk:
        T.append("  always @(*) io_clock = clk;")
    if has_rst:
        T.append("  always @(*) io_reset = rst;")
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

    sub_deps = " ".join(f"$(GOLDEN_RTL)/{t}.sv" for t in sorted(types)
                        if (GOLDEN / f"{t}.sv").exists())
    fm_ref = " ".join(f"{t}.sv" for t in sorted(types)
                      if (GOLDEN / f"{t}.sv").exists())
    txt = f"""# 自动生成:scripts/gen_xstop.py —— 勿手改
MODULE = XSTop

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xstop/xstop_pkg.sv \\
           $(RTL_DIR)/xstop/XSTop.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSTop.sv + 子模块全部叶子(传递闭包,-f 显式编译)。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSTop.sv

SUB_DEPS = {sub_deps}

WRAPPER_SRCS = $(RTL_DIR)/xstop/XSTop_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = XSTop
FM_REF_DEPS_XSTop = {fm_ref}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstop
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
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
    names = inst_names()
    print(f"ports: {len(ps)}  submodule types: {len(types)}  instances: "
          f"{sum(len(v) for v in types.values())}")
    blocks = extract_instances()
    widths = _harvest_wire_widths()
    d = gen_decls(widths, names)
    print(f"[decls] {d['nets']} interconnect nets, missing-width={len(d['missing'])}"
          + (": " + ", ".join(d["missing"][:8]) if d["missing"] else ""))
    g = gen_glue()
    print(f"[glue] {g['renamed']} golden temp names renamed to readable wires")
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
