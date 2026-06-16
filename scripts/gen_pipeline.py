#!/usr/bin/env python3
"""Generate Pipeline wrapper, UT harness, Makefile and queue blackbox stub."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "memblock"
UT = ROOT / "verif" / "ut" / "Pipeline"


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
        m = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_][A-Za-z0-9_]*)$", line)
        if not m:
            raise RuntimeError(f"cannot parse port line: {raw}")
        direction, width, name = m.groups()
        ports.append((direction, width or "", name))
    return ports


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


def bit_width(width):
    if not width:
        return 1
    m = re.match(r"\[(\d+):(\d+)\]", width)
    if not m:
        raise RuntimeError(f"bad width {width}")
    hi, lo = map(int, m.groups())
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


def gen_wrapper(top, ports):
    return (
        "// 自动生成：scripts/gen_pipeline.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_Pipeline_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_pipeline.py —— 勿手改\n"
        + module_header("Pipeline_xs", ports)
        + inst("xs_Pipeline_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_pipeline.py —— 勿手改",
        "`timescale 1ns/1ps",
        "`define CHECK(SIG) begin \\",
        "  if (!$isunknown(g_``SIG)) begin \\",
        "    checks++; \\",
        "    if (g_``SIG !== i_``SIG) begin \\",
        "      errors++; \\",
        "      if (errors <= 20) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\",
        "    end \\",
        "  end \\",
        "end",
        "module tb;",
        "  int unsigned NCYCLES = 200000;",
        "  bit clock = 0;",
        "  bit reset;",
        "  int errors = 0;",
        "  int checks = 0;",
        "  always #5 clock = ~clock;",
        "",
    ]
    for _, width, name in inputs:
        lines.append(signal_decl("logic", width, name))
    for _, width, name in outputs:
        lines.append(signal_decl("wire", width, f"g_{name}"))
        lines.append(signal_decl("wire", width, f"i_{name}"))
    for mod, inst_name, prefix in [("Pipeline", "u_g", "g_"), ("Pipeline_xs", "u_i", "i_")]:
        lines += ["", f"  {mod} {inst_name} ("]
        for idx, (direction, _, name) in enumerate(ports):
            sig = name if direction == "input" else f"{prefix}{name}"
            comma = "," if idx + 1 < len(ports) else ""
            lines.append(f"    .{name}({sig}){comma}")
        lines.append("  );")
    lines += ["", "  task automatic drive_random_inputs();"]
    for _, width, name in inputs:
        lines.append(f"    {name} = {rand_expr(width)};")
    lines += ["  endtask", "", "  task automatic check_outputs();"]
    for _, _, name in outputs:
        lines.append(f"    `CHECK({name})")
    lines += [
        "  endtask",
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
    ]
    for _, _, name in inputs:
        lines.append(f"    {name} = '0;")
    lines += [
        "    repeat (8) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        "    $display(\"Pipeline checks=%0d errors=%0d\", checks, errors);",
        "    if (errors == 0) begin",
        "      $display(\"TEST PASSED\");",
        "      $finish;",
        "    end",
        "    $display(\"TEST FAILED\");",
        "    $fatal(1);",
        "  end",
        "endmodule",
        "`undef CHECK",
        "",
    ]
    return "\n".join(lines)


def gen_blackbox():
    ports = parse_ports(GOLDEN / "Queue1_L1PrefetchReq.sv", "Queue1_L1PrefetchReq")
    return (
        "// 自动生成：scripts/gen_pipeline.py —— 勿手改\n"
        "// Queue 叶子黑盒声明：FM 两侧统一边界。\n"
        "(* black_box *)\n"
        + module_header("Queue1_L1PrefetchReq", ports)
        + "endmodule\n"
    )


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "Pipeline.sv", "Pipeline")
    (RTL / "Pipeline_wrapper.sv").write_text(gen_wrapper("Pipeline", ports))
    (RTL / "pipeline_queue_blackbox.sv").write_text(gen_blackbox())
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = Pipeline

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/memblock/pipeline_pkg.sv \\
           $(RTL_DIR)/memblock/Pipeline.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline.sv \\
              $(GOLDEN_RTL)/Queue1_L1PrefetchReq.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/Pipeline_wrapper.sv \\
               $(RTL_DIR)/memblock/pipeline_queue_blackbox.sv
FM_VARIANTS = Pipeline

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
"""
    )


if __name__ == "__main__":
    main()
