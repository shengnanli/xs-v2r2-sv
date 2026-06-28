#!/usr/bin/env python3
"""生成 DebugModule 的 wrapper / 变体 / 双时钟 UT testbench / Makefile / golden_filelist。

DebugModule 是纯装配 glue: 1 个 hartIsInReset 同步寄存器 + 例化两大黑盒
  - TLDebugModule         调试模块主体 (DM 寄存器/抽象命令/SBA/hart reset)
  - DebugTransportModuleJTAG  JTAG TAP -> DMI 传输模块
中间用 DMI 总线相连。端口全为标量/向量 (无 struct), 故 wrapper/变体直接同名透传
例化 xs_DebugModule_core (同 IMSIC 模式)。

子块在 FM 时两侧都黑盒 (不进 FM_IMPL_SRCS / FM_REF_DEPS), 比对聚焦本层 glue
(同步寄存器 + DMI/总线连线) 的等价。

UT 难点: JTAG 走独立 TCK 时钟域 -> tb 需双时钟驱动 (io_clock 主域 + TCK 域),
两侧共用真实子模块 (33 个 golden 依赖文件, 经 golden_filelist.f 显式编译)。

产物:
  - rtl/uncore/DebugModule_wrapper.sv   (golden 同名 DebugModule, FM impl 顶层)
  - verif/ut/DebugModule/variants_xs.sv (DebugModule_xs, UT impl 顶层)
  - verif/ut/DebugModule/tb.sv          (双时钟双例化逐拍比对)
  - verif/ut/DebugModule/Makefile
  - verif/ut/DebugModule/golden_filelist.f (33 个子块依赖, UT 双例化用)
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "DebugModule"

# ---- 时钟 / 复位 / TCK 域输入 / IDCODE 常量, 用于 tb 分类驱动 ----
CLOCKS = {"io_clock", "io_debugIO_clock", "io_debugIO_systemjtag_jtag_TCK"}
RESETS = {"io_reset", "io_debugIO_reset", "io_debugIO_systemjtag_reset"}
TCK_INPUTS = {"io_debugIO_systemjtag_jtag_TMS", "io_debugIO_systemjtag_jtag_TDI"}
IDCODE = {  # IDCODE 三段, 仿真里取固定常量 (任意非 X 值即可)
    "io_debugIO_systemjtag_mfr_id": "11'h536",
    "io_debugIO_systemjtag_part_number": "16'h1234",
    "io_debugIO_systemjtag_version": "4'h1",
}

# 黑盒两大子模块的 golden 依赖传递闭包 (UT 双例化需真实编入)。
BLACKBOX_ROOTS = ["TLDebugModule", "DebugTransportModuleJTAG"]


def parse_ports(path, module):
    text = path.read_text()
    match = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    if not match:
        raise RuntimeError(f"module {module} not found in {path}")
    ports = []
    for raw in match.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        m = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        if not m:
            raise RuntimeError(f"cannot parse port line: {raw}")
        direction, width, name = m.groups()
        ports.append((direction, width or "", name))
    return ports


def closure(roots):
    """计算从 roots 出发的模块实例化传递闭包对应的 golden 文件集合。"""
    defs = {}
    for f in GOLDEN.glob("*.sv"):
        for mname in re.findall(r"^module\s+([A-Za-z_]\w*)\s*[(#;]", f.read_text(errors="ignore"), re.M):
            defs.setdefault(mname, f)
    allmods = set(defs)
    seen, files, stack = set(), set(), list(roots)
    while stack:
        mod = stack.pop()
        if mod in seen or mod not in defs:
            continue
        seen.add(mod)
        f = defs[mod]
        files.add(f.name)
        txt = re.sub(r"//[^\n]*", "", f.read_text(errors="ignore"))
        # 实例化形如 `ModName inst (` 或 `ModName #(...) inst (`; 模块名首字母大写
        # (TL*/Async*) 或小写存储宏 (ram_NxM)。凡在 allmods 里且非 SV 关键字即收。
        for m in re.finditer(r"(?<![\w.])([A-Za-z_]\w*)\s+(?:#\s*\([^;]*?\)\s*)?[a-zA-Z_]\w*\s*\(", txt):
            nm = m.group(1)
            if nm in allmods and nm not in seen:
                stack.append(nm)
    return sorted(files)


def decl(direction, width, name):
    gap = " " if width else ""
    return f"  {direction} {width}{gap}{name}"


def module_header(name, ports):
    return f"module {name}(\n" + ",\n".join(decl(*p) for p in ports) + "\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for idx, (_, _, port) in enumerate(ports):
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{port}({port}){comma}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(top, ports):
    return ("// 自动生成：scripts/gen_debugmodule.py —— 勿手改\n"
            + module_header(top, ports)
            + inst("xs_DebugModule_core", "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_debugmodule.py —— 勿手改\n"
            + module_header("DebugModule_xs", ports)
            + inst("xs_DebugModule_core", "u_core", ports) + "\nendmodule\n")


def bit_width(width):
    if not width:
        return 1
    hi, lo = map(int, re.match(r"\[(\d+):(\d+)\]", width).groups())
    return abs(hi - lo) + 1


def rand_expr(width):
    bits = bit_width(width)
    if bits == 1:
        return "$urandom_range(0, 1)"
    words = max(1, (bits + 31) // 32)
    return f"{bits}'({{{', '.join(['$urandom'] * words)}}})"


def signal_decl(kind, width, name):
    gap = " " if width else ""
    return f"  {kind} {width}{gap}{name};"


def gen_tb(ports):
    outputs = [p for p in ports if p[0] == "output"]
    # 主域随机输入 = input 且非时钟/复位/TCK域/IDCODE
    main_in = [p for p in ports if p[0] == "input" and p[2] not in CLOCKS | RESETS | TCK_INPUTS | set(IDCODE)]
    tck_in = [p for p in ports if p[2] in TCK_INPUTS]

    L = [
        "// 自动生成：scripts/gen_debugmodule.py —— 勿手改",
        "// DebugModule 双时钟双例化逐拍比对: golden DebugModule vs 可读重写 DebugModule_xs。",
        "// 两侧共用真实子模块 (TLDebugModule + DebugTransportModuleJTAG + 31 个依赖)。",
        "// 双时钟: clock 主域 (io_clock/io_debugIO_clock) + tck 域 (JTAG/DMI)。",
        "// 被测的本层逻辑 = hartIsInReset 同步寄存器 + DMI/总线连线; 连线/打拍若有误,",
        "// 子模块收到不同输入 -> 输出发散 -> 逐拍比对捕获。",
        "`timescale 1ns/1ps",
        "`define CHECK(SIG) begin \\",
        "  if (!$isunknown(g_``SIG)) begin \\",
        "    checks++; \\",
        "    if (g_``SIG !== i_``SIG) begin \\",
        "      errors++; \\",
        "      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\",
        "    end \\",
        "  end \\",
        "end",
        "module tb;",
        "  int unsigned NCYCLES = 200000;",
        "  bit clock = 0;   // 主域时钟 (io_clock = io_debugIO_clock)",
        "  bit tck   = 0;   // JTAG/DMI 时钟 (与主域异步)",
        "  bit mrst, drst, jrst;  // 主复位 / debug 复位 / jtag(DMI) 复位",
        "  int errors = 0;",
        "  int checks = 0;",
        "  always #5  clock = ~clock;   // 100MHz",
        "  always #17 tck   = ~tck;     // ~29MHz, 与主域错相异步",
        "",
    ]
    # 信号声明
    for _, width, name in main_in + tck_in:
        L.append(signal_decl("logic", width, name))
    for name, val in IDCODE.items():
        w = next(width for _, width, n in ports if n == name)
        L.append(signal_decl("logic", w, name))
    for _, width, name in outputs:
        L.append(signal_decl("wire", width, f"g_{name}"))
        L.append(signal_decl("wire", width, f"i_{name}"))
    L.append("")

    # 两实例例化: 时钟/复位映射, 数据端口分别接 g_/i_
    def conn(prefix):
        lines = []
        for direction, _, name in ports:
            if name == "io_clock" or name == "io_debugIO_clock":
                sig = "clock"
            elif name == "io_debugIO_systemjtag_jtag_TCK":
                sig = "tck"
            elif name == "io_reset":
                sig = "mrst"
            elif name == "io_debugIO_reset":
                sig = "drst"
            elif name == "io_debugIO_systemjtag_reset":
                sig = "jrst"
            elif direction == "input":
                sig = name
            else:
                sig = f"{prefix}{name}"
            lines.append(f"    .{name}({sig})")
        return ",\n".join(lines)

    L.append("  DebugModule u_g (")
    L.append(conn("g_"))
    L.append("  );")
    L.append("")
    L.append("  DebugModule_xs u_i (")
    L.append(conn("i_"))
    L.append("  );")
    L.append("")

    # 主域随机激励
    L.append("  task automatic drive_main_inputs();")
    for _, width, name in main_in:
        L.append(f"    {name} <= {rand_expr(width)};")
    L.append("  endtask")
    L.append("")
    # TCK 域随机激励
    L.append("  task automatic drive_tck_inputs();")
    for _, width, name in tck_in:
        L.append(f"    {name} <= {rand_expr(width)};")
    L.append("  endtask")
    L.append("")
    # 输出比对
    L.append("  task automatic check_outputs();")
    for _, _, name in outputs:
        L.append(f"    `CHECK({name})")
    L.append("  endtask")
    L.append("")
    # TCK 域驱动 (独立 always)
    L.append("  always @(negedge tck) if (!jrst) drive_tck_inputs();")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    // IDCODE 常量")
    for name, val in IDCODE.items():
        L.append(f"    {name} = {val};")
    L.append("    // 全部输入清零, 三组复位拉高")
    for _, _, name in main_in + tck_in:
        L.append(f"    {name} = '0;")
    L.append("    mrst = 1'b1; drst = 1'b1; jrst = 1'b1;")
    L.append("    repeat (8) @(posedge clock);")
    L.append("    repeat (4) @(posedge tck);   // 让 TCK 域复位充分")
    L.append("    mrst = 1'b0; drst = 1'b0; jrst = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_main_inputs();")
    L.append("      @(posedge clock);")
    L.append("      #1 check_outputs();")
    L.append("    end")
    L.append("    $display(\"DebugModule checks=%0d errors=%0d\", checks, errors);")
    L.append("    if (errors == 0 && checks > 1000) begin")
    L.append("      $display(\"TEST PASSED\");")
    L.append("      $finish;")
    L.append("    end")
    L.append("    $display(\"TEST FAILED\");")
    L.append("    $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHECK")
    L.append("")
    return "\n".join(L)


def gen_filelist(files):
    # VCS -f 不展开 Make 变量, 用相对路径 (相对 verif/ut/DebugModule)。
    L = ["// 自动生成：scripts/gen_debugmodule.py —— DebugModule 两大黑盒子块的 golden 依赖闭包",
         "// (UT 双例化需编入真实子模块; -f 显式列出, 每文件一次)"]
    for f in files:
        L.append(f"../../../golden/chisel-rtl/{f}")
    return "\n".join(L) + "\n"


def gen_makefile():
    return """# 自动生成：scripts/gen_debugmodule.py —— 勿手改
