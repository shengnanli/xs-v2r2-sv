#!/usr/bin/env python3
"""生成 AXI4Deinterleaver (AXI4 读响应去交织适配器) 的 wrapper / 变体 / UT testbench / Makefile。

AXI4Deinterleaver 把下游从设备交织返回的 R 通道 burst, 按 ID 分桶 (96 个深度 2 队列, 黑盒
Queue2_AXI4BundleR_3) 去交织成"一旦发某 burst 首拍便连续发到 last"的不交织 R 流。AW/AR/W
控制+写数据透传 in→out, B 写响应透传 out→in。端口全为标量/向量, wrapper/变体同名透传例化
xs_AXI4Deinterleaver_core。

UT: golden AXI4Deinterleaver vs 可读 AXI4Deinterleaver_xs 双例化 (二者共用同一黑盒队列):
  · 下游 R 通道 valid/id/data/last 随机, 其中 r_bits_id 偏置到小范围 (多数 0..7, 少数全 0..95):
    制造同/异 ID 拍交织 + 频繁 burst 末拍, 充分激励 pending 计数 / 优先选择 / locked 状态机;
  · 上游 in.r ready 随机 (制造背压, 覆盖锁定期间出队与换桶);
  · AW/AR/W/B 各通道随机 (覆盖透传通道)。
逐拍比对全部输出。FM: ref=golden AXI4Deinterleaver + 黑盒队列; impl=pkg+核+黑盒队列+wrapper。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "AXI4Deinterleaver"

CORE = "xs_AXI4Deinterleaver_core"
TOP = "AXI4Deinterleaver"
VARIANT = "AXI4Deinterleaver_xs"

# 偏置生成的端口 → 生成器表达式 (其余端口走通用全随机)
SPECIAL_PORTS = {
    "auto_out_r_bits_id": "rand_rid()",
}


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
        d, w, n = m.groups()
        ports.append((d, w or "", n))
    return ports


def decl(d, w, n):
    gap = " " if w else ""
    return f"  {d} {w}{gap}{n}"


def header(name, ports):
    return f"module {name}(\n" + ",\n".join(decl(*p) for p in ports) + "\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{p}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(ports):
    return ("// 自动生成：scripts/gen_axi4deint.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_axi4deint.py —— 勿手改\n"
            + header(VARIANT, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def bit_width(w):
    if not w:
        return 1
    hi, lo = map(int, re.match(r"\[(\d+):(\d+)\]", w).groups())
    return abs(hi - lo) + 1


def rand_expr(w):
    b = bit_width(w)
    if b == 1:
        return "$urandom_range(0, 1)"
    words = max(1, (b + 31) // 32)
    return f"{b}'({{{', '.join(['$urandom'] * words)}}})"


def sdecl(kind, w, n):
    gap = " " if w else ""
    return f"  {kind} {w}{gap}{n};"


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_axi4deint.py —— 勿手改",
        "// AXI4Deinterleaver 双例化逐拍比对: golden AXI4Deinterleaver vs 可读 AXI4Deinterleaver_xs。",
        "// 激励: 下游 R 通道 valid/id(偏置小范围)/data/last 随机 + 上游 r ready 随机 + 其余通道随机。",
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
        "  bit clock = 0;",
        "  bit reset;",
        "  int errors = 0;",
        "  int checks = 0;",
        "  always #5 clock = ~clock;",
        "",
    ]
    for _, w, n in inputs:
        L.append(sdecl("logic", w, n))
    for _, w, n in outputs:
        L.append(sdecl("wire", w, f"g_{n}"))
        L.append(sdecl("wire", w, f"i_{n}"))
    L += ["", f"  {TOP} u_g ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"g_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", "", f"  {VARIANT} u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"i_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", ""]

    # R 响应 ID 生成器: 多数偏置到小范围 [0,7] (制造同 ID 拍交织 + 频繁 burst 完成,
    # 激励 pending 计数饱和 / 优先选择 / locked 锁定); 少数取全范围 [0,95] (覆盖 96 路译码)。
    L.append("  function automatic logic [6:0] rand_rid();")
    L.append("    case ($urandom_range(0, 3))")
    L.append("      0, 1: return 7'($urandom_range(0, 7));   // 小范围: 频繁碰撞/完成 burst")
    L.append("      2:    return 7'($urandom_range(0, 95));  // 全在用范围: 覆盖译码")
    L.append("      default: return 7'($urandom);            // 含越界 [96,127]: 覆盖 padding")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
        if n in SPECIAL_PORTS:
            L.append(f"    {n} <= {SPECIAL_PORTS[n]};")
        else:
            L.append(f"    {n} <= {rand_expr(w)};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outputs:
        L.append(f"    `CHECK({n})")
    L.append("  endtask")
    L += [
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
    ]
    for _, _, n in inputs:
        L.append(f"    {n} = '0;")
    L += [
        "    repeat (6) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        f"    $display(\"{TOP} checks=%0d errors=%0d\", checks, errors);",
        "    if (errors == 0 && checks > 1000) begin",
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
    return "\n".join(L)


def gen_makefile():
    return """# 自动生成：scripts/gen_axi4deint.py —— 勿手改
MODULE = AXI4Deinterleaver

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): 每 ID 一个深度 2 的 R 队列 Queue2_AXI4BundleR_3
# (其内部存储是 golden 行为级 RAM ram_2x264)。
RTL_SRCS = $(RTL_DIR)/uncore/axi4deint_pkg.sv \\
           $(RTL_DIR)/uncore/AXI4Deinterleaver.sv \\
           $(GOLDEN_RTL)/Queue2_AXI4BundleR_3.sv \\
           $(GOLDEN_RTL)/ram_2x264.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_AXI4BundleR_3 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Deinterleaver.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Deinterleaver_wrapper.sv
FM_VARIANTS = AXI4Deinterleaver
# FM: ref = golden AXI4Deinterleaver + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。
FM_REF_DEPS_AXI4Deinterleaver = Queue2_AXI4BundleR_3.sv ram_2x264.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / f"{TOP}.sv", TOP)
    (RTL / f"{TOP}_wrapper.sv").write_text(gen_wrapper(ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(gen_makefile())
    print(f"generated {TOP} wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
