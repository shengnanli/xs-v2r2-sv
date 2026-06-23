#!/usr/bin/env python3
"""
NewCSR 顶层集成生成器（RISC-V 控制状态寄存器文件，香山 V2R2 KunmingHu）。

设计意图来源（人写 Chisel）：
  src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala  class NewCSR
  + 同目录各 CSR 定义 / CSRPermitModule / InterruptFilter / TrapHandleModule /
    Debug / PMPEntryHandleModule / PMAEntryHandleModule / SstcInterruptGen 等。

分层（与 DCache / MemBlock 同一方法学：可读核 + 机械互联 .svh + 黑盒子模块）：
  NewCSR 是一个**集成/路由模块**：
    * 304 个“单个 CSR 寄存器”子模块（mstatus/mtvec/satp/各 PMP/PMA/trigger/…）
      —— 每个寄存器的位域语义、写掩码、副作用读出都在各自子模块里（黑盒）。
    * 8 个“逻辑辅助”子模块：CSRPermitModule（特权/合法性检查）、InterruptFilter
      （中断仲裁优先级）、TrapHandleModule（异常/中断委托+入口特权级）、Debug
      （触发器/单步/调试入口）、PMP/PMAEntryHandleModule（PMP/PMA 写整形+读出）、
      SstcInterruptGen、CommitIDModule —— 真正的“算法”都在这些黑盒里。

  NewCSR **自身**的可读重写逻辑（取代 golden 展平的 ~1100 个 _T_/_GEN_ glue wire）落在
  可读核 xs_NewCSR_core（rtl/backend/NewCSR.sv + newcsr_pkg.sv）：
    §A CSR 地址译码 + 每寄存器写使能 fanout（wenLegalReg & addr==id，含 VS/S 别名重映射）
    §B 读出路由：rData / regOut 的按地址 Mux1H（VS/S 别名）
    §C 特权级状态机（PRVM/V/debugMode）+ 事件驱动更新（MuxCase）
    §D 异步访问状态机 s_idle/s_waitIMSIC/s_finish（IMSIC/AIA 等待）
    §E trap-entry / xret 事件 valid 仲裁（优先级 + NMIE 门）
    §F 输出 mux：rData/regOut/targetPc/EX_II/EX_VI/flushPipe
    §G 副作用：写 satp 触发流水冲刷、satp/vsatp/hgatp ASID 改变→TLB flush、
       fp/vec status on/off、frm/vstart change 等
  这些用 newcsr_pkg 的 typedef enum（特权级/虚拟态/CSR-FSM）、struct（trap 事件集）、
  function automatic（地址译码/别名重映射）、genvar（按 CSR 表/计数器/PMP 多路）表达。

  机械互联（本脚本从 golden 复刻，纯接线，无 NewCSR 设计决策）：
    * 312 个子模块实例端口->网名连接                 -> newcsr_inst.svh
    * 子模块间互联 reg 声明                          -> newcsr_regs.svh
    * 寄存器/复位 always 块（剥离核接管的状态）      -> newcsr_ff.svh

  子模块在 UT/FM 两侧均黑盒（newcsr_stub.sv）；本核只验证集成/路由层等价。

本脚本同时生成：黑盒 stub、golden 同名 wrapper、UT 镜像 / tb。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "NewCSR.sv").read_text()
LINES = GSV.splitlines()
RTL = XSSV / "rtl/backend"
HDR = "// 自动生成：scripts/gen_newcsr.py —— 勿手改\n"

# 实例名允许大写首字母：golden 中 MhpmeventModule 的实例名为 Mhpmevent3..31（大写 M），
# 旧正则只认小写首字母实例名，漏掉 29 个 MhpmeventModule 实例（既漏 stub 也漏 inst.svh）。
INST_HEAD = re.compile(r"^  ([A-Za-z_][A-Za-z_0-9]*) +([A-Za-z_][A-Za-z_0-9]*) \($")
BODY_END = min(i for i, l in enumerate(LINES) if INST_HEAD.match(l))


# ---------------------------------------------------------------------------
# 顶层端口
# ---------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module NewCSR\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


# ---------------------------------------------------------------------------
# 实例解析
# ---------------------------------------------------------------------------
def unwrap(v):
    v = v.strip()
    if v.startswith("(") and v.endswith(")") and v.count("(") == 1:
        return v[1:-1].strip()
    return v


def parse_instances():
    insts = []
    i = 0
    while i < len(LINES):
        m = INST_HEAD.match(LINES[i])
        if not m:
            i += 1
            continue
        mod, inst = m.group(1), m.group(2)
        i += 1
        raw = []
        while not re.match(r"^  \);$", LINES[i]):
            raw.append(LINES[i])
            i += 1
        conns, cur = [], None
        for l in raw:
            pm = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
            if pm and (pm.group(2).strip() == "" or pm.group(2).strip().startswith("(")):
                if cur:
                    conns.append(cur)
                cur = [pm.group(1), pm.group(2).strip()]
            else:
                cur[1] += " " + l.strip()
        if cur:
            conns.append(cur)
        conns = [(p, re.sub(r"\s+", " ", v).strip().rstrip(",")) for p, v in conns]
        insts.append((mod, inst, conns))
        i += 1
    return insts


# ---------------------------------------------------------------------------
# 黑盒 stub：每类子模块端口取自其 golden 文件；本顶层不存在的内联子模块
# （CSR 寄存器/PMP/PMA/trigger 模块在 NewCSR.sv 之外没有独立 golden 文件，
#  其端口方向从顶层实例的连接 + golden 内 module 定义推断）。NewCSR.sv 自身
# 也内联定义了这些 module，故从 GSV 抽取它们的 module 头即可。
# ---------------------------------------------------------------------------
def collect_module_defs():
    """NewCSR.sv 末尾内联定义了所有子 module；抽出 {name: portblock}。"""
    defs = {}
    for m in re.finditer(r"^module (\w+)\((.*?)\n\);", GSV, re.S | re.M):
        if m.group(1) == "NewCSR":
            continue
        defs[m.group(1)] = m.group(2)
    return defs


def gen_stubs(insts):
    defs = collect_module_defs()
    seen = []
    out = [HDR, "// NewCSR 子模块黑盒 stub（UT/FM 两侧共用，统一黑盒边界）。",
           "// 端口块取自 golden NewCSR.sv 内联 module 定义。\n"]
    for mod, _, _ in insts:
        if mod in seen:
            continue
        seen.append(mod)
        if mod in defs:
            out.append(f"module {mod}(")
            out.append(defs[mod])
            out.append(");")
            out.append("endmodule\n")
        else:
            # 退回外部 golden 文件
            gf = GOLDEN / f"{mod}.sv"
            if gf.exists():
                t = gf.read_text()
                mm = re.search(rf"^module {re.escape(mod)}\((.*?)\n\);", t, re.S | re.M)
                out.append(f"module {mod}(")
                out.append(mm.group(1))
                out.append(");")
                out.append("endmodule\n")
            else:
                out.append(f"// WARN: no def for {mod}")
                out.append(f"module {mod}(); endmodule\n")
    (RTL / "newcsr_stub.sv").write_text("\n".join(out))
    print(f"  stubs: {len(seen)} distinct submodule types")


def gen_inst_svh(insts):
    out = [HDR, "// 312 个子模块实例（端口->网名，原样复刻 golden 互联）。\n"]
    for mod, inst, conns in insts:
        out.append(f"  {mod} {inst} (")
        body = []
        for p, v in conns:
            vv = unwrap(v) if v else ""
            if vv.strip() == "/* unused */":
                vv = ""
            body.append(f"    .{p}({vv})")
        out.append(",\n".join(body))
        out.append("  );")
    (RTL / "newcsr_inst.svh").write_text("\n".join(out) + "\n")


def gen_decls_and_core(insts):
    """步0 骨架：从 golden 抽取所有内部网声明，生成
       newcsr_decls.svh（inst.svh 引用的内部网声明）+ NewCSR.sv（xs_NewCSR_core 骨架）。

    分工：
      * 子模块输出网（_<inst>_*，golden 声明但从不在 glue 中被赋值）由 inst.svh 实例驱动，核只读；
      * 其余核须驱动的 glue/具名网（含暂存的 golden _T_/_GEN_ 余项——inst.svh 仍按 golden 名消费，
        待后续步9 重映射）：步0 以占位 '0 驱动，仅为锁定 296 端口 + inst.svh 契约、令 elaborate 过。
      * 全部输出端口：步0 同样占位 '0。
    步1-9 将逐组用真实可读逻辑替换占位（见 docs/backend/NewCSR.md §5）。
    """
    # golden module 头（296 端口）原样复用，保证 1:1。
    mh = re.search(r"^module NewCSR\((.*?)\n\);", GSV, re.S | re.M).group(1)
    portnames = set()
    outports = []
    for d, w, n in top_ports():
        portnames.add(n)
        if d == "output":
            outports.append(n)
    portnames |= {"clock", "reset"}

    # golden 全部内部网声明 + 宽度。
    dre = re.compile(r"^\s*(wire|reg)\s+(\[\d+:0\]\s*)?([A-Za-z_]\w*)\s*[;=]")
    decl_w = {}
    for l in LINES:
        m = dre.match(l)
        if m:
            decl_w.setdefault(m.group(3), (m.group(2) or "").strip())

    # 子模块输出网 = golden 声明 但 从不被 glue 赋值（wire/reg=、assign、<= 均无）的网。
    assigned = set()
    a1 = re.compile(r"^\s*(?:wire|reg)\s+(?:\[\d+:0\]\s*)?([A-Za-z_]\w*)\s*=")
    a2 = re.compile(r"^\s*assign\s+([A-Za-z_]\w*)\s*=")
    a3 = re.compile(r"^\s*([A-Za-z_]\w*)\s*<=")
    for l in LINES:
        for rx in (a1, a2, a3):
            m = rx.match(l)
            if m:
                assigned.add(m.group(1))
    sub_out_all = {n for n in decl_w if n not in portnames and n not in assigned}

    # inst.svh 引用、且非端口 的网 = 核必须声明的网（缩到 inst.svh 实际消费集）。
    inst_ids = set()
    for _, _, conns in insts:
        for _, v in conns:
            for t in re.findall(r"[A-Za-z_]\w*", v):
                if not re.fullmatch(r"h[0-9A-Fa-f]+", t):
                    inst_ids.add(t)
    need = [x for x in inst_ids if x not in portnames]
    need_sub = sorted(x for x in need if x in sub_out_all)
    need_glue = sorted(x for x in need if x not in sub_out_all)
    gent = [x for x in need_glue if "_GEN" in x or "_T_" in x or x.endswith("_T")]

    def emit(names):
        out = []
        for n in names:
            w = decl_w.get(n, "")
            out.append(f"  logic {(w + ' ') if w else ''}{n};")
        return out

    d = [HDR,
         "// newcsr_inst.svh 引用、且非 wrapper 端口 的内部网声明（步0 骨架）。",
         f"// ① 子模块黑盒输出网（_<inst>_*，由 inst.svh 实例驱动，核只读）：{len(need_sub)} 个。",
         f"// ② 核须驱动的 glue/具名网：{len(need_glue)} 个，其中 golden _T_/_GEN_ 余项 {len(gent)} 个",
         "//    （仅因 inst.svh 仍按 golden 名消费，待步9 重映射）。统一用 logic 声明。\n",
         "  // ===== ① 子模块黑盒输出网 ====="]
    d += emit(need_sub)
    d.append("\n  // ===== ② 核须驱动的 glue / 具名网 =====")
    d += emit(need_glue)
    (RTL / "newcsr_decls.svh").write_text("\n".join(d) + "\n")

    c = [HDR,
         "// ============================================================================",
         "// xs_NewCSR_core —— 香山 NewCSR 可读核（步0：骨架 + 契约锁定）",
         "// 设计意图：src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala（class NewCSR）",
         "//   * 296 端口 = NewCSR_wrapper.sv 模块头 1:1（contract 锁定）。",
         "//   * include newcsr_decls.svh（inst.svh 引用的内部网声明）。",
         "//   * include newcsr_inst.svh（341 子模块黑盒实例，机械互联）。",
         "//   * 核须驱动的 glue/具名网 + 全部输出端口：步0 暂以占位 '0 驱动，",
         "//     仅为令 VCS elaborate 通过、锁死端口与 inst.svh 契约。",
         "// 步1-9（读Mux→priority case / 写fanout / 特权FSM / trap派发 / 副作用 / 输出广播 /",
         "//   perf·trigger / IMSIC异步 / difftest打拍 / inst.svh重映射）逐组替换占位。",
         "// ============================================================================",
         "import newcsr_pkg::*;\n",
         "module xs_NewCSR_core(",
         mh,
         ");\n",
         "  // ====== 子模块输出网 + glue/具名网 声明 ======",
         '  `include "newcsr_decls.svh"\n',
         "  // ========================================================================",
         f"  // 步0 占位驱动：核须驱动的 glue/具名网（{len(need_glue)} 个）暂置 0。",
         "  // 其中以 _T_/_GEN_ 命名者为 golden 余项——待步9 重映射为可读具名网后消除。",
         "  // ========================================================================"]
    for n in need_glue:
        c.append(f"  assign {n} = '0;")
    c.append("\n  // ----- 输出端口占位驱动（步2+ 接真实逻辑）-----")
    for n in outports:
        c.append(f"  assign {n} = '0;")
    c.append("\n  // ====== 341 子模块实例（机械互联，黑盒）======")
    c.append('  `include "newcsr_inst.svh"')
    c.append("endmodule")
    (RTL / "NewCSR.sv").write_text("\n".join(c) + "\n")
    print(f"  decls.svh: {len(need_sub)} sub-out + {len(need_glue)} glue "
          f"({len(gent)} _T_/_GEN_ remnants); NewCSR.sv core skeleton")


def flat_wrapper(modname, core, ps):
    decls = [f"  {d:6s} {('['+str(w-1)+':0] ') if w > 1 else ''}{n}"
             for d, w, n in ps]
    L = [f"module {modname}(", ",\n".join(decls) + "\n);",
         f"  {core} u_core (",
         ",\n".join(f"    .{n}({n})" for _, _, n in ps), "  );", "endmodule\n"]
    return "\n".join(L)


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0; logic rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        T.append(f"  logic {('['+str(w-1)+':0] ') if w > 1 else ''}{n};")
    for w, n in outs:
        ws = ('['+str(w-1)+':0] ') if w > 1 else ''
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    T.append("  NewCSR    u_g (" + ", ".join(gc + [f".{n}(g_{n})" for _, n in outs]) + ");")
    T.append("  NewCSR_xs u_i (" + ", ".join(gc + [f".{n}(i_{n})" for _, n in outs]) + ");")

    def rnd(w, n):
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()'] * rep)}}})"

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
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def gen_wrapper_and_ut(ps):
    (RTL / "NewCSR_wrapper.sv").write_text(HDR + flat_wrapper("NewCSR", "xs_NewCSR_core", ps))
    ut = XSSV / "verif/ut/NewCSR"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(HDR + flat_wrapper("NewCSR_xs", "xs_NewCSR_core", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))


if __name__ == "__main__":
    ps = top_ports()
    insts = parse_instances()
    print(f"NewCSR: {len(ps)} ports, {len(insts)} sub-instances, "
          f"body(pre-inst) {BODY_END} lines")
    gen_stubs(insts)
    gen_inst_svh(insts)
    gen_decls_and_core(insts)
    gen_wrapper_and_ut(ps)
    print("generated: stub / inst.svh / decls.svh / NewCSR.sv(core) / wrapper / ut(variants+tb)")