MODULE = DebugModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + pkg。两大子块 (TLDebugModule / DebugTransportModuleJTAG) 不在此:
#   UT 经 golden_filelist.f 编入真实子块 (两侧共用);
#   FM 两侧都黑盒 (不进 FM_IMPL_SRCS / FM_REF_DEPS)。
RTL_SRCS = $(RTL_DIR)/uncore/debug_pkg.sv \\
           $(RTL_DIR)/uncore/DebugModule.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden 顶层 (子块依赖闭包见 golden_filelist.f)。
GOLDEN_SRCS = $(GOLDEN_RTL)/DebugModule.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/DebugModule_wrapper.sv
FM_VARIANTS = DebugModule
# FM: TLDebugModule / DebugTransportModuleJTAG 不提供给任一侧 ⇒
#     hdlin_unresolved_modules=black_box 在 ref/impl 两侧黑盒化,
#     比对聚焦 DebugModule 自身同步寄存器 + DMI/总线连线。
# (FM_REF_DEPS_DebugModule 留空, ref 侧只读 DebugModule.sv)

include ../../../scripts/ut_common.mk

# golden 子块含非综合断言/firtool 随机初始化; UT 关随机化并按 initreg+0 初始化,
# 双时钟域 + 异步跨域队列在两实例间确定性演化。
VCS += +define+SYNTHESIS
VCS += +vcs+initreg+random
VCS += -assert disable
VCS += +libext+.sv+.v
VCS += -f golden_filelist.f
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "DebugModule.sv", "DebugModule")
    files = closure(BLACKBOX_ROOTS)
    # 闭包含两个根自身 (顶层), UT 的 golden 顶层已在 GOLDEN_SRCS 单列 DebugModule.sv,
    # 但 TLDebugModule / DebugTransportModuleJTAG 作为依赖须保留在 filelist。
    (RTL / "DebugModule_wrapper.sv").write_text(gen_wrapper("DebugModule", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(gen_makefile())
    (UT / "golden_filelist.f").write_text(gen_filelist(files))
    print(f"generated DebugModule wrapper / variant / tb / Makefile; {len(files)} golden dep files")


if __name__ == "__main__":
    main()
