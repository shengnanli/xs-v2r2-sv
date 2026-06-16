#!/usr/bin/env python3
"""
MemBlock 生成器 —— 访存子系统总集成（capstone，1346 端口 / 71 实例）。

设计意图来源：src/main/scala/xiangshan/mem/MemBlock.scala
  （class MemBlockInlined / MemBlockInlinedImp，外层 MemBlock/MemBlockImp）

MemBlock 是香山 V2R2 访存子系统的**顶层互联 glue**：它把 LoadUnit×3 / StoreUnit×2 /
stdExeUnit(MemExeUnit)×2 / AtomicsUnit / 各向量访存单元(VLSplit/VSSplit/VxMergeBuffer/
VSegmentUnit/VfofBuffer) / Lsq(LsqWrapper) / Sbuffer / DCacheWrapper / Uncache /
三个 DTLB(TLBNonBlock×3) / PMP + PMPChecker×8 / L2TLBWrapper(共享 PTW) /
PTWNewFilter + PTWRepeaterNB / 各预取器(SMSPrefetcher/L1Prefetcher) /
TileLink 缓冲与交叉开关(TLBuffer×N/TLXbar) / Pipeline / 各 DelayN/PipelineConnect /
MBIST / PFEvent 等几十个功能单元组装起来。本层只做**端口路由 / 仲裁 / 互联 +
少量顶层时序逻辑(CSR/触发器分发、异常聚合、prefetch enable 打拍、perf 汇聚)**，
所有功能算法都在子模块内部。

因为这是 1346 端口 / 71 实例 / ~4960 wire / 326 assign / 6 always 的巨型扁平互联，
机械的“信号声明 + 连线 + 实例端口表”按工程既定先例(LoadQueue/LsqWrapper)拆进
memblock_*.svh，由可读核 `include；不搬运任何逻辑改写，仅做 firtool 样板剥离。
可读核 xs_MemBlock_core 提供**架构框架 + 中文讲解**(各单元如何互联 / CSR 分发 /
异常聚合 / perf)，是学习载体。

本脚本：
  1. 解析 golden/chisel-rtl/MemBlock.sv 的端口表 → memblock_ports.svh（可读核端口列表，
     与 golden 同名扁平端口，供 FM/ST 对接）。
  2. 解析 module 体（端口表之后到 endmodule），**剥离 firtool 样板**：
       - `ifndef SYNTHESIS … `endif（XSError/assert，非综合）
       - `ifdef ENABLE_INITIAL_REG_ … `endif（寄存器上电随机化 initial 块）
     其余 wire/reg 声明、assign、always、子模块实例**按 golden 原样保留**为互联载体，
     拆进 memblock_glue.svh（被可读核 include）。
  3. 生成 golden 同名 wrapper（→ 可读核 + pkg）、_xs 镜像、随机比对 tb、黑盒 stub 列表。

可读核本体（手写架构框架 + 注释）见 rtl/memblock/MemBlock.sv，类型包见 memblock_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
RTL = XSSV / "rtl/memblock"
GSV = (GOLDEN / "MemBlock.sv").read_text()
LINES = GSV.splitlines()

HDR = "// 自动生成：scripts/gen_memblock.py —— 勿手改\n"


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module MemBlock\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


# ----------------------------------------------------------------------------
# module 体提取 + firtool 样板剥离
# ----------------------------------------------------------------------------
def body_lines():
    # 端口表结束：module MemBlock( 之后第一行 ");"
    mod_start = next(i for i, l in enumerate(LINES) if l.startswith("module MemBlock("))
    ports_end = next(i for i in range(mod_start, len(LINES)) if LINES[i].rstrip() == ");")
    end_mod = next(i for i in range(ports_end, len(LINES)) if LINES[i].rstrip() == "endmodule")
    raw = LINES[ports_end + 1:end_mod]

    out, i = [], 0
    while i < len(raw):
        l = raw[i]
        s = l.strip()
        # 剥离 `ifndef SYNTHESIS … `endif（XSError/assert，非综合，不参与功能）
        if s.startswith("`ifndef SYNTHESIS"):
            depth = 1
            i += 1
            while i < len(raw) and depth > 0:
                t = raw[i].strip()
                if t.startswith("`ifdef") or t.startswith("`ifndef"):
                    depth += 1
                elif t.startswith("`endif"):
                    depth -= 1
                i += 1
            continue
        # 剥离 `ifdef ENABLE_INITIAL_REG_ … `endif（寄存器上电随机化 initial 块）
        if s.startswith("`ifdef ENABLE_INITIAL_REG_") or \
           s.startswith("`ifdef ENABLE_INITIAL_MEM_"):
            depth = 1
            i += 1
            while i < len(raw) and depth > 0:
                t = raw[i].strip()
                if t.startswith("`ifdef") or t.startswith("`ifndef"):
                    depth += 1
                elif t.startswith("`endif"):
                    depth -= 1
                i += 1
            continue
        out.append(l)
        i += 1
    return out


# ----------------------------------------------------------------------------
# 体拆分：把 wire/reg 声明、assign/always、子模块实例分到不同 .svh，便于阅读
#   - memblock_nets.svh  ：所有 wire/reg 内部互联网声明
#   - memblock_logic.svh ：所有 assign + always（顶层组合/时序 glue）
#   - memblock_inst.svh  ：71 个子模块实例端口表
# 不改写任何连接，仅按语法块归类。声明与逻辑/实例按 golden 出现顺序各自拼接。
# ----------------------------------------------------------------------------
DECL_RE = re.compile(r"^\s*(wire|reg)\b")
INST_HEAD_RE = re.compile(r"^  [A-Z][A-Za-z_0-9]+ +[a-z_][A-Za-z_0-9]* +\($")
ASSIGN_RE = re.compile(r"^\s*assign\b")
ALWAYS_RE = re.compile(r"^\s*always\b")


def classify(body):
    nets, logic, inst = [], [], []
    i, n = 0, len(body)
    while i < n:
        l = body[i]
        # 子模块实例：从 "Mod inst (" 到匹配的 "  );"
        if INST_HEAD_RE.match(l):
            blk = [l]
            i += 1
            while i < n and body[i].rstrip() != "  );":
                blk.append(body[i])
                i += 1
            if i < n:
                blk.append(body[i])  # "  );"
                i += 1
            inst.append("\n".join(blk))
            continue
        # always 块：到匹配 end 的 "  end"（firtool 的 always 顶层 end 缩进为 2 空格）
        if ALWAYS_RE.match(l):
            blk = [l]
            i += 1
            while i < n:
                blk.append(body[i])
                # always 顶层结束：以 "  end" 开头（含可能的尾注释 // always @...)
                if re.match(r"^  end\b", body[i]) and not body[i].startswith("  end_"):
                    i += 1
                    break
                i += 1
            logic.append("\n".join(blk))
            continue
        # assign（可能跨多行，到以 ";" 结尾的那一行）
        if ASSIGN_RE.match(l):
            blk = [l]
            while not body[i].rstrip().endswith(";"):
                i += 1
                blk.append(body[i])
            i += 1
            logic.append("\n".join(blk))
            continue
        # wire/reg 声明：每条声明都以 ";" 结束（可能 wire x = {concat}; 跨多行，
        # 续行可能以 "," 结尾——那是拼接里的逗号，不是声明结束，故只认 ";"）。
        if DECL_RE.match(l):
            blk = [l]
            while not body[i].rstrip().endswith(";"):
                i += 1
                if i >= n:
                    break
                blk.append(body[i])
            i += 1
            nets.append("\n".join(blk))
            continue
        # 其余（空行/注释）丢给 nets 末尾无害
        i += 1
    return nets, logic, inst


# ----------------------------------------------------------------------------
# 把 perf 输出 2 级流水从机械 glue 中“抬出”，交给可读核用 genvar+struct 实现。
#   golden 里 8 路 perf 各打两拍：inner_io_perf_<i>_value_REG -> _REG_1 -> io_perf_<i>。
#   这是规整的可读逻辑（与 DCache/LsqWrapper perf 同一做法），故：
#     - 从 always 块剔除 inner_io_perf_*_value_REG* 的两拍赋值行；
#     - 从 assign 列表剔除 io_perf_<i>_value = ..._REG_1；
#     - 从 nets 剔除 inner_io_perf_*_value_REG* 的 reg 声明；
#     - 生成 memblock_perf_src.svh：perf_src[i] = _inner_perfEvents_hpm_io_perf_<i>_value。
#   可读核据 PERF_OUT_NUM 用 genvar 打两拍后接 io_perf_*。
# ----------------------------------------------------------------------------
PERF_REG_LINE = re.compile(r"^\s*inner_io_perf_\d+_value_REG")
PERF_OUT_ASSIGN = re.compile(r"^\s*assign io_perf_(\d+)_value = ")
PERF_REG_DECL = re.compile(r"\binner_io_perf_\d+_value_REG")
PERF_SRC = re.compile(r"_inner_perfEvents_hpm_io_perf_(\d+)_value")


def lift_perf(nets, logic):
    # 从 always 块剔除 perf 两拍赋值行
    new_logic = []
    for blk in logic:
        if PERF_OUT_ASSIGN.match(blk.strip()):
            continue  # perf 输出 assign，剔除（核里重接）
        lines = blk.split("\n")
        kept = [ln for ln in lines if not PERF_REG_LINE.match(ln)]
        new_logic.append("\n".join(kept))
    # 从 nets 剔除 perf REG 声明
    new_nets = [d for d in nets if not PERF_REG_DECL.search(d)]
    # 生成 perf 源映射
    src = ["// 自动生成：scripts/gen_memblock.py —— 勿手改",
           "// perf 源：HPerfMonitor 吐出的 8 路计数 → perf_src[i]，由可读核打两拍后接出。"]
    for i in range(8):
        src.append(f"  assign perf_src[{i}] = _inner_perfEvents_hpm_io_perf_{i}_value;")
    (RTL / "memblock_perf_src.svh").write_text("\n".join(src) + "\n")
    out = ["// 自动生成：scripts/gen_memblock.py —— 勿手改",
           "// perf 输出：可读核打两拍后的 perf_stage2[i] → 顶层扁平端口 io_perf_<i>_value。"]
    for i in range(8):
        out.append(f"  assign io_perf_{i}_value = perf_stage2[{i}];")
    (RTL / "memblock_perf_out.svh").write_text("\n".join(out) + "\n")
    return new_nets, new_logic


def write_svh(name, blocks, head_comment):
    txt = HDR + head_comment + "\n\n" + "\n".join(blocks) + "\n"
    (RTL / name).write_text(txt)
    return txt.count("\n")


# ----------------------------------------------------------------------------
# 端口表 svh（可读核端口列表）
# ----------------------------------------------------------------------------
def gen_ports_svh(ps):
    decls = []
    for d, w, nm in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{nm}")
    (RTL / "memblock_ports.svh").write_text(
        HDR + "// 可读核 xs_MemBlock_core 的端口列表（与 golden MemBlock 同名扁平端口）。\n"
        + ",\n".join(decls) + "\n")


# ----------------------------------------------------------------------------
# golden 同名 wrapper（FM/ST 用）+ _xs 镜像（UT 用）
# ----------------------------------------------------------------------------
def emit_flat_wrapper(modname, ps):
    decls = []
    for d, w, nm in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{nm}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{nm}({nm})" for _, _, nm in ps]
    L.append("  xs_MemBlock_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


# ----------------------------------------------------------------------------
# 黑盒 stub：所有子模块声明为 empty black box（端口从 golden 提取，仅方向/位宽）
# ----------------------------------------------------------------------------
def submodule_names():
    names = set()
    for l in LINES:
        m = re.match(r"^  ([A-Z][A-Za-z_0-9]+) +[a-z_][A-Za-z_0-9]* +\($", l)
        if m:
            names.add(m.group(1))
    return sorted(names)


def golden_module_ports(modname):
    """从对应 golden 文件提取某模块端口（用于黑盒 stub）。找不到独立文件则跳过。"""
    f = GOLDEN / f"{modname}.sv"
    if not f.exists():
        return None
    txt = f.read_text()
    m = re.search(rf"^module {re.escape(modname)}\((.*?)\n\);", txt, re.S | re.M)
    if not m:
        return None
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def gen_stub_sv():
    """生成黑盒 stub 文件（UT/FM 不用——两侧共用 golden 子模块定义；
    此 stub 仅供独立 elaborate 可读核时占位/查阅端口）。"""
    blocks = []
    for nm in submodule_names():
        ps = golden_module_ports(nm)
        if ps is None:
            blocks.append(f"// {nm}: golden 无独立文件，沿用 MemBlock 内部例化定义")
            continue
        decls = []
        for d, w, n in ps:
            ws = f"[{w-1}:0] " if w > 1 else ""
            decls.append(f"  {d:6s} {ws}{n}")
        blocks.append(f"module {nm}(\n" + ",\n".join(decls) + "\n);\nendmodule")
    (RTL / "memblock_stub.sv").write_text(
        HDR + "// MemBlock 全部子模块的黑盒 stub（端口自 golden 提取）。\n"
        "// UT/FM 实际两侧共用 golden 子模块定义，此文件仅供可读核单独 elaborate 占位。\n\n"
        + "\n\n".join(blocks) + "\n")


# ----------------------------------------------------------------------------
# tb（UT 双例化逐拍比对全部输出）
# ----------------------------------------------------------------------------
def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_memblock.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  MemBlock    u_g ({', '.join(gg)});")
    T.append(f"  MemBlock_xs u_i ({', '.join(ig)});")

    def rnd(w, n):
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    if (!$value$plusargs("NCYCLES=%d", NCYCLES)) NCYCLES = 200000;
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


# ----------------------------------------------------------------------------
# golden 实例化闭包（从 MemBlock 出发的模块例化传递闭包）
#   MemBlock 是访存子系统顶层，其闭包≈整个访存子系统的 golden 文件。
#   UT 双例化两侧 / FM 两侧都需要这批 golden 子模块定义。
# ----------------------------------------------------------------------------
def module_to_file():
    """模块名 → golden 文件名映射。含 .sv（Chisel/SRAM）与 .v（厂商内存宏 *_ext）。
    模块声明形式可为 'module Name(' 或 'module Name ('（ClockGate 等带空格）。"""
    m2f = {}
    for f in sorted(GOLDEN.glob("*.sv")) + sorted(GOLDEN.glob("*.v")):
        txt = f.read_text(errors="ignore")
        for mm in re.finditer(r"^module\s+(\w+)\s*[\(#]", txt, re.M):
            m2f.setdefault(mm.group(1), f.name)
    return m2f


# 非实例的关键字（避免把 always/if/case 等误当模块名）
_NOT_INST = {"always", "assign", "if", "else", "case", "for", "begin", "end",
             "wire", "reg", "module", "endmodule", "initial", "generate",
             "endgenerate", "function", "endfunction", "task", "endtask",
             "input", "output", "inout", "localparam", "parameter"}


def instances_in_file(fname):
    """通用 Verilog 例化扫描："  ModuleName instName ("。
    覆盖 Chisel 大写模块、SRAM 宏(sram_array_*)、ClockGate、array_*/array_*_ext 等
    各级物理 cell；过滤掉控制关键字。"""
    p = GOLDEN / fname
    if not p.exists():
        return set()
    txt = p.read_text(errors="ignore")
    res = set()
    for mm in re.finditer(r"^  ([A-Za-z_][A-Za-z_0-9]*) +[A-Za-z_][A-Za-z_0-9]* +\($",
                          txt, re.M):
        nm = mm.group(1)
        if nm not in _NOT_INST:
            res.add(nm)
    return res


def golden_closure():
    m2f = module_to_file()
    seen, closure, stack = set(), set(), ["MemBlock"]
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        fn = m2f.get(mod)
        if not fn:
            continue
        closure.add(fn)
        for c in instances_in_file(fn):
            if c not in seen:
                stack.append(c)
    closure.discard("MemBlock.sv")
    return sorted(closure)


def gen_makefile(closure):
    def fmt(prefix, files, per=2):
        L = []
        for i in range(0, len(files), per):
            chunk = " ".join(f"$(GOLDEN_RTL)/{f}" for f in files[i:i + per])
            L.append(("  " if i else prefix) + chunk + (" \\" if i + per < len(files) else ""))
        return "\n".join(L)

    closure_str = fmt("", closure)
    mk = f"""MODULE = MemBlock

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（核通过 `include 引入端口表 / 内部网 / 顶层逻辑 / perf / 实例表）。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_pkg.sv \\
           $(RTL_DIR)/memblock/MemBlock.sv

TB_SRCS = variants_xs.sv tb.sv

# golden MemBlock 例化访存子系统全部组件，其传递闭包共 {len(closure)} 个 golden 文件
# （整个访存子系统：DCache 全栈 + L2TLB/PTW + 全部队列 + 厂商 SRAM 宏 *_ext.v + ClockGate）。
# UT 双例化两侧（golden 顶层 + 手写可读核）都读入这批 golden 子模块定义。
GOLDEN_SRCS = $(GOLDEN_RTL)/MemBlock.sv \\
{closure_str}

# FM 走黑盒先例（见 fm_eq_bb.tcl）：ref/impl 两侧都只读顶层 + memblock_stub（全部
# 子模块显式端口黑盒），避免厂商 RAM(ram_40x47 异步读)在 link 触发 FMR_ELAB-147，
# 并把比对聚焦在本层互联 glue。共享 fm-% 规则会整树 link golden 子模块而失败，故不用。
FM_VARIANTS =

# 子模块条目结构相同的重复寄存器很多，关掉“合并同值重复寄存器”pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口表 / 内部网 / 顶层逻辑 / perf / 实例表）。
VCS += +incdir+$(RTL_DIR)/memblock

# ----------------------------------------------------------------------------
# 黑盒 FM 目标：ref = golden MemBlock + 全子模块黑盒桩；impl = wrapper(→核+pkg) + 同一桩。
# 两侧子模块实化为同一份空黑盒，FM 对顶层互联 glue 做签名等价（不改任何共享脚本）。
# ----------------------------------------------------------------------------
STUB = $(abspath $(RTL_DIR)/memblock/memblock_stub.sv)
.PHONY: fmbb
fmbb:
	@mkdir -p fm_work/MemBlock
	@echo "=== FM(bb): MemBlock ==="
	FM_TOP=MemBlock \\
	FM_REF_SRCS="$(abspath $(GOLDEN_RTL)/MemBlock.sv) $(STUB)" \\
	FM_IMPL_SRCS="$(abspath $(RTL_SRCS)) $(abspath $(RTL_DIR)/memblock/MemBlock_wrapper.sv) $(STUB)" \\
	FM_MERGE_DUP=false \\
	fm_shell -64 -work_path fm_work/MemBlock -file $(abspath fm_eq_bb.tcl) \\
	    > fm_work/MemBlock/fm.log 2>&1; \\
	grep -E "^FM_RESULT" fm_work/MemBlock/fm.log; \\
	grep -q "^FM_RESULT: Verification SUCCEEDED" fm_work/MemBlock/fm.log
"""
    ut = XSSV / "verif/ut/MemBlock"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "Makefile").write_text(mk)


def main():
    ps = top_ports()
    body = body_lines()
    nets, logic, inst = classify(body)
    nets, logic = lift_perf(nets, logic)

    gen_ports_svh(ps)
    nln = write_svh(
        "memblock_nets.svh", nets,
        "// 内部互联网声明（_inner_* / inner_*）：子模块输出网、流水寄存器、CSR/触发器\n"
        "// 副本等。这是 1346 端口 / 71 实例巨型互联的载体，按 golden 原样保留（剥离\n"
        "// firtool 随机化样板），不做逻辑改写。")
    lln = write_svh(
        "memblock_logic.svh", logic,
        "// 顶层组合/时序 glue：assign（端口路由 / 仲裁 / 异常聚合 / 互联）+ always\n"
        "// （CSR/触发器分发寄存、prefetch enable 打拍、redirect/perf 寄存等）。\n"
        "// 按 golden 原样保留，不搬运逻辑；阅读时配合 docs/memblock/MemBlock.md 的分节讲解。")
    iln = write_svh(
        "memblock_inst.svh", inst,
        "// 71 个子模块实例端口表（全部作 golden 黑盒；UT/FM 两侧共用 golden 定义）。\n"
        "// 各功能单元的算法在子模块内部，本层只负责把它们的端口接到互联网/顶层端口。")

    (RTL / "MemBlock_wrapper.sv").write_text(HDR + emit_flat_wrapper("MemBlock", ps))
    gen_stub_sv()

    ut = XSSV / "verif/ut/MemBlock"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(HDR + emit_flat_wrapper("MemBlock_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))

    closure = golden_closure()
    gen_makefile(closure)

    nin = sum(1 for d, _, _ in ps if d == "input")
    nout = sum(1 for d, _, _ in ps if d == "output")
    print(f"MemBlock: {len(ps)} ports ({nin} in / {nout} out)")
    print(f"  nets.svh  : {len(nets)} decls (~{nln} lines)")
    print(f"  logic.svh : {len(logic)} assign/always (~{lln} lines)")
    print(f"  inst.svh  : {len(inst)} instances (~{iln} lines)")
    print(f"  submodules: {len(submodule_names())} distinct")
    print(f"  golden closure: {len(closure)} files")


if __name__ == "__main__":
    main()
