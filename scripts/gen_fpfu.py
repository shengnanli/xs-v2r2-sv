#!/usr/bin/env python3
"""
浮点 FU 通用生成器：解析 golden 端口生成 wrapper(golden 同名) / _xs 镜像 / 随机比对 tb。

支持四个浮点 FU wrapper（计算子模块作 golden 黑盒）：
  FAlu (latency=1, FloatAdder)、FMA (latency=3, FloatFMA)、
  FCVT (latency=2, FPCVT)、FDivSqrt (非定长流水, FloatDivider)。

各 golden 端口已是逐字段扁平形式（io_*），与可读核 xs_<M>_core 端口一一同名，故
wrapper / _xs 只把端口透传给核（u_core）。核内部例化叶子计算子模块（黑盒），golden 也
例化同一模块；UT 两侧共用同一份 golden 子模块，比对只检验 wrapper 的控制/格式/流水/选择。

每个 FU 用 scripts/gen_<m>.py 调本模块的 build(MODULE) 入口。
设计意图来自 src/main/scala/xiangshan/backend/fu/wrapper/<M>.scala。
"""
import re
import sys
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit_wrapper(modname, core, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append(f"  {core} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


# 各 FU 的合法 opType 集合（用于 tb 随机激励覆盖各 opType）
OPTYPES = {
    # FAlu: opcode=fuOpType[4:0]（FloatAdder 内部译码）；取若干典型 VfaddOpCode。
    "FAlu":     ["9'h00", "9'h01", "9'h02", "9'h03", "9'h04", "9'h08",
                 "9'h0C", "9'h0E", "9'h10", "9'h12"],
    # FMA: opcode=fuOpType[3:0]；0=vfmul,其余乘加变体。
    "FMA":      ["9'h00", "9'h01", "9'h02", "9'h03", "9'h08", "9'h09"],
    # FCVT: 典型转换/取整/搬移 opType（含 fround/froundnx/fcvtmod/fmv）。
    "FCVT":     ["9'h00", "9'h01", "9'h02", "9'h03", "9'h08", "9'h09",
                 "9'h0A", "9'h0B", "9'h10", "9'h11", "9'hC0", "9'hC4",
                 "9'h191", "9'h180"],
    # FDivSqrt: bit0=is_sqrt → 用 0(div)/1(sqrt)。
    "FDivSqrt": ["9'h00", "9'h01"],
}


def build(module, core, latency, nonpiped=False):
    ps = ports(module)
    hdr = f"// 自动生成：scripts/gen_{module.lower()}.py —— 勿手改\n"

    (XSSV / f"rtl/backend/{module}_wrapper.sv").write_text(hdr + emit_wrapper(module, core, ps))
    ut = XSSV / f"verif/ut/{module}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper(f"{module}_xs", core, ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    in_names = {n for _, n in ins}

    T = [f"""// 自动生成：scripts/gen_{module.lower()}.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  {module}    u_g ({', '.join(gg)});")
    T.append(f"  {module}_xs u_i ({', '.join(ig)});")

    ops = OPTYPES[module]
    T.append(f"  // 合法 fuOpType 集合（覆盖各 opType）")
    T.append(f"  logic [8:0] fops [0:{len(ops)-1}] = '{{{', '.join(ops)}}};")

    def rnd(w, n):
        if n == "io_in_valid":
            return "$urandom_range(0,1)"
        if n.startswith("io_in_bits_validPipe_"):
            return "$urandom_range(0,1)"
        if n == "io_in_bits_ctrl_fuOpType":
            return f"fops[$urandom_range(0,{len(ops)-1})]"
        if n == "io_in_bits_ctrlPipe_2_fuOpType":   # FCVT 输出端 opType：也用合法集合
            return f"fops[$urandom_range(0,{len(ops)-1})]"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_in_valid <= 1'b0;")
    for n in ("io_in_bits_validPipe_1", "io_in_bits_validPipe_2", "io_in_bits_validPipe_3"):
        if n in in_names:
            T.append(f"      {n} <= 1'b0;")
    if "io_flush_valid" in in_names:
        T.append("      io_flush_valid <= 1'b0;")
    if "io_out_ready" in in_names:
        T.append("      io_out_ready <= 1'b1;")
    T.append("    end else begin")
    for w, n in ins:
        # io_out_ready / io_flush_valid 单独给倾向值，其余随机
        if n == "io_out_ready":
            T.append(f"      {n} <= ($urandom_range(0,3) != 0);  // 多数拍可写回")
        elif n == "io_flush_valid":
            T.append(f"      {n} <= ($urandom_range(0,15) == 0); // 偶发重定向冲刷")
        else:
            T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出（跳过 golden 为 X 的不可达态）
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"{module}: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")
