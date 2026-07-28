#!/usr/bin/env python3
"""生成 FastArbiter 族 2 输入变体 (_77/_78/_79) 的可读核 / wrapper / 变体 / UT / Makefile。

FastArbiter_77/78/79 是 XSTop 顶层 CHI 交叉开关的 **2 输入** round-robin 仲裁器
(与 SNXbar/RNXbar 里的 4 输入变体 _27/_44/_46/_47 同族, 但 N=2 且 golden 用了
特化的 2 位 rrSelOH/rrGrantMask 展开式, 非通用 pkg 形式)。三者 payload 通道不同:

  FastArbiter_77 : CHI RXSNP  (snoop flit: qos/srcID/txnID/fwdNID/opcode/addr/mpam...)
  FastArbiter_78 : CHI RXRSP  (rsp   flit: qos/tgtID/srcID/txnID/opcode/resp/dbID...)
  FastArbiter_79 : CHI RXDAT  (dat   flit: 256 位 data + be/tag/dataID/dataCheck...)

三个 golden 的仲裁核 (chosenOH/pendingMask/rrGrantMask/rrSelOH/io_out_valid/io_chosen)
**逐字节一致**, 只是 payload struct 字段不同。故可读核 xs_FastArbiter_NN_core 用一段
自包含的 2 输入轮转逻辑 (忠实复刻 golden 特化展开式) + payload one-hot OR 归约多路选择。

golden 2 输入轮转 (与 golden RTL 逐位一致, 不走通用 pkg):
  valids      = {io_in_1_valid, io_in_0_valid}
  _rrSelOH_T3 = rrGrantMask[0] & pendingMask[0]
  rrSelOH     = {rrGrantMask[1] & pendingMask[1] & ~_rrSelOH_T3, _rrSelOH_T3}
  chosenOH    = |(rrSelOH & valids) ? rrSelOH
                                    : {io_in_1_valid & ~io_in_0_valid, io_in_0_valid}
  更新 (io_out_ready & |valids):
    pendingMask <= valids & ~chosenOH
    rrGrantMask <= {chosenOH[0], 1'h0}
  io_out_valid = |valids ; io_chosen = chosenOH[1] (标量)

端口全标量/向量, wrapper/变体直接同名透传例化核。UT: golden vs 可读核双例化, 全随机
激励 (随机 valids + 随机 io_out_ready 自然遍历轮转相位), 逐拍比对全部输出。
FM: ref = golden 叶子 NN.sv; impl = 可读核 + wrapper。无子例化/无黑盒/signoff-strict。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UTROOT = ROOT / "verif" / "ut"

VARIANTS = ["FastArbiter_77", "FastArbiter_78", "FastArbiter_79"]

# 通道名 (仅用于核头注释)
CHAN = {"FastArbiter_77": "RXSNP (snoop)",
        "FastArbiter_78": "RXRSP (rsp)",
        "FastArbiter_79": "RXDAT (dat, 256b data)"}


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


def gen_wrapper(top, ports):
    core = f"xs_{top}_core"
    return ("// 自动生成：scripts/gen_fastarbiter77.py —— 勿手改\n"
            + header(top, ports) + inst(core, "u_core", ports) + "\nendmodule\n")


def gen_variant(top, ports):
    core = f"xs_{top}_core"
    return ("// 自动生成：scripts/gen_fastarbiter77.py —— 勿手改\n"
            + header(f"{top}_xs", ports) + inst(core, "u_core", ports) + "\nendmodule\n")


def payload_fields(ports):
    """从 io_in_0_bits_* 端口提取 payload (name, width) 有序列表。"""
    fields = []
    for d, w, n in ports:
        if d == "input" and n.startswith("io_in_0_bits_"):
            fields.append((n[len("io_in_0_bits_"):], w))
    return fields


def gen_core(top, ports):
    fields = payload_fields(ports)
    port_decls = ",\n".join(decl(*p) for p in ports)
    # struct 声明
    struct_lines = ["  typedef struct packed {"]
    for f, w in fields:
        gap = " " if w else ""
        struct_lines.append(f"    logic {w}{gap}{f};")
    struct_lines.append("  } flit_t;")
    struct = "\n".join(struct_lines)

    # pin[k] 赋值
    def pin_assign(k):
        parts = []
        for f, _ in fields:
            parts.append(f"{f}:io_in_{k}_bits_{f}")
        body = ", ".join(parts)
        return f"  assign pin[{k}] = '{{{body}}};"
    pin0 = pin_assign(0)
    pin1 = pin_assign(1)

    # 输出赋值
    out_lines = []
    for f, _ in fields:
        out_lines.append(f"  assign io_out_bits_{f:<20} = psel.{f};")
    outs = "\n".join(out_lines)

    return f"""// =============================================================================
