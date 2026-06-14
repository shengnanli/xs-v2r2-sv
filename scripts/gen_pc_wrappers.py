#!/usr/bin/env python3
"""
为 NewPipelineConnectPipe 系列生成：
  1) rtl/common/PipelineConnect_variants.sv     变体包装（golden 同名，FM/ST 用）
  2) verif/ut/PipelineConnect/variants_xs.sv     _xs 后缀镜像（UT 用）
  3) verif/ut/PipelineConnect/tb.sv              全变体 golden vs _xs 随机比对 tb

每个变体的 payload 是一组 io_in_bits_<field> / io_out_bits_<field> 端口（in/out 同名
一一对应）。包装层把 in 字段按声明序拼接成 xs_PipelineConnect 的 io_in_bits 总线，
再把 io_out_bits 拆回各 out 字段。两类变体：
  - 有 ready 端口：完整握手，io_in_ready/io_out_ready 直连；
  - 无 ready 端口（下游 out_ready 恒 1 被 firtool DCE）：包装层 io_out_ready 接 1，
    io_in_ready 悬空。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"


def variants():
    return sorted((p.stem for p in GOLDEN.glob("NewPipelineConnectPipe*.sv")),
                  key=lambda s: (len(s), s))


def parse_ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    assert m, name
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            d, w, n = pm.group(1), pm.group(2), pm.group(3)
            ports.append((d, int(w) + 1 if w else 1, n))
    return ports


def bits_fields(ports, io):
    """返回 [(width, name)]，按声明序"""
    return [(w, n) for d, w, n in ports if n.startswith(f"io_{io}_bits")]


def field_offsets(ports):
    """返回 [(field_suffix, lo, w)]：各 in_bits 字段在打包 data_reg 中的位区间。
    打包 in_bus={in_f[0],...,in_f[n-1]}，in_f[0] 为 MSB；data_reg[j]=in_bus[j]。
    field_suffix 为 io_in_bits_ 之后的部分（即 golden 寄存器名 data_<suffix>）。"""
    in_f = bits_fields(ports, "in")
    width = sum(w for w, _ in in_f)
    res, hi = [], width - 1
    for w, n in in_f:
        suf = n[len("io_in_bits_"):]
        res.append((suf, hi - w + 1, w))
        hi -= w
    return res


def gen_wrapper(name, ports, suffix=""):
    in_f = bits_fields(ports, "in")
    out_f = bits_fields(ports, "out")
    width = sum(w for w, _ in in_f)
    assert sum(w for w, _ in out_f) == width, f"{name}: in/out width mismatch"
    has_ready = any(n == "io_in_ready" for _, _, n in ports)

    decls = []
    for d, w, n in ports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    body = [f"module {name}{suffix}(", ",\n".join(decls) + "\n);"]

    # in 字段拼接（首字段 MSB；只需 wrapper 内自洽）
    in_bus = "{" + ", ".join(n for _, n in in_f) + "}" if len(in_f) > 1 else in_f[0][1]
    body.append(f"  wire [{width-1}:0] out_bus;")
    # out 总线按相同顺序拆回各 out 字段
    hi = width - 1
    for w, n in out_f:
        sl = f"[{hi}:{hi-w+1}]" if width != w else ""
        body.append(f"  assign {n} = out_bus{sl};")
        hi -= w

    # isFlush / rightOutFire 可能被实例绑常量后 firtool DCE（如 isFlush 恒 0）：
    # 端口不存在时接对应常量，避免引用未声明信号。
    has_flush = any(n == "io_isFlush" for _, _, n in ports)
    has_rof = any(n == "io_rightOutFire" for _, _, n in ports)
    flush_c = "io_isFlush" if has_flush else "1'b0"
    rof_c = "io_rightOutFire" if has_rof else "1'b0"

    conns = [".clock(clock)", ".reset(reset)",
             f".io_in_valid(io_in_valid)", f".io_in_bits({in_bus})",
             ".io_out_valid(io_out_valid)", ".io_out_bits(out_bus)",
             f".io_rightOutFire({rof_c})", f".io_isFlush({flush_c})"]
    if has_ready:
        conns.insert(2, ".io_in_ready(io_in_ready)")
        conns.insert(5, ".io_out_ready(io_out_ready)")
    else:
        conns.insert(2, ".io_in_ready(/* 上游未用，golden 已 DCE */)")
        conns.insert(5, ".io_out_ready(1'b1)")

    body.append(f"  xs_PipelineConnect #(.DATA_WIDTH({width})) u_core (")
    body.append("    " + ",\n    ".join(conns))
    body.append("  );")
    body.append("endmodule\n")
    return "\n".join(body)


def gen_tb(vs):
    L = ["""// 自动生成：scripts/gen_pc_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 50000;
  int unsigned WARMUP  = 2000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;
