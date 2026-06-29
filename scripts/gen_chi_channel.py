#!/usr/bin/env python3
"""通用 CHI / L2 通道叶子的 wrapper / 变体 / UT / Makefile 生成器。

用法:  python3 gen_chi_channel.py <ModuleName> [<ModuleName> ...]

约定 (与 gen_sinka.py 一致):
  - 手写可读核   : rtl/uncore/<Module>.sv 内 module xs_<Module>_core(...)  (手工维护, 本脚本不动)
  - wrapper      : rtl/uncore/<Module>_wrapper.sv  = golden 同名 <Module>, 例化核 (FM impl 顶层)
  - 变体         : verif/ut/<Module>/variants_xs.sv = <Module>_xs, 例化核 (UT impl 顶层)
  - tb.sv        : 双例化 golden <Module> vs <Module>_xs, 逐拍随机激励比对全部输出
  - Makefile     : include ut_common.mk

端口顺序/位宽完全取自 golden RTL, 保证 wrapper / 变体 / 核 三者引脚一一对应。
所有 golden 通道叶子在 +define+SYNTHESIS 下断言被裁掉, 故可全随机激励。
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"

# 模块 → 额外 golden 子模块文件 (黑盒): UT 双例化两侧共用真 golden 定义;
# FM 两侧均不提供该定义 ⇒ 自动黑盒, 只比对外围 glue 等价。
DEPS = {
    "TXRSP": ["Queue16_CHIRSP.sv", "ram_16x62.sv"],
    "TXREQ": ["Queue16_CHIREQ.sv", "ram_16x137.sv"],
    "TXDAT": ["Queue16_TaskBundle.sv", "ram_16x67.sv", "Queue16_DSBeat.sv", "ram_data_16x256.sv"],
    "LCredit2Decoupled": ["Queue4_CHISNP.sv", "ram_4x115.sv"],
    "LCredit2Decoupled_8": ["Queue4_CHIREQ.sv", "ram_4x151.sv"],
    "LCredit2Decoupled_10": ["Queue4_CHIDAT.sv", "ram_4x422.sv"],
}


def parse_ports(path, module):
    text = path.read_text()
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    hi, lo = map(int, mm.groups())
    return abs(hi - lo) + 1


def module_header(name, ports):
    body = ",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in ports)
    return f"module {name}(\n{body}\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{p}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_body(mod, top, ports):
    return ("// 自动生成 scripts/gen_chi_channel.py —— 勿手改\n"
            + module_header(top, ports)
            + inst(f"xs_{mod}_core", "u_core", ports) + "\nendmodule\n")


def gen_tb(mod, ports):
    has_clock = any(n == "clock" for _, _, n in ports)
    has_reset = any(n == "reset" for _, _, n in ports)
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_chi_channel.py —— 勿手改")
    L.append(f"// {mod} 双例化逐拍比对: golden {mod} vs 可读重写 {mod}_xs。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    for instname, pfx in ((mod, "g_"), (f"{mod}_xs", "i_")):
        L.append(f"  {instname} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(ports):
            c = "," if i + 1 < len(ports) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n.endswith("_valid"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n.endswith("_ready"):
            L.append(f"    {n} = ($urandom_range(0,3) != 0);")
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append(f"    $display(\"{mod} checks=%0d errors=%0d\", checks, errors);")
    L.append("    if (errors == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


def makefile(mod):
    deps = DEPS.get(mod, [])
    extra = "".join(f" $(GOLDEN_RTL)/{d}" for d in deps)
    # 子模块 (Queue/RAM) 两侧共用同一份 golden 定义:
    #   UT  : GOLDEN_SRCS 提供给 golden 与 _xs 两实例;
    #   FM  : ref 侧经 FM_REF_DEPS、impl 侧经 WRAPPER_SRCS 都引入同一文件 ⇒ 整体等价比对
    #         (子模块内部点两侧逐一匹配, 只剩外围 glue 真正被验), 避免黑盒未知方向引脚误判。
    wrapper_extra = "".join(f" $(GOLDEN_RTL)/{d}" for d in deps)
    fm_ref_deps = " ".join(deps)
    comment = ("# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): "
               + ", ".join(deps)) if deps else "# 无子模块依赖"
    return f"""MODULE = {mod}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/{mod}.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/{mod}_wrapper.sv{wrapper_extra}

{comment}
GOLDEN_SRCS = $(GOLDEN_RTL)/{mod}.sv{extra}
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = {mod}
FM_REF_DEPS_{mod} = {fm_ref_deps}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def gen_one(mod):
    ut = ROOT / "verif" / "ut" / mod
    ut.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / f"{mod}.sv", mod)
    (RTL / f"{mod}_wrapper.sv").write_text(gen_body(mod, mod, ports))
    (ut / "variants_xs.sv").write_text(gen_body(mod, f"{mod}_xs", ports))
    (ut / "tb.sv").write_text(gen_tb(mod, ports))
    (ut / "Makefile").write_text(makefile(mod))
    print(f"generated {mod}: {len(ports)} ports")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for mod in sys.argv[1:]:
        gen_one(mod)


if __name__ == "__main__":
    main()