//  {top} —— CHI {CHAN[top]} 2 路 round-robin 仲裁器 (可读核 xs_{top}_core)
// -----------------------------------------------------------------------------
//  XSTop 顶层 CHI 交叉开关: 2 个上行主口经本仲裁器轮转选一路发往下游。
//  与 SNXbar/RNXbar 的 4 输入 FastArbiter 同族, 但 N=2 且 golden 用特化的 2 位
//  rrSelOH/rrGrantMask 展开式 (非通用 pkg), 本核逐位忠实复刻。
//  payload = CHI {CHAN[top]} flit 子集, 打包成 packed struct 后用胜者 one-hot OR
//  归约多路选择到 io_out。无 io_in_ready 端口 (上游用 io_chosen 自行回送),
//  下游背压只看 io_out_ready。
// =============================================================================
module xs_{top}_core(
{port_decls}
);

  // ---- CHI {CHAN[top]} flit payload (打包成 packed struct, 便于 one-hot OR 多路选择) ----
{struct}

  flit_t       pin [2];
  logic [1:0]  valids;

  assign valids = {{io_in_1_valid, io_in_0_valid}};
{pin0}
{pin1}

  // ---- 2 输入 round-robin 状态 + 组合选胜 (逐位复刻 golden 特化展开) ----
  reg   [1:0] pendingMask;
  reg   [1:0] rrGrantMask;
  logic [1:0] chosenOH;

  wire        rrSelOH_T3 = rrGrantMask[0] & pendingMask[0];
  wire [1:0]  rrSelOH    = {{rrGrantMask[1] & pendingMask[1] & ~rrSelOH_T3, rrSelOH_T3}};
  assign chosenOH =
    (|(rrSelOH & valids)) ? rrSelOH
                          : {{io_in_1_valid & ~io_in_0_valid, io_in_0_valid}};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= 2'h0;
      rrGrantMask <= 2'h0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;     // 没被选中的 valid 转入欠服务
      rrGrantMask <= {{chosenOH[0], 1'h0}};  // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  flit_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < 2; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid = |valids;
{outs}
  assign io_chosen    = chosenOH[1];

endmodule
"""


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


def gen_tb(top, ports):
    variant = f"{top}_xs"
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_fastarbiter77.py —— 勿手改",
        f"// {top} 双例化逐拍比对: golden {top} vs 可读 {variant}。",
        "// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。",
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
    L += ["", f"  {top} u_g ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"g_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", "", f"  {variant} u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"i_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", ""]

    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
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
        f"    $display(\"{top} checks=%0d errors=%0d\", checks, errors);",
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


def gen_makefile(top):
    return f"""# 自动生成：scripts/gen_fastarbiter77.py —— 勿手改
MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/{top}.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/{top}_wrapper.sv
FM_VARIANTS = {top}
# FM: ref = golden {top}.sv; impl = 可读核 + wrapper。无外部依赖/黑盒/signoff-strict。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    for top in VARIANTS:
        ports = parse_ports(GOLDEN / f"{top}.sv", top)
        (RTL / f"{top}.sv").write_text(gen_core(top, ports))
        (RTL / f"{top}_wrapper.sv").write_text(gen_wrapper(top, ports))
        ut = UTROOT / top
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(gen_variant(top, ports))
        (ut / "tb.sv").write_text(gen_tb(top, ports))
        (ut / "Makefile").write_text(gen_makefile(top))
        print(f"generated {top}: core / wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
