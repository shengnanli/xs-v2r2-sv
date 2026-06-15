#!/usr/bin/env python3
"""
Composer 顶层（BPU 预测器组合器）生成器。

解析 golden `Composer.sv`，生成：
  - rtl/frontend/Composer_wrapper.sv : golden 同名 wrapper `Composer`
  - verif/ut/Composer/variants_xs.sv : 镜像 `Composer_xs`
  - verif/ut/Composer/tb.sv          : golden vs _xs 双例化，随机激励逐拍比对全部输出

设计观察（详见 docs/frontend/Composer.md）：
  * Composer 本质是“预测器流水线的接线工”：把 uFTB/FTB/TAGE-SC/ITTAGE/RAS 5 个预测器
    与 4 个 DelayN（ctrl 使能延迟对齐）按**菊花链**串起来，
    覆盖式预测的合成发生在各预测器**内部**（每个预测器吃上一级的 resp_in 再覆盖），
    而非 Composer 自身的组合逻辑里。
  * Composer 自身真正驱动输出的逻辑只有 9 条 assign：
      - io_out_last_stage_meta : 5 个预测器 meta 段拼接
      - io_s1_ready            : tage & ftb & ittage 的 s1_ready 相与
      - io_perf_0..6_value     : uftb/tage/ftb 的 perf 计数经 2 级寄存器对齐
    这部分被抽到**可读核** xs_Composer_core（rtl/frontend/Composer.sv，手写）。
  * golden 里还有一大坨 s1/s2/s3_pc_dup 分段寄存器（debug PC 跟踪）——在本 build 里**结构性死逻辑**
    （只喂 s2_pc_addr/s3_pc_addr 这两个谁都不用的 wire）。可读核里以注释保留说明，不再例化。
  * s2_pc/s3_pc、各级 full_pred 等输出由 RAS（链尾）/uFTB（链首 s1）实例直接驱动顶层端口。

wrapper 接线策略（保证 FM 签名分析可判 + 黑盒引脚对齐）：
  - 5 个预测器 + 4 个 DelayN 的例化连接**逐字照搬 golden**（这些是黑盒子模块引脚，
    名字/连接必须与 golden 一致，FM 才能把两侧黑盒配对）。
  - 预测器之间互连的内部 net（_ftb_io_*/_uftb_io_* …）按 golden 原名声明为内部 wire。
  - 可读核 u_core 吃 perf/meta/ready 的源 net，吐 9 条 assign 输出。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
SRC = (GOLDEN / "Composer.sv").read_text()

# ----------------------------------------------------------------------------
# 解析顶层端口
# ----------------------------------------------------------------------------
def parse_ports(text, modname):
    hdr = re.search(rf"^module {re.escape(modname)}\((.*?)\n\);", text, re.S | re.M).group(1)
    res = []
    for line in hdr.splitlines():
        m = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if m:
            res.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return res

PORTS = parse_ports(SRC, "Composer")

def width_str(w):
    return f"[{w-1}:0] " if w > 1 else ""

# ----------------------------------------------------------------------------
# 解析内部 wire/reg 声明（截到第一个 always 之前）
# 分类：bore(顶层端口已含，跳过) / deadpc(死 debug pc, 跳过) / perfreg(挪到核) /
#       prednet(预测器互连 net, 保留) / _GEN(reset_vector, 挪到核)
# ----------------------------------------------------------------------------
DECL_REGION = SRC[:SRC.index("  always @")]

def parse_decls():
    out = []  # (kind, width, name)
    for m in re.finditer(r"^  (wire|reg)\s+(?:\[(\d+):0\])?\s*(\w+)\s*(?:=|;)", DECL_REGION, re.M):
        kind, hi, name = m.group(1), m.group(2), m.group(3)
        w = int(hi) + 1 if hi else 1
        out.append((kind, w, name))
    return out

DECLS = parse_decls()

def decl_category(name):
    if "bore" in name:
        return "bore"
    if name.startswith(("s1_pc_dup", "s2_pc_dup", "s3_pc_dup")):
        return "deadpc"
    # Composer 自身 perf 2 级流水寄存器（挪到可读核），名形如 io_perf_*_REG / REG / REG_1。
    # 注意：预测器侧的 perf 源 net（_tage_io_perf_0_value 等）不在此列，归 prednet。
    if name.startswith("io_perf_") or name in ("REG", "REG_1"):
        return "perfreg"
    if name == "_GEN":
        return "gen"
    if re.match(r"_(ftb|uftb|tage|ras|ittage)_io", name):
        return "prednet"
    return "other"

# 预测器互连 net（需在 wrapper 内声明）
PREDNETS = [(w, n) for k, w, n in DECLS if decl_category(n) == "prednet"]

# ----------------------------------------------------------------------------
# 解析 5 预测器 + 4 DelayN 实例（逐字照搬连接）
# ----------------------------------------------------------------------------
def parse_instances():
    insts = []
    for m in re.finditer(r"^  ([A-Z]\w*) (\w+) \(\n(.*?)^  \);", SRC, re.S | re.M):
        mod, inst, body = m.group(1), m.group(2), m.group(3)
        insts.append((mod, inst, body.rstrip()))
    return insts

INSTANCES = parse_instances()

# ----------------------------------------------------------------------------
# 核（xs_Composer_core）的接口：输入 perf/meta/ready 源 net + 时钟复位，
# 输出 9 条 assign。源 net 名直接复用 golden 内部 net 名。
# ----------------------------------------------------------------------------
PERF_SRC = [  # (out_index, source_net)
    (0, "_uftb_io_perf_0_value"), (1, "_uftb_io_perf_1_value"),
    (2, "_tage_io_perf_0_value"), (3, "_tage_io_perf_1_value"),
    (4, "_tage_io_perf_2_value"),
    (5, "_ftb_io_perf_0_value"),  (6, "_ftb_io_perf_1_value"),
]
# (源 net, 有效低位段宽度) —— 与 golden meta 拼接所取的位宽一致，
# wrapper 只把 net[w-1:0] 送进核，未读高位不跨边界（与 golden 行为一致，FM 干净）。
META_SRC = [
    ("_uftb_io_out_last_stage_meta", 6),
    ("_tage_io_out_last_stage_meta", 144),
    ("_ftb_io_out_last_stage_meta", 67),
    ("_ittage_io_out_last_stage_meta", 182),
    ("_ras_io_out_last_stage_meta", 10),
]
READY_SRC = ["_tage_io_s1_ready", "_ftb_io_s1_ready", "_ittage_io_s1_ready"]


def emit_wrapper(modname):
    L = []
    L.append(f"// 自动生成：scripts/gen_composer.py —— 勿手改")
    L.append(f"// golden 同名 wrapper：例化 5 预测器 + 4 DelayN（逐字照搬 golden 连接）+ 可读核 xs_Composer_core。")
    L.append(f"module {modname}(")
    decls = [f"  {d:6s} {width_str(w)}{n}" for d, w, n in PORTS]
    L.append(",\n".join(decls))
    L.append(");")
    L.append("")
    # 预测器互连内部 net
    L.append("  // ---- 预测器之间 / 预测器→输出 的互连 net（沿用 golden 原名，便于黑盒引脚对齐）----")
    for w, n in PREDNETS:
        L.append(f"  wire {width_str(w)}{n};")
    L.append("")
    # 实例（逐字照搬）
    for mod, inst, body in INSTANCES:
        L.append(f"  {mod} {inst} (")
        L.append(body)
        L.append("  );")
        L.append("")
    # 可读核
    L.append("  // ---- 可读核：perf 2 级流水 / meta 拼接 / s1_ready 相与 ----")
    L.append("  xs_Composer_core u_core (")
    cc = [".clock(clock)", ".reset(reset)"]
    for idx, src in PERF_SRC:
        cc.append(f".perf_in_{idx}({src})")
    for i, (src, w) in enumerate(META_SRC):
        cc.append(f".meta_in_{i}({src}[{w-1}:0])")
    for i, src in enumerate(READY_SRC):
        cc.append(f".ready_in_{i}({src})")
    for idx, _ in PERF_SRC:
        cc.append(f".io_perf_{idx}_value(io_perf_{idx}_value)")
    cc.append(".io_out_last_stage_meta(io_out_last_stage_meta)")
    cc.append(".io_s1_ready(io_s1_ready)")
    L.append("    " + ",\n    ".join(cc))
    L.append("  );")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_tb():
    ins = [(w, n) for d, w, n in PORTS if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in PORTS if d == "output"]
    T = ["""// 自动生成：scripts/gen_composer.py —— 勿手改
