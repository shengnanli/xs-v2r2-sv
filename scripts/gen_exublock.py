#!/usr/bin/env python3
"""
ExuBlock / ExuBlock_1(执行单元簇容器)可读 SV 生成器。

== 设计意图(来自人写 Chisel:backend/exu/ExuBlock.scala class ExuBlock)==
ExuBlock 是若干执行单元(ExeUnit,各自封装 Alu/Mul/Div/Brh/Jump/CSR/Fence/FAlu... 这
些功能单元)的**容器**。LazyModule 时按 SchdBlockParams 把每个 issueblock 的每个 exu
都 LazyModule 出来,Imp 里做的事(ExuBlock.scala 38~68 行)只有一种「逐 exu 同构连线」:

    (ins zip exus zip outs).foreach { (input, exu, output) =>
      exu.io.flush  <> io.flush                       // flush 广播给每个 exu
      exu.io.csrio  / csrin / fenceio  <> io.*        // 仅含 CSR/Fence 的那个 exu 有
      exu.io.frm    := RegNext(io.frm)                // 每个吃 frm 的 vf-exu 各打一拍
      exu.io.vxrm/vtype/vlIsZero/vlIsVlmax <> io.*    // 仅向量配置 exu 有
      exu.io.in  <> input                             // 上游 issue → exu 输入
      output     <> exu.io.out                        // exu 输出 → 下游写回
      io.csrToDecode <> exu.io.csrToDecode            // 仅 CSR-exu 有
    }
    // 含 csrio 的 exu 把 instrAddrTransType 反向广播给其余 exu(本单态化下其余 exu 无此口)
    criticalErrors = csr-exu.getCriticalErrors → generateCriticalErrors()  // io_error 两级打拍

所以 ExuBlock **自身没有数据通路逻辑**(分发/仲裁/旁路都在它例化的 ExeUnit 子模块里、
或更上游的 Dispatch/DataPath 里)。容器层真正的「逻辑」只有三块,本脚本把它们从设计
意图重新实现为可读 SV(struct/enum/function/genvar),不照抄 golden 展平名:
  §1 frm 流水:每个 needSrcFrm 的 vf-exu 把 io_frm 打一拍后喂给该 exu(RegNext)。
  §2 critical-error 聚合:含 CSR 的 exu 的 error 两级打拍后输出 io_error_0。
  §3 输出反压/CSR 透传:exu 的 in_ready / csrio.instrAddrTransType 直接接到顶层(连线)。
其余 600 个端口都是 input<>exu.in / exu.out<>output 的**机械同构连线**,落在 *_connect.svh。

== 反套壳 ==
连线 svh 只放 ExeUnit 黑盒例化 + 扁平端口直连,grep "_GEN_|_T_[0-9]" 必为 0。
ExeUnit 各变体在 UT/FM 两侧均为 golden 黑盒(它们才是 FU 实体)。

产物(<MOD> ∈ {ExuBlock, ExuBlock_1}):
  rtl/backend/exublock[_1]_pkg.sv      —— 容器配置 + error 流水 struct/enum
  rtl/backend/exublock[_1]_ports.svh   —— 可读核扁平端口表
  rtl/backend/exublock[_1]_logic.svh   —— §1/§2/§3 可读重写逻辑(无 golden 临时名)
  rtl/backend/exublock[_1]_connect.svh —— ExeUnit 黑盒例化 + 端口机械连线
  rtl/backend/<MOD>.sv                 —— 可读核 xs_<MOD>_core
  rtl/backend/<MOD>_wrapper.sv         —— golden 同名扁平 wrapper(例化核)
  verif/ut/<MOD>/{variants_xs.sv,tb.sv,Makefile}
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"


def gen_hdr(mod):
    return f"// 自动生成:scripts/gen_exublock.py（{mod}）—— 勿手改(逻辑为从设计意图的可读重写)\n"


# ============================================================================
# golden 解析
# ============================================================================
def parse_ports(gsv, mod):
    """返回顶层端口 [(dir, width, name), ...](保留 golden 顺序,去掉 clock/reset)。"""
    m = re.search(rf"^module {mod}\((.*?)\n\);", gsv, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            if pm.group(3) in ("clock", "reset"):
                continue  # clock/reset 由核/wrapper 单独显式声明,不进端口表
            ww = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), ww, pm.group(3)))
    return res


def parse_instances(gsv):
    """
    解析每个 ExeUnit 例化:返回 [(type, inst, [(pin, rhs), ...]), ...]。
    rhs 形如 io_xxx / clock / reset / 内部 wire(_exus_N_io_in_ready 等)。
    """
    insts = []
    for m in re.finditer(r"^  ([A-Z][A-Za-z0-9_]+) +(\w+) +\((.*?)\n  \);",
                         gsv, re.S | re.M):
        typ, inst, body = m.group(1), m.group(2), m.group(3)
        pins = []
        for pm in re.finditer(r"\.(\w+)\s*\(\s*([A-Za-z0-9_]+)\s*\)", body):
            pins.append((pm.group(1), pm.group(2)))
        insts.append((typ, inst, pins))
    return insts


def parse_frm_regs(gsv):
    """frm 打拍寄存器:返回 {reg_name: 顺序号},以及每个寄存器喂给哪个 inst.pin。"""
    regs = re.findall(r"reg\s+\[2:0\]\s+(exus_io_frm_REG(?:_\d+)?);", gsv)
    return regs


def parse_assigns(gsv):
    """顶层 assign:返回 [(lhs, rhs), ...](in_ready / instrAddrTransType / error 透传)。"""
    res = []
    for m in re.finditer(r"^\s*assign\s+(\w+)\s*=\s*(\w+);", gsv, re.M):
        res.append((m.group(1), m.group(2)))
    return res


def parse_error_pipe(gsv):
    """识别 critical-error 两级打拍:io_error_0 <= REG_1 <= REG <= _exusN_io_error_0。"""
    src = re.search(r"(\w+_io_error_0)", gsv)
    regs = re.findall(r"reg\s+(io_error_0_REG(?:_\d+)?);", gsv)
    return (src.group(1) if src else None), regs


# ============================================================================
# 端口表 svh
# ============================================================================
def gen_ports(ports, base, mod):
    decls = []
    for d, ww, n in ports:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        ty = "output logic" if d == "output" else "input "
        decls.append(f"  {ty:13s} {ws}{n}")
    (BK / f"{base}_ports.svh").write_text(
        gen_hdr(mod)
        + f"// 可读核 xs_{mod}_core 端口表(golden 同名扁平端口,无 clock/reset)。\n"
        + ",\n".join(decls) + "\n")


# ============================================================================
# 配置 + error 流水 pkg
# ============================================================================
def gen_pkg(base, mod, frm_regs, err_regs):
    pkgname = base + "_pkg"
    n_frm = len(frm_regs)
    n_err_stage = len(err_regs)  # 打拍级数(REG, REG_1 → 2 级)
    L = [gen_hdr(mod),
         f"// {mod} 容器配置 + critical-error 流水类型。",
         f"// 这些是 SchdBlockParams 单态化(昆明湖)后定死的实例常量与流水级数,",
         f"// 可读核据此用 genvar/struct 重新表达 frm 打拍与 error 聚合(非组合算法)。",
         f"package {pkgname};",
         f"  // §1 需要 frm(动态舍入模式)打拍的 vf-exu 个数;每个各打一拍喂给对应 exu。",
         f"  localparam int NUM_FRM_PIPE = {n_frm};",
         f"",
         f"  // frm 是 3 bit 浮点动态舍入模式。用 struct 显式表达「一拍延迟级」这一寄存语义,",
         f"  // 配合 frm_step() 纯函数描述 RegNext(每拍采样输入),而非散落的 *_REG 标量。",
         f"  typedef struct packed {{",
         f"    logic [2:0] rm;   // 已寄存一拍的舍入模式",
         f"  }} frm_pipe_t;",
         f"",
         f"  // 推进一拍:采样当前 io_frm(等价 RegNext(io.frm))。",
         f"  function automatic frm_pipe_t frm_step(logic [2:0] nin);",
         f"    frm_step.rm = nin;",
         f"  endfunction",
         ]
    if n_err_stage:
        L += [
         f"",
         f"  // §2 critical-error 聚合流水:含 CSR 的 exu 的 error 经 {n_err_stage} 级寄存后输出。",
         f"  //     用移位寄存器 struct 表达「逐拍右移、最末级即输出」的打拍链。",
         f"  localparam int ERR_PIPE_DEPTH = {n_err_stage};",
         f"  typedef struct packed {{",
         f"    // stage[0] 为最靠近输入的一级,stage[DEPTH-1] 为输出级。",
         f"    logic [ERR_PIPE_DEPTH-1:0] stage;",
         f"  }} err_pipe_t;",
         f"",
         f"  // 推进一拍:整体右移引入新采样,最高位丢弃。",
         f"  function automatic err_pipe_t err_pipe_step(err_pipe_t cur, logic nin);",
         f"    err_pipe_step.stage = {{nin, cur.stage[ERR_PIPE_DEPTH-1:1]}};",
         f"  endfunction",
         f"",
         f"  // 输出级 = 最低位(经过 DEPTH 拍延迟)。",
         f"  function automatic logic err_pipe_out(err_pipe_t cur);",
         f"    err_pipe_out = cur.stage[0];",
         f"  endfunction",
        ]
    L += [f"endpackage : {pkgname}", ""]
    (BK / f"{pkgname}.sv").write_text("\n".join(L))


# ============================================================================
# 逻辑 svh(§1 frm 流水 / §2 error 流水)—— 可读重写,无 golden 临时名
# ============================================================================
def gen_decls(base, mod, insts, frm_regs, err_src, err_regs):
    """核内信号声明(在所有 include 之前):子模块输出网 + frm/err 流水状态。"""
    internal = set()
    for typ, inst, pins in insts:
        for pin, rhs in pins:
            if rhs.startswith("_"):
                internal.add(rhs)
    if err_src and err_src.startswith("_"):
        internal.add(err_src)
    L = [gen_hdr(mod),
         f"// 核内信号声明(先于 logic/connect include):ExeUnit 输出网 + 流水寄存器状态。",
         f"",
         f"  // ---- ExeUnit 子模块输出网(in_ready / csrio.instrAddrTransType / error 等)----"]
    for wname in sorted(internal):
        L.append(f"  wire {wname};")
    L += [f"",
          f"  // ---- §1 frm 打拍状态 / §2 error 打拍状态 ----",
          f"  frm_pipe_t  frm_pipe [NUM_FRM_PIPE];",
          f"  logic [2:0] frm_q    [NUM_FRM_PIPE];  // 供 connect.svh 接到各 vf-exu 的 io_frm"]
    if err_regs:
        L.append(f"  err_pipe_t  err_pipe;")
    L.append("")
    (BK / f"{base}_decls.svh").write_text("\n".join(L))


def gen_logic(base, mod, frm_regs, err_src, err_regs):
    L = [gen_hdr(mod),
         f"// 容器层真正的时序逻辑(可读重写,无 golden _GEN_/_T_/_REG_ 名)。",
         f"// 状态变量在 decls.svh 声明;ExeUnit 输出网由 connect.svh 例化驱动。",
         f"",
         f"  // ==========================================================================",
         f"  // §1 frm(浮点动态舍入模式)打拍。",
         f"  //   Chisel: exu.io.frm := RegNext(io.frm)。每个 needSrcFrm 的 vf-exu 各打一拍,",
         f"  //   消除 CSR→exu 的 frm 长组合路径。本核用数组 + genvar 表达 {len(frm_regs)} 路同构打拍,",
         f"  //   connect.svh 再把 frm_q[k] 接到第 k 个吃 frm 的 exu。",
         f"  // ==========================================================================",
         f"  for (genvar k = 0; k < NUM_FRM_PIPE; k++) begin : g_frm_pipe",
         f"    always_ff @(posedge clock) frm_pipe[k] <= frm_step(io_frm);",
         f"    assign frm_q[k] = frm_pipe[k].rm;",
         f"  end",
         ]
    if err_regs:
        L += [
         f"",
         f"  // ==========================================================================",
         f"  // §2 critical-error 聚合流水。",
         f"  //   Chisel: HasCriticalErrors.generateCriticalErrors() 把含 CSR 的 exu 报出的",
         f"  //   critical error 经 ERR_PIPE_DEPTH 拍寄存(消除跨模块长路径)后,作为 io_error_0",
         f"  //   送顶层。本核用移位寄存器 struct(err_pipe_t)逐拍推进,而非散落的 *_REG/_REG_1。",
         f"  // ==========================================================================",
         f"  always_ff @(posedge clock)",
         f"    err_pipe <= err_pipe_step(err_pipe, {err_src});",
         f"  assign io_error_0 = err_pipe_out(err_pipe);",
        ]
    L.append("")
    (BK / f"{base}_logic.svh").write_text("\n".join(L))


# ============================================================================
# 连线 svh:ExeUnit 黑盒例化 + 端口机械直连(无逻辑)
# ============================================================================
def gen_connect(base, mod, insts, frm_regs, assigns, err_src, err_regs, gsv):
    # 找出 frm 寄存器名 → frm_q[k] 的映射(按 golden 出现顺序)
    frm_map = {name: i for i, name in enumerate(frm_regs)}

    L = [gen_hdr(mod),
         f"// ExeUnit 各变体黑盒例化 + 扁平端口机械连线。ExeUnit 才是功能单元(FU)实体,",
         f"// 在 UT/FM 两侧均为 golden 黑盒;本层只做同构连线,无任何容器逻辑。",
         f"// 子模块输出网在 decls.svh 声明,本表只例化与连线。",
         f""]

    for typ, inst, pins in insts:
        L.append(f"  {typ} {inst} (")
        rows = []
        for pin, rhs in pins:
            conn = rhs
            # frm 打拍寄存器替换为可读核数组元素
            if rhs in frm_map:
                conn = f"frm_q[{frm_map[rhs]}]"
            rows.append(f"    .{pin} ({conn})")
        L.append(",\n".join(rows))
        L.append("  );")
        L.append("")

    # 顶层 assign:in_ready / instrAddrTransType / csr 透传(error_0 已在 logic.svh 里产生)
    L.append("  // ---- 输出反压 / CSR 透传(直接接子模块输出网)----")
    err_lhs = "io_error_0"
    for lhs, rhs in assigns:
        if lhs == err_lhs:
            continue  # io_error_0 由 logic.svh 的 err_pipe 产生
        L.append(f"  assign {lhs} = {rhs};")
    L.append("")
    (BK / f"{base}_connect.svh").write_text("\n".join(L))


# ============================================================================
# 可读核
# ============================================================================
def gen_core(base, mod, err_regs):
    pkgname = base + "_pkg"
    L = [gen_hdr(mod),
         f"// ============================================================================",
         f"// xs_{mod}_core —— 执行单元簇容器(香山 V2R2 昆明湖)",
         f"// ----------------------------------------------------------------------------",
         f"// 设计意图来源:src/main/scala/xiangshan/backend/exu/ExuBlock.scala  class ExuBlock",
         f"//",
         f"// {mod} 把一个调度块(SchdBlock)里的全部 ExeUnit(执行单元)拼成一簇:",
         f"//   * 自身**没有**数据通路逻辑(分发/仲裁/旁路都在 ExeUnit 子模块或上游 Dispatch);",
         f"//   * 容器层只做三件事(见 *_logic.svh):",
         f"//       §1 frm 打拍——每个吃 frm 的 vf-exu 把 io_frm 打一拍(RegNext)后喂入;",
         f"//       §2 error 聚合——含 CSR 的 exu 的 critical-error 经多级寄存后输出 io_error_0;",
         f"//       §3 反压/CSR 透传——exu 的 in_ready / instrAddrTransType 直连顶层。",
         f"//   * 其余数百个端口为 input<>exu.in / exu.out<>output 的同构连线(见 *_connect.svh)。",
         f"//",
         f"//   上游 issue            ExeUnit 黑盒(FU 实体)            下游写回",
         f"//   ┌──────────┐      ┌────────────────────────────┐    ┌──────────┐",
         f"//   │ in[i][j] │─────▶│ exus / exus_1 / ...(Alu/   │───▶│ out[i][j]│",
         f"//   └──────────┘      │  Mul/Div/Brh/Jump/CSR/...) │    └──────────┘",
         f"//   flush ───广播────▶│                            │",
         f"//   frm  ─§1 打拍───▶│ vf-exu                     │",
         f"//                     │ csr-exu ──§2 error 打拍──▶ │──▶ io_error_0",
         f"//                     └────────────────────────────┘",
         f"//",
         f"// ExeUnit 各变体在 UT/FM 两侧均为 golden 黑盒(它们封装真正的功能单元)。",
         f"// ============================================================================",
         f"module xs_{mod}_core",
         f"  import {pkgname}::*;",
         f"(",
         f"  input  clock,",
         f"  input  reset,",
         f'  `include "{base}_ports.svh"',
         f");",
         f"",
         f'  `include "{base}_decls.svh"    // 子模块输出网 + 流水寄存器状态声明',
         f'  `include "{base}_logic.svh"    // §1 frm 流水 / §2 error 流水(可读重写)',
         f'  `include "{base}_connect.svh"  // ExeUnit 黑盒例化 + 端口机械连线',
         f"",
         f"endmodule",
         f"",
         ]
    (BK / f"{mod}.sv").write_text("\n".join(L))


# ============================================================================
# golden 同名 wrapper + _xs 变体(FM/ST 用,扁平端口适配核)
# ============================================================================
def gen_wrapper_and_variant(ports, mod):
    def emit(modname, instname, hdr):
        decls = []
        for d, ww, n in ports:
            ws = f"[{ww-1}:0] " if ww > 1 else ""
            decls.append(f"  {d:6s} {ws}{n}")
        body = [hdr, f"module {modname}(",
                "  input  clock,", "  input  reset,",
                ",\n".join(decls), ");",
                f"  xs_{mod}_core {instname} ("]
        conns = ["    .clock(clock)", "    .reset(reset)"]
        for d, ww, n in ports:
            conns.append(f"    .{n}({n})")
        body.append(",\n".join(conns))
        body += ["  );", "endmodule", ""]
        return "\n".join(body)

    (BK / f"{mod}_wrapper.sv").write_text(
        emit(mod, "u_core", gen_hdr(mod) + "// golden 同名扁平 wrapper(FM/ST 用):例化可读核。"))
    return emit(f"{mod}_xs", "u_core",
                gen_hdr(mod) + f"// impl 侧变体 {mod}_xs:例化可读核(UT 比对/_FM impl)。")


# ============================================================================
# tb + Makefile
# ============================================================================
def vc(ww):  # 位宽声明串
    return f"[{ww-1}:0] " if ww > 1 else ""


def rand_rhs(ww):
    if ww == 1:
        return "$urandom_range(0,1)"
    return f"{ww}'($urandom)"


def gen_tb(ports, mod, variant_text):
    ins = [(ww, n) for d, ww, n in ports if d == "input"]
    outs = [(ww, n) for d, ww, n in ports if d == "output"]
    L = [gen_hdr(mod), "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    # 输入信号
    for ww, n in ins:
        L.append(f"  logic {vc(ww)}{n};")
    # 输出比对线
    for ww, n in outs:
        L.append(f"  wire {vc(ww)}g_{n};")
        L.append(f"  wire {vc(ww)}i_{n};")
    L.append("")
    # 例化 golden u_g 与 impl u_i
    def inst(modname, instname, prefix):
        conns = ["    .clock(clk)", "    .reset(rst)"]
        for d, ww, n in ports:
            if d == "input":
                conns.append(f"    .{n}({n})")
            else:
                conns.append(f"    .{n}({prefix}{n})")
        return f"  {modname} {instname} (\n" + ",\n".join(conns) + "\n  );"
    L.append(inst(mod, "u_g", "g_"))
    L.append(inst(f"{mod}_xs", "u_i", "i_"))
    L.append("")
    # 随机激励:每拍驱动所有输入
    L.append("  always @(posedge clk) if (!rst) begin")
    for ww, n in ins:
        L.append(f"    {n} <= {rand_rhs(ww)};")
    L.append("  end")
    L.append("")
    # 逐拍比对所有输出(don't-care 用 !$isunknown 跳过)
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for ww, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f'      if(errors<=80) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append("  end")
    L.append("")
    L.append("  initial begin")
    L.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    L.append("")
    vdir = XSSV / "verif/ut" / mod
    vdir.mkdir(parents=True, exist_ok=True)
    (vdir / "tb.sv").write_text("\n".join(L))
    (vdir / "variants_xs.sv").write_text(variant_text)


def gen_makefile(base, mod, sub_types):
    sub_files = [f"{t}.sv" for t in sub_types]
    rtl = [f"$(RTL_DIR)/backend/{base}_pkg.sv",
           f"$(RTL_DIR)/backend/{mod}.sv"]
    sub_lines = " \\\n           ".join(f"$(GOLDEN_RTL)/{f}" for f in sub_files)
    refdeps = " ".join(sub_files)
    L = [f"MODULE = {mod}", "",
         "RTL_DIR = ../../../rtl",
         "GOLDEN_RTL = ../../../golden/chisel-rtl", "",
         "# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。",
         "RTL_SRCS = " + " \\\n           ".join(rtl), "",
         "TB_SRCS = variants_xs.sv tb.sv", "",
         "# ExeUnit 各变体(功能单元实体)全部作 golden 黑盒;UT 双例化两侧共用同一份定义。",
         "SUB_DEPS = " + sub_lines, "",
         "GOLDEN_SRCS = $(GOLDEN_RTL)/" + mod + ".sv $(SUB_DEPS)", "",
         "# FM:impl 侧(wrapper→可读核)与 ref 侧在相同层次黑盒化 ExeUnit。",
         "WRAPPER_SRCS = $(RTL_DIR)/backend/" + mod + "_wrapper.sv $(SUB_DEPS)",
         f"FM_VARIANTS = {mod}",
         f"FM_REF_DEPS_{mod} = {refdeps}", "",
         "include ../../../scripts/ut_common.mk", "",
         "# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。",
         "VCS += +define+SYNTHESIS",
         "VCS += +incdir+$(RTL_DIR)/backend",
         "# ExeUnit 黑盒内例化更深的 golden 叶子(Alu/CSR/Dispatcher/...),用 -y 库目录自动解析。",
         "VCS += -y $(GOLDEN_RTL) +libext+.sv+.v",
         "VCS += -assert disable", ""]
    (XSSV / "verif/ut" / mod / "Makefile").write_text("\n".join(L))


# ============================================================================
def build(mod, base):
    gsv = (GOLDEN / f"{mod}.sv").read_text()
    ports = parse_ports(gsv, mod)
    insts = parse_instances(gsv)
    frm_regs = parse_frm_regs(gsv)
    assigns = parse_assigns(gsv)
    err_src, err_regs = parse_error_pipe(gsv)
    sub_types = sorted({t for t, _, _ in insts})

    gen_ports(ports, base, mod)
    gen_pkg(base, mod, frm_regs, err_regs)
    gen_decls(base, mod, insts, frm_regs, err_src, err_regs)
    gen_logic(base, mod, frm_regs, err_src, err_regs)
    gen_connect(base, mod, insts, frm_regs, assigns, err_src, err_regs, gsv)
    gen_core(base, mod, err_regs)
    variant = gen_wrapper_and_variant(ports, mod)
    gen_tb(ports, mod, variant)
    gen_makefile(base, mod, sub_types)
    print(f"[{mod}] ports={len(ports)} insts={len(insts)} "
          f"frm_pipe={len(frm_regs)} err_depth={len(err_regs)} subtypes={sub_types}")


def main():
    build("ExuBlock", "exublock")
    build("ExuBlock_1", "exublock_1")


if __name__ == "__main__":
    main()
