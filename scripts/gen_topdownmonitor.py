#!/usr/bin/env python3
"""生成 TopDownMonitor (L2 top-down 性能监视器) 的 wrapper/UT/Makefile。

golden TopDownMonitor 只有 **单个输出** io_debugTopDown_l2MissMatch (纯组合)。
它 = OR over 4 bank × 16 MSHR = 64 项:
    robHeadPaddr_valid
      & {msStatus_b_i_reqTag, msStatus_b_i_set, 2'h<b>} == {12'h0, robHeadPaddr_bits[35:6]}
      & msStatus_b_i_valid & msStatus_b_i_is_miss
其余端口(dirResult/latePF/channel/is_prefetch 等)在 golden 中只喂 firtool 裁剪掉
的性能计数器输出所对应的悬空中间 wire —— 不驱动任何输出, 属 golden-only dead cone。
可读核只重建真正驱动输出的那 64 项匹配逻辑, 与 golden 单输出逐位等价。

本脚本解析 golden 端口表(保持逐字节端口顺序), 产出:
  rtl/l2/TopDownMonitor_wrapper.sv        FM impl 顶层(golden 同名)
  verif/ut/TopDownMonitor/variants_xs.sv  UT impl 顶层(TopDownMonitor_xs)
  verif/ut/TopDownMonitor/tb.sv / Makefile

用法: python3 scripts/gen_topdownmonitor.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
TOP = "TopDownMonitor"
NBANK = 4
NMSHR = 16


def parse_ports(text, module):
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        pm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = pm.groups()
        ports.append((d, w or "", n))
    return ports


def decl(d, w, n):
    return f"  {d} {w}{' ' if w else ''}{n}"


def gen_body():
    """真正驱动输出的 64 项匹配 OR。"""
    L = []
    L.append("  // ---- 唯一输出: io_debugTopDown_l2MissMatch (纯组合, 64 项 MSHR 匹配 OR) ----")
    L.append("  // _GEN = {12'h0, robHeadPaddr_bits[35:6]} —— rob 头指令物理地址的 cacheline")
    L.append("  wire [41:0] cmp_key = {12'h0, io_debugTopDown_robHeadPaddr_bits[35:6]};")
    L.append("  // 每 bank 的 2 位低位标签(= bank 号), 与 golden {reqTag, set, 2'h<b>} 一致")
    L.append("  wire [63:0] match_vec;")
    for b in range(NBANK):
        for i in range(NMSHR):
            idx = b * NMSHR + i
            L.append(
                f"  assign match_vec[{idx}] = io_debugTopDown_robHeadPaddr_valid"
                f" & ({{io_msStatus_{b}_{i}_bits_reqTag, io_msStatus_{b}_{i}_bits_set, 2'h{b}}} == cmp_key)"
                f" & io_msStatus_{b}_{i}_valid & io_msStatus_{b}_{i}_bits_is_miss;"
            )
    L.append("  assign io_debugTopDown_l2MissMatch = |match_vec;")
    return "\n".join(L)


def gen():
    text = (GOLDEN / f"{TOP}.sv").read_text()
    ports = parse_ports(text, TOP)
    body = gen_body()
    hdr = ",\n".join(decl(*p) for p in ports)

    banner_note = (
        "// TopDownMonitor —— 手写可读实现(TL2 shard, AUX signoff)。\n"
        "// L2 top-down 性能监视器。唯一功能输出 io_debugTopDown_l2MissMatch:\n"
        "// 当 rob 头指令物理地址命中某个正在 miss 的 L2 MSHR(4 bank×16)时置 1,\n"
        "// 用于 top-down 分析中判定 rob 阻塞是否由 L2 miss 造成。\n"
        "// 其余输入(dirResult/latePF/msStatus 的 channel/is_prefetch 等)在 golden 里\n"
        "// 只喂被 firtool 裁剪掉的性能计数器, 属 golden-only 悬空 dead cone, 不驱动输出。\n"
    )
    wrapper = (banner_note + f"module {TOP}(\n" + hdr + "\n);\n" + body + "\nendmodule\n")
    (ROOT / "rtl" / "l2" / f"{TOP}_wrapper.sv").write_text(wrapper)

    variant = (banner_note + f"module {TOP}_xs(\n" + hdr + "\n);\n" + body + "\nendmodule\n")
    utdir = ROOT / "verif" / "ut" / TOP
    utdir.mkdir(parents=True, exist_ok=True)
    (utdir / "variants_xs.sv").write_text(variant)
    (utdir / "tb.sv").write_text(gen_tb(ports))
    (utdir / "Makefile").write_text(gen_makefile())
    print(f"[gen_topdownmonitor] {TOP}: ports={len(ports)}")


def width_of(w):
    if not w:
        return 1
    m = re.match(r"\[(\d+):(\d+)\]", w)
    return int(m.group(1)) - int(m.group(2)) + 1


def gen_tb(ports):
    ins = [(w, n) for (d, w, n) in ports if d == "input"]
    outs = [(w, n) for (d, w, n) in ports if d == "output"]
    L = []
    L.append(f"// {TOP} 双例化逐拍比对: golden {TOP} vs 可读 {TOP}_xs (随机激励).")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHECK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append('      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \\')
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0;")
    L.append("  int errors = 0;")
    L.append("  int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")

    def inst(mod, iname, gpref):
        s = [f"  {mod} {iname} ("]
        conns = []
        for d, w, n in ports:
            if d == "output":
                conns.append(f".{n}({gpref}{n})")
            else:
                conns.append(f".{n}({n})")
        s.append("    " + ",\n    ".join(conns))
        s.append("  );")
        return "\n".join(s)

    L.append(inst(TOP, "u_g", "g_"))
    L.append(inst(f"{TOP}_xs", "u_i", "i_"))

    # 随机激励: 大部分输入无关紧要, 但要让 match 有机会触发, 需偶尔让某 MSHR 的
    # {reqTag,set,bank} 对齐 robHeadPaddr。用低熵地址空间提高命中率。
    L.append("  task automatic drive_random_inputs();")
    for w, n in ins:
        bw = width_of(w)
        if bw == 1:
            L.append(f"    {n} = $urandom_range(0, 1);")
        else:
            L.append(f"    {n} = {bw}'($urandom);")
    # 用一个小的公共地址域, 让匹配偶尔命中(否则 output 恒 0, 只测得 trivial 路径)。
    L.append("    // 约束: 让 reqTag/set 与 robHeadPaddr 落在小域, 提高 match 命中率")
    L.append("    io_debugTopDown_robHeadPaddr_bits = 36'($urandom_range(0, 255)) << 6;")
    for b in range(NBANK):
        for i in range(NMSHR):
            L.append(f"    io_msStatus_{b}_{i}_bits_reqTag = 31'($urandom_range(0, 3));")
            L.append(f"    io_msStatus_{b}_{i}_bits_set = 9'($urandom_range(0, 15));")
    L.append("  endtask")

    L.append("  task automatic check_outputs();")
    for w, n in outs:
        L.append(f"    `CHECK({n})")
    L.append("  endtask")

    L.append("  initial begin")
    L.append('    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end')
    for w, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (2) @(posedge clock);")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random_inputs();")
    L.append("      #1 check_outputs();")
    L.append("    end")
    L.append(f'    $display("{TOP} checks=%0d errors=%0d", checks, errors);')
    L.append("    if (errors == 0 && checks > 1000) begin")
    L.append('      $display("TEST PASSED");')
    L.append("      $finish;")
    L.append("    end")
    L.append('    $display("TEST FAILED");')
    L.append("    $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHECK")
    return "\n".join(L) + "\n"


def gen_makefile():
    return f"""# {TOP} UT + FM Makefile
MODULE = {TOP}

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

RTL_SRCS =
WRAPPER_SRCS = $(RTL_DIR)/l2/{TOP}_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/{TOP}.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = {TOP}
# 纯组合叶子, 无子例化/无黑盒。golden 含悬空性能计数器 dead cone(不驱动输出)。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
"""


if __name__ == "__main__":
    gen()
