#!/usr/bin/env python3
"""生成 TLPLIC 的 wrapper / 变体 / UT testbench / Makefile。

TLPLIC 是 PLIC 主体 (TileLink 寄存器路由器 + LevelGateway×65 + PLICFanIn×2)。
可读核 xs_TLPLIC_core 把 65 路外设中断打包成 int_in[64:0]、2 路对外中断打包成
int_out[1:0]，TileLink 端口去掉 auto_ 前缀 (in_a_*/in_d_*)。golden TLPLIC 端口
是扁平标量 (auto_int_in_0_0..63 + auto_int_in_1_0 + auto_int_out_{0,1}_0 + auto_in_*)。
wrapper / 变体在例化核时做端口形态转换:
  int_in[d]  = auto_int_in_0_d  (d=0..63)
  int_in[64] = auto_int_in_1_0
  auto_int_out_0_0 = int_out[0]; auto_int_out_1_0 = int_out[1]
  auto_in_<x> ↔ in_<x>

子模块 LevelGateway / PLICFanIn 复用已重写可读核 (xs_LevelGateway_core /
xs_PLICFanIn_core)，FM/UT 时与 RTL_SRCS 一并编译。

产物:
  - wrapper (golden 同名 TLPLIC) : FM impl 侧顶层，例化 xs_TLPLIC_core
  - 变体    (TLPLIC_xs)          : UT impl 侧顶层，同样例化 xs_TLPLIC_core
  - tb.sv                        : 双例化 (golden TLPLIC vs TLPLIC_xs) 逐拍比对
  - Makefile                     : include ut_common.mk，UT + FM 共用
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "TLPLIC"

N_DEV = 65          # auto_int_in_0_0..63 (64) + auto_int_in_1_0 (1) = 65
N_HART = 2


def golden_ports():
    """golden TLPLIC 端口 (按声明顺序), 用于 wrapper/tb 例化对接。"""
    ports = [("input", "", "clock"), ("input", "", "reset")]
    ports.append(("input", "", "auto_int_in_1_0"))
    for d in range(64):
        ports.append(("input", "", f"auto_int_in_0_{d}"))
    ports.append(("output", "", "auto_int_out_1_0"))
    ports.append(("output", "", "auto_int_out_0_0"))
    ports += [
        ("output", "", "auto_in_a_ready"),
        ("input", "", "auto_in_a_valid"),
        ("input", "[3:0]", "auto_in_a_bits_opcode"),
        ("input", "[1:0]", "auto_in_a_bits_size"),
        ("input", "[14:0]", "auto_in_a_bits_source"),
        ("input", "[29:0]", "auto_in_a_bits_address"),
        ("input", "[7:0]", "auto_in_a_bits_mask"),
        ("input", "[63:0]", "auto_in_a_bits_data"),
        ("input", "", "auto_in_d_ready"),
        ("output", "", "auto_in_d_valid"),
        ("output", "[3:0]", "auto_in_d_bits_opcode"),
        ("output", "[1:0]", "auto_in_d_bits_size"),
        ("output", "[14:0]", "auto_in_d_bits_source"),
        ("output", "[63:0]", "auto_in_d_bits_data"),
    ]
    return ports


def module_header(name, ports):
    body = ",\n".join(
        f"  {d} {w} {n}" if w else f"  {d} {n}" for d, w, n in ports
    )
    return f"module {name}(\n{body}\n);\n"


# TileLink 端口名映射: golden auto_in_<x>  →  core in_<x>
TL_MAP = {
    "auto_in_a_ready": "in_a_ready",
    "auto_in_a_valid": "in_a_valid",
    "auto_in_a_bits_opcode": "in_a_bits_opcode",
    "auto_in_a_bits_size": "in_a_bits_size",
    "auto_in_a_bits_source": "in_a_bits_source",
    "auto_in_a_bits_address": "in_a_bits_address",
    "auto_in_a_bits_mask": "in_a_bits_mask",
    "auto_in_a_bits_data": "in_a_bits_data",
    "auto_in_d_ready": "in_d_ready",
    "auto_in_d_valid": "in_d_valid",
    "auto_in_d_bits_opcode": "in_d_bits_opcode",
    "auto_in_d_bits_size": "in_d_bits_size",
    "auto_in_d_bits_source": "in_d_bits_source",
    "auto_in_d_bits_data": "in_d_bits_data",
}


def core_inst(inst_name):
    """例化 xs_TLPLIC_core: 扁平 int_in/int_out 与打包向量互转, TileLink 改名直连。"""
    # int_in 拼接: [64]=auto_int_in_1_0, [63:0]=auto_int_in_0_63..0 (高索引在前)
    int_in_concat = ", ".join(
        ["auto_int_in_1_0"] + [f"auto_int_in_0_{d}" for d in range(63, -1, -1)]
    )
    lines = [
        "  // int_in[64]=auto_int_in_1_0, int_in[63:0]=auto_int_in_0_63..0",
        f"  logic [{N_DEV-1}:0] int_in;",
        f"  assign int_in = {{{int_in_concat}}};",
        "  // int_out[0]→hart0(auto_int_out_0_0), int_out[1]→hart1(auto_int_out_1_0)",
        f"  logic [{N_HART-1}:0] int_out;",
        "  assign auto_int_out_0_0 = int_out[0];",
        "  assign auto_int_out_1_0 = int_out[1];",
        "",
        f"  xs_TLPLIC_core {inst_name} (",
        "    .clock      (clock),",
        "    .reset      (reset),",
        "    .int_in     (int_in),",
        "    .int_out    (int_out),",
    ]
    tl = list(TL_MAP.items())
    for idx, (g, c) in enumerate(tl):
        comma = "," if idx + 1 < len(tl) else ""
        lines.append(f"    .{c} ({g}){comma}")
    lines.append("  );")
    return "\n".join(lines) + "\n"


def gen_wrapper(top):
    ports = golden_ports()
    return (
        "// 自动生成：scripts/gen_tlplic.py —— 勿手改\n"
        + module_header(top, ports)
        + core_inst("u_core")
        + "endmodule\n"
    )


def gen_variant():
    ports = golden_ports()
    return (
        "// 自动生成：scripts/gen_tlplic.py —— 勿手改\n"
        + module_header("TLPLIC_xs", ports)
        + core_inst("u_core")
        + "endmodule\n"
    )


def gen_tb():
    ports = golden_ports()
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_tlplic.py —— 勿手改",
        "// TLPLIC 双例化逐拍比对: golden TLPLIC vs 可读重写 TLPLIC_xs。",
        "// 激励: 65 路外设中断 (偏置: 多数拉低/单热/稀疏/全高) + TileLink A 随机请求",
        "// (地址偏向命中合法寄存器区: priority/pending/enable/hart claim)。",
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
        lines.append(f"  logic {w} {n};".replace("  logic  ", "  logic "))
    for _, w, n in outputs:
        lines.append(f"  wire {w} g_{n};".replace("  wire  ", "  wire "))
        lines.append(f"  wire {w} i_{n};".replace("  wire  ", "  wire "))
    # golden 例化
    lines += ["", "  TLPLIC u_g ("]
    for idx, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"g_{n}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{n}({sig}){comma}")
    lines += ["  );", "", "  TLPLIC_xs u_i ("]
    for idx, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"i_{n}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{n}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  // ---- 合法寄存器字节地址 (设备内 30 位地址) ----",
        "  // priorityBase 0x0, pendingBase 0x1000, enableBase 0x2000 (+hart*0x80),",
        "  // hartBase 0x200000 (+hart*0x1000)。地址低 3 位对齐到 8B beat。",
        "  function automatic logic [29:0] pick_addr();",
        "    case ($urandom_range(0, 7))",
        "      0: return 30'($urandom_range(0, 16)) << 3;           // priority 区附近字",
        "      1: return 30'h1000 | (30'($urandom_range(0,1))<<3);  // pending 字 0/1",
        "      2: return 30'h2000 | (30'($urandom_range(0,1))<<3);  // hart0 enable 字",
        "      3: return 30'h2080 | (30'($urandom_range(0,1))<<3);  // hart1 enable 字",
        "      4: return 30'h200000;                                // hart0 threshold/claim",
        "      5: return 30'h201000;                                // hart1 threshold/claim",
        "      default: return 30'($urandom);                       // 全随机 (覆盖未命中)",
        "    endcase",
        "  endfunction",
        "",
        "  // 65 路中断激励: 用 65 位向量 iv 计算分布, 再展开到各扁平端口。",
        "  // iv[d] (d=0..63) → auto_int_in_0_d; iv[64] → auto_int_in_1_0。",
        "  bit [64:0] iv;",
        "  task automatic drive_ints();",
        "    int mode;",
        "    mode = $urandom_range(0, 4);",
        "    case (mode)",
        "      0: begin end                              // 全保持 (沿用上拍, 制造电平)",
        "      1: iv[$urandom_range(0,64)] = ~iv[$urandom_range(0,64)]; // 翻转一路",
        "      2: iv = {32'($urandom), 33'($urandom)} & {32'($urandom), 33'($urandom)}; // 稀疏",
        "      3: iv = '1;                               // 全高",
        "      default: iv = {32'($urandom), 33'($urandom)};          // 全随机",
        "    endcase",
        "    apply_iv();",
        "  endtask",
        "",
        "  // 把 iv 展开到 65 个扁平中断端口",
        "  task automatic apply_iv();",
    ]
    int_assigns = []
    for d in range(64):
        int_assigns.append(f"    auto_int_in_0_{d} = iv[{d}];")
    int_assigns.append("    auto_int_in_1_0 = iv[64];")
    lines += int_assigns
    lines += [
        "  endtask",
        "",
        "  task automatic drive_random_inputs();",
        "    drive_ints();",
        "    auto_in_a_valid        = $urandom_range(0, 1);",
        "    // opcode: 偏向 Get(4,读) / PutFullData(0,写) / PutPartialData(1,写)",
        "    case ($urandom_range(0, 2))",
        "      0: auto_in_a_bits_opcode = 4'h4;",
        "      1: auto_in_a_bits_opcode = 4'h0;",
        "      default: auto_in_a_bits_opcode = 4'h1;",
        "    endcase",
        "    auto_in_a_bits_size    = 2'h3;          // 8 字节访问",
        "    auto_in_a_bits_source  = 15'($urandom);",
        "    auto_in_a_bits_address = pick_addr();",
        "    auto_in_a_bits_mask    = 8'($urandom);",
        "    auto_in_a_bits_data    = {$urandom, $urandom};",
        "    auto_in_d_ready        = $urandom_range(0, 1);",
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
        "    iv = '0;",
    ]
    for _, _, n in inputs:
        lines.append(f"    {n} = '0;")
    lines += [
        "    repeat (8) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        "    $display(\"TLPLIC checks=%0d errors=%0d\", checks, errors);",
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
    (RTL / "TLPLIC_wrapper.sv").write_text(gen_wrapper("TLPLIC"))
    (UT / "variants_xs.sv").write_text(gen_variant())
    (UT / "tb.sv").write_text(gen_tb())
    (UT / "Makefile").write_text(
        """MODULE = TLPLIC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 依赖的已重写叶子 (PLICFanIn / LevelGateway) + pkg
RTL_SRCS = $(RTL_DIR)/uncore/plic_pkg.sv \\
           $(RTL_DIR)/uncore/PLICFanIn.sv \\
           $(RTL_DIR)/uncore/LevelGateway.sv \\
           $(RTL_DIR)/uncore/TLPLIC.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden: TLPLIC 及其子模块
GOLDEN_SRCS = $(GOLDEN_RTL)/TLPLIC.sv \\
              $(GOLDEN_RTL)/PLICFanIn.sv \\
              $(GOLDEN_RTL)/LevelGateway.sv \\
              $(GOLDEN_RTL)/Queue1_RegMapperInput.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TLPLIC_wrapper.sv
FM_VARIANTS = TLPLIC
# FM ref 侧 golden TLPLIC 的子模块依赖
FM_REF_DEPS_TLPLIC = PLICFanIn.sv LevelGateway.sv Queue1_RegMapperInput.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated TLPLIC wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
