#!/usr/bin/env python3
"""
Backend(后端最高层总集成)生成器。

== 重写原则(从 Scala 设计意图,杜绝 golden 套壳)==
Backend(src/main/scala/xiangshan/backend/Backend.scala)是后端最高层:把
CtrlBlock / Scheduler×4(int/fp/vf/mem) / DataPath / BypassNetwork / ExuBlock×3 /
WbDataPath / WbFuBusyTable / VecExcpDataMergeModule / HPerfMonitor / PFEvent /
Og2ForVector / NewPipelineConnectPipe×N / DelayN×2 共 45 个实例组装互联。这些
子模块**已单独重写完成**,对本层是 golden 黑盒(UT/FM 两侧共用)。

本层真正属于「顶层 glue」的可读逻辑(都在 xs_Backend_core 用 struct/always 写,
不抽进 svh 套壳),见 rtl/backend/backend_logic.svh:
  1. iqWakeUpMappedBundleDelayed —— 唤醒总线打拍(RegNext)。
  2. int/fp/vf/v0/vlWriteBackDelayed —— 写回打拍(RegNext + RegEnable)。
  3. CSR<->Mem 边界打拍(instrAddrTransType/msiInfo/clintTime/l2FlushDone/extInt)。
  4. issueTimeout —— mem 发射超时 4-bit 饱和计数。
  5. vsetvlVType —— int/vf vtype 二选一锁存。
  6. debugVl/topDownInfo/pfevent 杂项打拍。
  7. flush 判定公用拼接别名(flushRobIdxFull / robDeqPtrFull)。

机械部分由本脚本生成:
  rtl/backend/backend_ports.svh —— 可读核扁平端口表(与 golden 同名)
  rtl/backend/backend_decls.svh —— 45 子模块黑盒输出/互联网声明(宽度从 golden 收割)
  rtl/backend/backend_inst.svh  —— 45 子模块黑盒例化 + 引脚连核内具名信号
  rtl/backend/Backend_wrapper.sv—— golden 同名扁平 wrapper(FM/ST 用)
  rtl/backend/backend_blackbox_stubs.sv —— 31 子模块类型黑盒 stub(空体,输出 0)
  verif/ut/Backend/{variants_xs.sv,tb.sv,Makefile}

可读核本体见 rtl/backend/Backend.sv,类型见 backend_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/Backend"
GSV = (GOLDEN / "Backend.sv").read_text()
LINES = GSV.splitlines()
HDR = "// 自动生成:scripts/gen_backend.py —— 勿手改(逻辑部分为从 Scala 意图的可读重写)\n"

_WORD = re.compile(r"[A-Za-z_]\w*")
_PINRE = re.compile(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)")


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module Backend\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_ports(ps):
    L = [HDR, "// 可读核端口表(与 golden Backend 同名扁平端口,供 FM/ST 对接)。",
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
    (BK / "backend_ports.svh").write_text("\n".join(L) + "\n")
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
# glue 临时名 -> 核内可读具名信号 的 rewrite 映射
# ----------------------------------------------------------------------------
# 唤醒总线打拍:golden 名 inner_iqWakeUpMappedBundleDelayed_delayed_REG[_<i>]_bits_<f>
#   -> 核内 wakeupDelayed[i].<f>(i 缺省=0)。
def _rw_wakeup(tok):
    m = re.fullmatch(r"inner_iqWakeUpMappedBundleDelayed_delayed_REG_(\d+)_bits_(\w+)", tok)
    if m:
        return f"wakeupDelayed[{m.group(1)}].{m.group(2)}"
    m = re.fullmatch(r"inner_iqWakeUpMappedBundleDelayed_delayed_REG_bits_(\w+)", tok)
    if m:
        return f"wakeupDelayed[0].{m.group(1)}"
    return None


# 写回打拍:golden 名 inner_<dom>WriteBackDelayed_<i>_<f>_REG / _addr_r
#   -> 核内 <dom>WbDelayed[i].<member>。
_WB_DOMS = {"int": "intWbDelayed", "fp": "fpWbDelayed", "vf": "vfWbDelayed",
            "v0": "v0WbDelayed", "vl": "vlWbDelayed"}
# 各域 typeWen 的 golden 名 -> struct 成员 typeWen
_WB_TYPEWEN = {"int": "intWen", "fp": "fpWen", "vf": "vecWen",
               "v0": "v0Wen", "vl": "vlWen"}


def _rw_writeback(tok):
    for dom, arr in _WB_DOMS.items():
        m = re.fullmatch(rf"inner_{dom}WriteBackDelayed_(\d+)_wen_REG", tok)
        if m:
            return f"{arr}[{m.group(1)}].wen"
        m = re.fullmatch(rf"inner_{dom}WriteBackDelayed_(\d+)_addr_r", tok)
        if m:
            return f"{arr}[{m.group(1)}].addr"
        tw = _WB_TYPEWEN[dom]
        m = re.fullmatch(rf"inner_{dom}WriteBackDelayed_(\d+)_{tw}_REG", tok)
        if m:
            return f"{arr}[{m.group(1)}].typeWen"
    return None


# 逐 token 的简单别名映射(寄存器化的 CSR/Mem 边界打拍 + vsetvl + 杂项)。
_SINGLETON = {
    # 顶层 hartId 拼接别名 {2'h0, hartId}
    "inner_": "hartIdFull",
    "inner_cg_cgen": "dftCgen",
    # CSR -> Mem 边界打拍(送 ctrlBlock.fromCSR.instrAddrTransType)
    "inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_bare": "instrTransTypeR.bare",
    "inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_sv39": "instrTransTypeR.sv39",
    "inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_sv39x4": "instrTransTypeR.sv39x4",
    "inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_sv48": "instrTransTypeR.sv48",
    "inner_ctrlBlock_io_fromCSR_instrAddrTransType_REG_sv48x4": "instrTransTypeR.sv48x4",
    # dataPath topDownInfo.l1Miss RegNext
    "inner_dataPath_io_topDownInfo_l1Miss_REG": "topDownL1MissR",
    "inner_io_topDownInfo_noUopsIssued_REG": "noUopsIssuedR",
    # intExuBlock.csrin 边界打拍(来自 io_fromTop_*)
    "inner_intExuBlock_io_csrin_msiInfo_valid_REG": "msiInfoValidR",
    "inner_intExuBlock_io_csrin_msiInfo_bits_r": "msiInfoBitsR",
    "inner_intExuBlock_io_csrin_clintTime_valid_REG": "clintTimeValidR",
    "inner_intExuBlock_io_csrin_clintTime_bits_r": "clintTimeBitsR",
    "inner_intExuBlock_io_csrin_l2FlushDone_REG": "l2FlushDoneR",
    # 外部中断打拍
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_mtip": "extIntR.mtip",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_msip": "extIntR.msip",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_meip": "extIntR.meip",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_seip": "extIntR.seip",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_debug": "extIntR.debug",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_nmi_nmi_31": "extIntR.nmi31",
    "inner_intExuBlock_io_csrio_externalInterrupt_REG_nmi_nmi_43": "extIntR.nmi43",
    # debugVl 打拍
    "inner_debugVl_s1_REG": "debugVlS1R",
    # pfevent CSR 分发打拍
    "inner_pfevent_io_distribute_csr_REG_w_valid": "pfeventCsrR.valid",
    "inner_pfevent_io_distribute_csr_REG_w_bits_addr": "pfeventCsrR.addr",
    "inner_pfevent_io_distribute_csr_REG_w_bits_data": "pfeventCsrR.data",
    # vsetvl vtype 锁存
    "inner_vsetvlVType_illegal": "vsetvlVType.illegal",
    "inner_vsetvlVType_vma": "vsetvlVType.vma",
    "inner_vsetvlVType_vta": "vsetvlVType.vta",
    "inner_vsetvlVType_vsew": "vsetvlVType.vsew",
    "inner_vsetvlVType_vlmul": "vsetvlVType.vlmul",
    # mem 发射超时计数标志(组合)
    "inner_issueTimeout": "issueTimeout[0]",
    "inner_issueTimeout_1": "issueTimeout[1]",
    "inner_issueTimeout_2": "issueTimeout[2]",
    "inner_issueTimeout_3": "issueTimeout[3]",
    "inner_issueTimeout_4": "issueTimeout[4]",
    # flush/robHead 判定公用拼接别名
    "inner__flushItself_T_2": "flushRobIdxFull",
    "inner__ctrlBlock_io_robio_robHeadLsIssue_T_2": "robDeqPtrFull",
    # mem 发射 valid&~ready 组合中间(inner__0..inner__9 偶为 ready&out_valid)
    "inner__0": "memIssueFire[0]", "inner__1": "memIssueOutFire[0]",
    "inner__2": "memIssueFire[1]", "inner__3": "memIssueOutFire[1]",
    "inner__4": "memIssueFire[2]", "inner__5": "memIssueOutFire[2]",
    "inner__6": "memIssueFire[3]", "inner__7": "memIssueOutFire[3]",
    "inner__8": "memIssueFire[4]", "inner__9": "memIssueOutFire[4]",
}


def rewrite_token(tok):
    """单个标识符 -> 核内具名信号(找不到返回 None,表示非 body-glue,原样保留)。"""
    r = _rw_wakeup(tok)
    if r:
        return r
    r = _rw_writeback(tok)
    if r:
        return r
    return _SINGLETON.get(tok)


def rewrite_rhs(rhs):
    return _WORD.sub(lambda m: rewrite_token(m.group(0)) or m.group(0), rhs)


def leftover_golden(rhs):
    """校验 rewrite 后是否仍有 golden 临时名残留(套壳门)。"""
    bad = []
    for t in _WORD.findall(rhs):
        if re.search(r"_GEN_\d|_T_\d", t):
            bad.append(t)
        elif t.startswith("inner_") and not t.startswith("_inner_"):
            # 所有 inner_ 前缀(非互联网 _inner_)都应已 rewrite 走;残留=漏映射
            bad.append(t)
    return bad


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
    """收集所有引脚 RHS 引用的互联网(_inner_ 前缀),声明之。"""
    used = set()
    for head, lines in blocks:
        for m in _PINRE.finditer("\n".join(lines)):
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            for idt in re.findall(r"\b_inner_[A-Za-z0-9_]+\b", rhs):
                used.add(idt)
    # 还有引脚 RHS 是「输出端口直连子模块输出」——这些 _inner_ 网必须声明;
    # 加上 always 块里被读的 _inner_(如打拍源)。
    for idt in re.findall(r"\b_inner_[A-Za-z0-9_]+\b", GSV):
        used.add(idt)
    to_decl = sorted(used)
    missing = [n for n in to_decl if n not in widths]
    L = [HDR,
         "// 45 子模块(golden 黑盒)输出/互联网声明,宽度从 golden wire 声明收割。",
         "// 这些网由 backend_inst.svh 例化时绑定到各子模块输出引脚,glue/直连消费。", ""]
    for n in to_decl:
        w = widths.get(n, "")
        L.append(f"  logic {w + ' ' if w else ''}{n};"
                 + ("" if w or n in widths else "   // 宽度未收割(按 1bit,请核对)"))
    (BK / "backend_decls.svh").write_text("\n".join(L) + "\n")
    return dict(nets=len(to_decl), missing=missing)


# ----------------------------------------------------------------------------
# gen_inst():45 子模块黑盒例化 + 引脚 rewrite
# ----------------------------------------------------------------------------
def gen_inst(blocks):
    L = [HDR,
         "// 45 子模块黑盒例化 + 引脚连核内具名信号(rewrite 见 gen_backend.py)。",
         "// 引脚 RHS 经 rewrite:body-glue(inner_*)-> 核内 struct 族/别名;",
         "// io_* 顶层端口 / _inner_* 互联网 / 常量 / clk 直连。", ""]
    leaks = 0
    for head, lines in blocks:
        typ, inst = head.strip().split()[0], head.strip().split()[1]
        L.append(f"  {typ} {inst} (")
        pins = []
        for m in _PINRE.finditer("\n".join(lines)):
            pin = m.group(1)
            rhs = re.sub(r"\s+", " ", m.group(2).strip())
            nr = rewrite_rhs(rhs)
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
    (BK / "backend_inst.svh").write_text("\n".join(L) + "\n")
    return dict(insts=len(blocks), leaks=leaks)


# ----------------------------------------------------------------------------
# backend_outassign.svh:顶层 io 输出驱动(208 条 assign io_=...)
#   golden 末尾用 assign 把子模块输出 _inner_* 直连顶层 io 输出端口,个别引用
#   glue 寄存器(noUopsIssuedR)。这里逐条搬运并 rewrite glue 名;纯连线,无逻辑。
# ----------------------------------------------------------------------------
def gen_outassign():
    assigns = re.findall(r"^  assign (io_\w+)\s*=\s*((?:[^;])*);", GSV, re.M)
    L = [HDR,
         "// 顶层 io 输出驱动:子模块黑盒输出 _inner_* 直连顶层 io(个别经 glue 寄存器)。",
         "// 纯连线,无逻辑;glue 名已 rewrite 到核内具名信号。", ""]
    leaks = 0
    for lhs, rhs in assigns:
        rhs = re.sub(r"\s+", " ", rhs.strip())
        nr = rewrite_rhs(rhs)
        if leftover_golden(nr):
            leaks += 1
        L.append(f"  assign {lhs} = {nr};")
    (BK / "backend_outassign.svh").write_text("\n".join(L) + "\n")
    return dict(n=len(assigns), leaks=leaks)


# ----------------------------------------------------------------------------
# Backend_wrapper.sv:golden 同名扁平 wrapper(例化可读核)
# ----------------------------------------------------------------------------
def gen_wrapper(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    L = [HDR, "// golden 同名扁平 wrapper(FM/ST 用):例化可读核 xs_Backend_core。",
         "module Backend(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        ww = "" if w == 1 else f"[{w - 1}:0] "
        L.append(f"  {d}  {ww}{n}{comma}")
    L.append(");")
    L.append("  xs_Backend_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (BK / "Backend_wrapper.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# blackbox stubs:从各 golden 子模块文件提取 module 头,生成空体 stub
# (UT/FM 用更优是直接用 golden 子模块定义;stub 仅备用/快速 elaborate)
# ----------------------------------------------------------------------------
def gen_stubs(types):
    L = [HDR, "// 31 子模块类型黑盒 stub(空体,所有 output 驱 0)。",
         "// 注:UT/FM 默认用 golden 子模块真定义(-y GOLDEN_RTL);本 stub 仅备快速 elaborate。", ""]
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
    (BK / "backend_blackbox_stubs.sv").write_text("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# UT:tb.sv / variants_xs.sv / Makefile(仿 CtrlBlock UT)
# ----------------------------------------------------------------------------
def wdecl(w):
    return "" if w == 1 else f"[{w - 1}:0] "


def gen_ut(ports, types):
    UT.mkdir(parents=True, exist_ok=True)
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    ins = [p for p in pl if p[0] == "input"]
    outs = [p for p in pl if p[0] == "output"]

    # variants_xs.sv:Backend_xs(golden 同名扁平端口)-> 核
    L = [HDR, "module Backend_xs(", "  input  clock,", "  input  reset,"]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_Backend_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(L) + "\n")

    # tb.sv
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

    T.append(f"  Backend    u_g ({conn('g_')});")
    T.append(f"  Backend_xs u_i ({conn('i_')});")
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
    # 比对
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

    # Makefile
    subt = sorted(types)
    subs = " \\\n           ".join(f"$(GOLDEN_RTL)/{t}.sv" for t in subt)
    ref_deps = " ".join(f"{t}.sv" for t in subt)
    txt = f"""# 自动生成:scripts/gen_backend.py —— 勿手改
MODULE = Backend

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/glue/inst svh)。
RTL_SRCS = $(RTL_DIR)/backend/backend_pkg.sv \\
           $(RTL_DIR)/backend/Backend.sv

TB_SRCS = variants_xs.sv tb.sv

# 31 子模块类型作 golden 黑盒;UT 双例化两侧共用同一份 golden 定义。
# 更深的 golden 叶子由 -y GOLDEN_RTL 按文件名自动解析。
SUB_DEPS = {subs}

GOLDEN_SRCS = $(GOLDEN_RTL)/Backend.sv $(SUB_DEPS)

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = $(RTL_DIR)/backend/Backend_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = Backend
FM_REF_DEPS_Backend = {ref_deps}

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
"""
    (UT / "Makefile").write_text(txt)
    return len(ins), len(outs)


def main():
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
    print(f"[inst] {r['insts']} instances, golden-temp leaks={r['leaks']}")
    oa = gen_outassign()
    print(f"[outassign] {oa['n']} io output assigns, golden-temp leaks={oa['leaks']}")
    gen_wrapper(ps)
    gen_stubs(types)
    ni, no = gen_ut(ps, types)
    print(f"[ut] {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