"""]
    for name, ports in vs:
        pre = f"v{name}"
        has_ready = any(n == "io_in_ready" for _, _, n in ports)
        ins = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
        outs = [(w, n) for d, w, n in ports if d == "output"]
        for w, n in ins:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  logic {ws}{pre}_{n};")
        for w, n in outs:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}{pre}_g_{n};")
            L.append(f"  wire {ws}{pre}_i_{n};")
        gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({pre}_{n})" for _, n in ins]
        ic = list(gc)
        gc += [f".{n}({pre}_g_{n})" for _, n in outs]
        ic += [f".{n}({pre}_i_{n})" for _, n in outs]
        L.append(f"  {name} u_g_{name} ({', '.join(gc)});")
        L.append(f"  {name}_xs u_i_{name} ({', '.join(ic)});")
        # 激励：控制信号随机占空，payload 全随机
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w, n in ins:
            if re.match(r"io_(in_valid|out_ready|rightOutFire|isFlush)$", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
        L.append("    end else begin")
        for w, n in ins:
            if n in ("io_in_valid", "io_out_ready", "io_rightOutFire"):
                L.append(f"      {pre}_{n} <= ($urandom_range(0,3) != 0);")  # ~75%
            elif n == "io_isFlush":
                L.append(f"      {pre}_{n} <= ($urandom_range(0,15) == 0);")  # ~6%
            elif w <= 32:
                L.append(f"      {pre}_{n} <= {w}'($urandom);")
            else:
                rep = (w + 31) // 32
                rnd = "{" + ", ".join(["$urandom()"] * rep) + "}"
                L.append(f"      {pre}_{n} <= {w}'({rnd});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if (!rst && cycle > WARMUP) begin")
        L.append("    #4; checks++;")
        for w, n in outs:
            L.append(f"    if ({pre}_g_{n} !== {pre}_i_{n}) begin errors++;")
            L.append(f"      $display(\"[%0t] {name}.{n} mismatch g=%h i=%h\", $time, {pre}_g_{n}, {pre}_i_{n}); end")
        L.append("  end")
        L.append("")
    L.append("""  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 50000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    hdr = "// 自动生成：scripts/gen_pc_wrappers.py —— 勿手改\n"
    vs = [(n, parse_ports(n)) for n in variants()]
    (XSSV / "rtl/common/PipelineConnect_variants.sv").write_text(
        hdr + "\n".join(gen_wrapper(n, p) for n, p in vs))
    ut = XSSV / "verif/ut/PipelineConnect"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(
        hdr + "\n".join(gen_wrapper(n, p, "_xs") for n, p in vs))
    (ut / "tb.sv").write_text(gen_tb(vs))
    # FM 字段映射：golden 逐字段寄存器 data_<suffix> → 扁平 u_core/data_reg[lo..]
    fmdir = ut / "fm_map"
    fmdir.mkdir(exist_ok=True)
    for n, p in vs:
        lines = [f"{suf} {lo} {w}" for suf, lo, w in field_offsets(p)]
        (fmdir / f"{n}.txt").write_text("\n".join(lines) + "\n")
    nr = sum(1 for n, p in vs if any(x[2] == "io_in_ready" for x in p))
    print(f"generated {len(vs)} variants ({nr} with ready, {len(vs)-nr} without)")


if __name__ == "__main__":
    main()
