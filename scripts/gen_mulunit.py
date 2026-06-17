#!/usr/bin/env python3
"""
MulUnit：解析 golden 端口生成 wrapper(golden 同名 MulUnit)、_xs 镜像、随机比对 tb。

MulUnit 的 golden 端口已是逐字段扁平形式（io_*），与可读核 xs_MulUnit_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。

核内部例化叶子子模块 ArrayMulDataModule（2 级流水乘法阵列），golden 也例化同一模块；
UT 两侧共用同一份 golden ArrayMulDataModule.sv（黑盒），FM 时作为两侧共享黑盒。

设计意图来自 src/main/scala/xiangshan/backend/fu/wrapper/MulUnit.scala（latency=2 piped）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/backend/MulUnit.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

MODULE = "MulUnit"
CORE = "xs_MulUnit_core"


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append(f"  {CORE} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports(MODULE)
    hdr = "// 自动生成：scripts/gen_mulunit.py —— 勿手改\n"

    (XSSV / f"rtl/backend/{MODULE}_wrapper.sv").write_text(hdr + emit(MODULE, ps))
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit(f"{MODULE}_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_mulunit.py —— 勿手改
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
    T.append(f"  {MODULE}    u_g ({', '.join(gg)});")
    T.append(f"  {MODULE}_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # MulUnit 是 2 拍定长流水。控制/数据流水 (validPipe/ctrlPipe) 在真实 SoC 由发射队列
    # 预打拍后送入；UT 里独立随机各 validPipe 位以覆盖“某些级有效/某些级空泡”的组合，
    # 并背靠背高频发射以覆盖流水满载。fuOpType 限定在合法乘法编码集合，覆盖各 opType。
    in_names = {n for _, n in ins}

    def rnd(w, n):
        if n == "io_in_valid":
            return "$urandom_range(0,1)"
        if n.startswith("io_in_bits_validPipe_"):
            return "$urandom_range(0,1)"
        if n == "io_in_bits_ctrl_fuOpType":
            # 合法乘法 fuOpType：mul/mulh/mulhsu/mulhu/mulw/mulw7
            return "mulops[$urandom_range(0,5)]"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    T.append("  // 合法乘法 fuOpType：mul=00000 mulh=00001 mulhsu=00010 mulhu=00011 mulw=00100 mulw7=01100")
    T.append("  logic [8:0] mulops [0:5] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h04, 9'h0C};")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_in_valid <= 1'b0;")
    for n in ("io_in_bits_validPipe_0", "io_in_bits_validPipe_1", "io_in_bits_validPipe_2"):
        if n in in_names:
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
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
    print(f"{MODULE}: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
