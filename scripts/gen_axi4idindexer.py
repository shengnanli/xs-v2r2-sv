#!/usr/bin/env python3
"""生成 AXI4IdIndexer / AXI4IdIndexer_1 (AXI4 ID 重映射适配器) 的核 / wrapper / 变体 / UT / Makefile。

AXI4IdIndexer 是 AXI4 总线链上的"ID 位宽适配器"(diplomacy AXI4IdIndexerNode): 上游主口 ID 宽
与下游从口 ID 宽不一致时, 在 AW/AR 上把上游 ID 适配进下游 ID 空间, 并在 B/R 响应上还原回上游 ID。
两个变体体现两种适配方式 (均为纯组合, 无时钟/寄存器/子模块):

  · AXI4IdIndexer   : 上游 7 位 ID → 下游 14 位 ID, 高位补 0 (零扩展); 响应截低 7 位还原。
                      (下游 ID 空间更大, 给上层 xbar 留前缀位; data 256/addr 48。)
  · AXI4IdIndexer_1 : 下游从口仅支持 2 位 ID; 把上游 7 位 ID 的低 2 位作下游 ID, 高 5 位塞进
                      AXI user-echo 字段 echo.extra_id 随路携带, 响应时从 echo.extra_id 取回高 5
                      位与 2 位 ID 拼回 7 位。这是 rocket-chip AXI4IdIndexer 的经典 echo 机制
                      (data 64/addr 31, 含 lock)。

核 (xs_AXI4IdIndexer_core / xs_AXI4IdIndexer_1_core) 的端口表由本脚本据 golden 端口忠实生成
(避免 ~140 行端口手抄出错), 通道直通 + ID 适配的赋值体为手写可读逻辑 (见下方 BODY 模板)。

UT: 每变体 golden vs 可读变体 双例化逐拍比对全部输出 (纯组合, 各通道 valid/id/载荷/echo 随机)。
FM: 每变体 ref=golden / impl=核+wrapper 证等价 (无黑盒依赖)。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"

CORE_FILE = RTL / "AXI4IdIndexer.sv"

# 每个变体: (golden 顶层名, 核名, 变体名, 核赋值体)
BODY0 = """\
  // ---- 上行 (in→out): AW/AR 把 7 位主口 ID 零扩展到 14 位下游 ID (高 7 位补 0) ----
  assign auto_out_aw_bits_id    = {7'h0, auto_in_aw_bits_id};
  assign auto_out_ar_bits_id    = {7'h0, auto_in_ar_bits_id};
  // ---- 下行 (out→in): B/R 把 14 位下游 ID 截回 7 位主口 ID ----
  assign auto_in_b_bits_id      = auto_out_b_bits_id[6:0];
  assign auto_in_r_bits_id      = auto_out_r_bits_id[6:0];

  // ---- 其余字段全直通 ----
  // 握手: ready 反向直通, valid 正向直通
  assign auto_in_aw_ready       = auto_out_aw_ready;
  assign auto_in_w_ready        = auto_out_w_ready;
  assign auto_in_ar_ready       = auto_out_ar_ready;
  assign auto_in_b_valid        = auto_out_b_valid;
  assign auto_in_r_valid        = auto_out_r_valid;
  assign auto_out_aw_valid      = auto_in_aw_valid;
  assign auto_out_w_valid       = auto_in_w_valid;
  assign auto_out_ar_valid      = auto_in_ar_valid;
  assign auto_out_b_ready       = auto_in_b_ready;
  assign auto_out_r_ready       = auto_in_r_ready;
  // AW 载荷 (除 id 外) 正向直通
  assign auto_out_aw_bits_addr  = auto_in_aw_bits_addr;
  assign auto_out_aw_bits_len   = auto_in_aw_bits_len;
  assign auto_out_aw_bits_size  = auto_in_aw_bits_size;
  assign auto_out_aw_bits_burst = auto_in_aw_bits_burst;
  assign auto_out_aw_bits_cache = auto_in_aw_bits_cache;
  assign auto_out_aw_bits_prot  = auto_in_aw_bits_prot;
  assign auto_out_aw_bits_qos   = auto_in_aw_bits_qos;
  // W 载荷正向直通
  assign auto_out_w_bits_data   = auto_in_w_bits_data;
  assign auto_out_w_bits_strb   = auto_in_w_bits_strb;
  assign auto_out_w_bits_last   = auto_in_w_bits_last;
  // AR 载荷 (除 id 外) 正向直通
  assign auto_out_ar_bits_addr  = auto_in_ar_bits_addr;
  assign auto_out_ar_bits_len   = auto_in_ar_bits_len;
  assign auto_out_ar_bits_size  = auto_in_ar_bits_size;
  assign auto_out_ar_bits_burst = auto_in_ar_bits_burst;
  assign auto_out_ar_bits_cache = auto_in_ar_bits_cache;
  assign auto_out_ar_bits_prot  = auto_in_ar_bits_prot;
  assign auto_out_ar_bits_qos   = auto_in_ar_bits_qos;
  // R 载荷 (除 id 外) 反向直通
  assign auto_in_r_bits_data    = auto_out_r_bits_data;
  assign auto_in_r_bits_resp    = auto_out_r_bits_resp;
  assign auto_in_r_bits_last    = auto_out_r_bits_last;
"""

BODY1 = """\
  // ---- 上行 (in→out): 下游从口仅支持 2 位 ID ----
  //  把 7 位主口 ID 拆成 {高 5 位, 低 2 位}: 低 2 位作下游 ID; 高 5 位塞进 AXI user-echo 字段
  //  echo.extra_id 随 AW/AR 携带到从口 (从口原样回传, 不解析), 供响应时还原主口 ID。
  assign auto_out_aw_bits_id            = auto_in_aw_bits_id[1:0];
  assign auto_out_aw_bits_echo_extra_id = auto_in_aw_bits_id[6:2];
  assign auto_out_ar_bits_id            = auto_in_ar_bits_id[1:0];
  assign auto_out_ar_bits_echo_extra_id = auto_in_ar_bits_id[6:2];
  // ---- 下行 (out→in): 从 echo.extra_id 取回高 5 位, 与 2 位下游 ID 拼回 7 位主口 ID ----
  assign auto_in_b_bits_id   = {auto_out_b_bits_echo_extra_id, auto_out_b_bits_id};
  assign auto_in_r_bits_id   = {auto_out_r_bits_echo_extra_id, auto_out_r_bits_id};

  // ---- 其余字段全直通 ----
  // 握手
  assign auto_in_aw_ready    = auto_out_aw_ready;
  assign auto_in_w_ready     = auto_out_w_ready;
  assign auto_in_ar_ready    = auto_out_ar_ready;
  assign auto_in_b_valid     = auto_out_b_valid;
  assign auto_in_r_valid     = auto_out_r_valid;
  assign auto_out_aw_valid   = auto_in_aw_valid;
  assign auto_out_w_valid    = auto_in_w_valid;
  assign auto_out_ar_valid   = auto_in_ar_valid;
  assign auto_out_b_ready    = auto_in_b_ready;
  assign auto_out_r_ready    = auto_in_r_ready;
  // B 载荷 (resp) 反向直通
  assign auto_in_b_bits_resp = auto_out_b_bits_resp;
  // AW 载荷 (除 id/echo 外) 正向直通
  assign auto_out_aw_bits_addr  = auto_in_aw_bits_addr;
  assign auto_out_aw_bits_len   = auto_in_aw_bits_len;
  assign auto_out_aw_bits_size  = auto_in_aw_bits_size;
  assign auto_out_aw_bits_burst = auto_in_aw_bits_burst;
  assign auto_out_aw_bits_lock  = auto_in_aw_bits_lock;
  assign auto_out_aw_bits_cache = auto_in_aw_bits_cache;
  assign auto_out_aw_bits_prot  = auto_in_aw_bits_prot;
  assign auto_out_aw_bits_qos   = auto_in_aw_bits_qos;
  // W 载荷正向直通
  assign auto_out_w_bits_data   = auto_in_w_bits_data;
  assign auto_out_w_bits_strb   = auto_in_w_bits_strb;
  assign auto_out_w_bits_last   = auto_in_w_bits_last;
  // AR 载荷 (除 id/echo 外) 正向直通
  assign auto_out_ar_bits_addr  = auto_in_ar_bits_addr;
  assign auto_out_ar_bits_len   = auto_in_ar_bits_len;
  assign auto_out_ar_bits_size  = auto_in_ar_bits_size;
  assign auto_out_ar_bits_burst = auto_in_ar_bits_burst;
  assign auto_out_ar_bits_lock  = auto_in_ar_bits_lock;
  assign auto_out_ar_bits_cache = auto_in_ar_bits_cache;
  assign auto_out_ar_bits_prot  = auto_in_ar_bits_prot;
  assign auto_out_ar_bits_qos   = auto_in_ar_bits_qos;
  // R 载荷 (除 id 外) 反向直通
  assign auto_in_r_bits_data    = auto_out_r_bits_data;
  assign auto_in_r_bits_resp    = auto_out_r_bits_resp;
  assign auto_in_r_bits_last    = auto_out_r_bits_last;
"""

VARIANTS = [
    ("AXI4IdIndexer",   "xs_AXI4IdIndexer_core",   "AXI4IdIndexer_xs",   BODY0),
    ("AXI4IdIndexer_1", "xs_AXI4IdIndexer_1_core", "AXI4IdIndexer_1_xs", BODY1),
]

CORE_HEADER_DOC = """\
// =============================================================================
//  AXI4IdIndexer / AXI4IdIndexer_1 —— AXI4 ID 位宽适配器 (可读重写核)
// -----------------------------------------------------------------------------
//  源自 rocket-chip AXI4IdIndexer (src/main/scala/amba/axi4/IdIndexer.scala)。两者均为
//  纯组合直通适配器 (无时钟/寄存器/子模块), 只对 AW/AR/B/R 的 ID 字段做适配, 其余字段直通:
//
//    xs_AXI4IdIndexer_core   : 上游 7 位 ID → 下游 14 位 ID, 上行零扩展 {7'h0,id}; 下行截 id[6:0]。
//    xs_AXI4IdIndexer_1_core : 下游仅 2 位 ID; 上行 out.id=id[1:0] + echo.extra_id=id[6:2] 随路;
//                              下行 in.id={echo.extra_id, out.id} 还原 7 位。
//
//  端口表据 golden 同名模块忠实生成 (位宽/顺序一致), 赋值体为手写可读逻辑。
//  验证: 各变体 golden vs 可读变体 双例化逐拍比对全部输出; FM 证等价。
// =============================================================================
"""


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


def gen_wrapper(top, core, ports):
    return ("// 自动生成：scripts/gen_axi4idindexer.py —— 勿手改\n"
            + header(top, ports) + inst(core, "u_core", ports) + "\nendmodule\n")


def gen_variant(variant, core, ports):
    return ("// 自动生成：scripts/gen_axi4idindexer.py —— 勿手改\n"
            + header(variant, ports) + inst(core, "u_core", ports) + "\nendmodule\n")


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


def gen_tb(top, variant, ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_axi4idindexer.py —— 勿手改",
        f"// {top} 双例化逐拍比对: golden {top} vs 可读 {variant} (纯组合 ID 适配器)。",
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
    conn = [n for _, _, n in ports]
    for i, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"g_{n}"
        L.append(f"    .{n}({sig}){',' if i + 1 < len(conn) else ''}")
    L += ["  );", "", f"  {variant} u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = n if d == "input" else f"i_{n}"
        L.append(f"    .{n}({sig}){',' if i + 1 < len(conn) else ''}")
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


def gen_makefile(top, variant):
    return f"""# 自动生成：scripts/gen_axi4idindexer.py —— 勿手改
MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 (两变体同在 AXI4IdIndexer.sv); 纯组合, 无黑盒依赖。
RTL_SRCS = $(RTL_DIR)/uncore/AXI4IdIndexer.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/{top}_wrapper.sv
FM_VARIANTS = {top}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    # 1) 生成两核合一的核文件 (头据 golden 忠实, 体为手写)
    core_parts = [CORE_HEADER_DOC]
    for top, core, _variant, body in VARIANTS:
        ports = parse_ports(GOLDEN / f"{top}.sv", top)
        core_parts.append(f"module {core}(\n" + ",\n".join(decl(*p) for p in ports)
                          + "\n);\n\n" + body + "\nendmodule\n")
    CORE_FILE.write_text("\n".join(core_parts))

    # 2) 每变体: wrapper + 变体 + tb + Makefile (各自独立 UT 目录)
    for top, core, variant, _body in VARIANTS:
        ports = parse_ports(GOLDEN / f"{top}.sv", top)
        (RTL / f"{top}_wrapper.sv").write_text(gen_wrapper(top, core, ports))
        ut = ROOT / "verif" / "ut" / top
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(gen_variant(variant, core, ports))
        (ut / "tb.sv").write_text(gen_tb(top, variant, ports))
        (ut / "Makefile").write_text(gen_makefile(top, variant))
    print("generated AXI4IdIndexer + AXI4IdIndexer_1 core / wrappers / UTs / Makefiles")


if __name__ == "__main__":
    main()
