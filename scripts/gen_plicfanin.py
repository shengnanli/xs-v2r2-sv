#!/usr/bin/env python3
"""生成 PLICFanIn 的 wrapper / 变体 / UT testbench / Makefile。

PLICFanIn 是纯组合叶子模块 (无子模块、无 SRAM、无寄存器)，故无需黑盒 stub。
难点在端口形态差异：golden 端口是扁平标量
  io_prio_0..io_prio_64 (各 [2:0]) + io_ip[64:0] + io_dev[6:0] + io_max[2:0]，
而可读核 xs_PLICFanIn_core 把 65 路 prio 打包成 io_prio[64:0][2:0]。
wrapper / 变体在例化核时把扁平 io_prio_d 拼成打包数组传入。

产物：
  - wrapper (golden 同名 PLICFanIn) : FM impl 侧顶层，例化 xs_PLICFanIn_core
  - 变体    (PLICFanIn_xs)           : UT impl 侧顶层，同样例化 xs_PLICFanIn_core
  - tb.sv                            : 双例化 (golden PLICFanIn vs PLICFanIn_xs) 逐拍比对
  - Makefile                         : include ut_common.mk，UT + FM 共用
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "PLICFanIn"

N_DEV = 65          # 设备数 (io_prio_0..io_prio_64)
PRIO_BITS = 3
DEV_BITS = 7

# golden 端口（按声明顺序），用于 wrapper / tb 例化对接
def golden_ports():
    ports = []
    for d in range(N_DEV):
        ports.append(("input", f"[{PRIO_BITS-1}:0]", f"io_prio_{d}"))
    ports.append(("input", f"[{N_DEV-1}:0]", "io_ip"))
    ports.append(("output", f"[{DEV_BITS-1}:0]", "io_dev"))
    ports.append(("output", f"[{PRIO_BITS-1}:0]", "io_max"))
    return ports


def module_header(name, ports):
    body = ",\n".join(
        f"  {d} {w} {n}" if w else f"  {d} {n}" for d, w, n in ports
    )
    return f"module {name}(\n{body}\n);\n"


def core_inst(inst_name):
    """例化 xs_PLICFanIn_core：把扁平 io_prio_d 拼进打包数组 io_prio。"""
    prio_concat = ", ".join(f"io_prio_{d}" for d in range(N_DEV - 1, -1, -1))
    return (
        f"  // 把 65 路扁平 io_prio_d 拼成打包数组 (高索引在前)，喂给可读核\n"
        f"  logic [{N_DEV-1}:0][{PRIO_BITS-1}:0] prio_packed;\n"
        f"  assign prio_packed = {{{prio_concat}}};\n\n"
        f"  xs_PLICFanIn_core {inst_name} (\n"
        f"    .io_prio (prio_packed),\n"
        f"    .io_ip   (io_ip),\n"
        f"    .io_dev  (io_dev),\n"
        f"    .io_max  (io_max)\n"
        f"  );\n"
    )


def gen_wrapper(top):
    ports = golden_ports()
    return (
        "// 自动生成：scripts/gen_plicfanin.py —— 勿手改\n"
        + module_header(top, ports)
        + core_inst("u_core")
        + "endmodule\n"
    )


def gen_variant():
    ports = golden_ports()
    return (
        "// 自动生成：scripts/gen_plicfanin.py —— 勿手改\n"
        + module_header("PLICFanIn_xs", ports)
        + core_inst("u_core")
        + "endmodule\n"
    )


def gen_tb():
    ports = golden_ports()
    inputs = [p for p in ports if p[0] == "input"]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_plicfanin.py —— 勿手改",
        "// PLICFanIn 双例化逐拍比对：golden PLICFanIn vs 可读重写 PLICFanIn_xs。",
        "// 纯组合模块：每拍随机驱动 65 路优先级 + 65 位挂起向量，比对 io_dev/io_max。",
        "// 激励混合：全随机 + 偏置 (大量未挂起 / 单热挂起 / 全挂起) 以覆盖仲裁边界。",
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
    for _, w, n in inputs:
        lines.append(f"  logic {w} {n};")
    for _, w, n in outputs:
        lines.append(f"  wire {w} g_{n};")
        lines.append(f"  wire {w} i_{n};")
    # golden 例化
    lines += ["", "  PLICFanIn u_g ("]
    for idx, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"g_{n}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{n}({sig}){comma}")
    lines += ["  );", "", "  PLICFanIn_xs u_i ("]
    for idx, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"i_{n}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{n}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  // 随机驱动：mode 控制挂起向量分布，覆盖仲裁各路径",
        "  task automatic drive_random_inputs();",
        "    int mode;",
        "    mode = $urandom_range(0, 4);",
        "    // 优先级始终全随机 (3 位)",
    ]
    for d in range(N_DEV):
        lines.append(f"    io_prio_{d} = {PRIO_BITS}'($urandom);")
    lines += [
        "    case (mode)",
        "      0: io_ip = '0;                          // 无挂起：占位设备(dev=0)应胜出",
        "      1: io_ip = (65'h1 << $urandom_range(0, 64)); // 单热挂起",
        "      2: io_ip = '1;                          // 全挂起",
        "      3: io_ip = {65{1'b0}} | (65'($urandom) & 65'($urandom)); // 稀疏随机(两随机数相与，挂起更稀)",
        "      default: io_ip = {32'($urandom), 33'($urandom)}; // 全随机 65 位",
        "    endcase",
        "  endtask",
        "",
        "  task automatic check_outputs();",
    ]
    for _, _, n in outputs:
        lines.append(f"    `CHECK({n})")
    lines += [
        "  endtask",
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
    ]
    for _, _, n in inputs:
        lines.append(f"    {n} = '0;")
    lines += [
        "    repeat (4) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        "    $display(\"PLICFanIn checks=%0d errors=%0d\", checks, errors);",
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


def main():
    UT.mkdir(parents=True, exist_ok=True)
    (RTL / "PLICFanIn_wrapper.sv").write_text(gen_wrapper("PLICFanIn"))
    (UT / "variants_xs.sv").write_text(gen_variant())
    (UT / "tb.sv").write_text(gen_tb())
    (UT / "Makefile").write_text(
        """MODULE = PLICFanIn

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/plic_pkg.sv \\
           $(RTL_DIR)/uncore/PLICFanIn.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PLICFanIn.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/PLICFanIn_wrapper.sv
FM_VARIANTS = PLICFanIn

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated PLICFanIn wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