// Composer UT：golden Composer vs 手写 Composer_xs 双例化（两侧共用同名 golden 预测器子模块），
// 随机 req/redirect/update/ctrl 激励，逐拍比对全部输出。差异只可能来自 Composer 自身逻辑/接线。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 64;   // 子模块内部 SRAM/寄存器清零所需拍数（大于子模块清零拍数）
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int cyc = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        T.append(f"  logic {width_str(w)}{n};")
    for w, n in outs:
        T.append(f"  wire {width_str(w)}g_{n};")
        T.append(f"  wire {width_str(w)}i_{n};")
    common = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = common + [f".{n}(g_{n})" for _, n in outs]
    ig = common + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  Composer    u_g ({', '.join(gg)});")
    T.append(f"  Composer_xs u_i ({', '.join(ig)});")
    T.append("")

    fire_sigs = [f"io_s{s}_fire_{d}" for s in range(3) for d in range(4)]
    redir_sigs = ["io_s3_redirect_0", "io_s3_redirect_1", "io_s3_redirect_2", "io_s3_redirect_3",
                  "io_redirect_valid", "io_redirectFromIFU"]
    # 低位压缩，提高预测器命中率（与各子模块 UT 同策略）
    pc_sigs = [n for _, n in ins if re.search(r"(s0_pc_\d|update_bits_pc|full_target)$", n)]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_update_valid <= 1'b0;")
    for s in fire_sigs:
        T.append(f"      {s} <= 1'b0;")
    for s in redir_sigs:
        if any(s == n for _, n in ins):
            T.append(f"      {s} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n in fire_sigs:
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n == "io_update_valid":
            T.append(f"      {n} <= ($urandom_range(0,3)==0);")
        elif n in redir_sigs:
            T.append(f"      {n} <= ($urandom_range(0,7)==0);")
        elif n == "io_reset_vector":
            T.append(f"      {n} <= {w}'h80000000;")  # 复位向量固定，贴近真实
        elif n in pc_sigs:
            T.append(f"      {n} <= {{{w-13}'($urandom), 12'($urandom_range(0,255)), 1'b0}};")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()'] * rep)}}});")
    T.append("    end")
    T.append("  end")
    T.append("")
    T.append("  // 比对：跳过 golden 为 X 的位（子模块内层 SRAM 在 +SYNTHESIS 下初值 X）")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    cyc++;")
    T.append("    #4;")
    T.append("    if (cyc > WARMUP) begin")
    T.append("      checks++;")
    for w, n in outs:
        T.append(f"      if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"        if (errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("    end")
    T.append("  end")
    T.append("")
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


def main():
    (XSSV / "rtl/frontend/Composer_wrapper.sv").write_text(emit_wrapper("Composer"))
    ut = XSSV / "verif/ut/Composer"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(emit_wrapper("Composer_xs"))
    (ut / "tb.sv").write_text(emit_tb())
    ni = sum(1 for d, _, _ in PORTS if d == "input")
    no = sum(1 for d, _, _ in PORTS if d == "output")
    print(f"Composer: {ni} inputs, {no} outputs, {len(PREDNETS)} internal nets, {len(INSTANCES)} instances")


if __name__ == "__main__":
    main()
