#!/usr/bin/env python3
"""
DivUnit：解析 golden 端口生成 wrapper(golden 同名 DivUnit)、_xs 镜像、随机比对 tb。

DivUnit 的 golden 端口已是逐字段扁平形式（io_*），与可读核 xs_DivUnit_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。

核内部例化叶子子模块 SRT16DividerDataModule（基-16 SRT 迭代除法器），golden 也例化
同一模块；UT 两侧共用同一份 golden SRT16DividerDataModule.sv（黑盒），FM 时作为
两侧共享黑盒。

设计意图来自 src/main/scala/xiangshan/backend/fu/wrapper/DivUnit.scala（多周期迭代）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/backend/DivUnit.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

MODULE = "DivUnit"
CORE = "xs_DivUnit_core"


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
    hdr = "// 自动生成：scripts/gen_divunit.py —— 勿手改\n"

    (XSSV / f"rtl/backend/{MODULE}_wrapper.sv").write_text(hdr + emit(MODULE, ps))
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit(f"{MODULE}_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_divunit.py —— 勿手改
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
    # DivUnit 是多周期迭代除法，有真正的 in/out 握手与 flush。激励要点：
    #   · io_in_valid 常发以喂满除法器，但除法器忙时会拉低 in_ready（背压）；
    #   · io_out_ready 随机以制造输出背压，覆盖结果在除法器口停留；
    #   · io_flush_valid 偶发以覆盖 kill_w / kill_r 两条冲刷路径（迭代中冲刷）；
    #     flush 的 robIdx 与输入 robIdx 共用一个小空间(0..15)，提高命中冲刷概率；
    #   · fuOpType 限定在合法除法编码集合，覆盖各 opType（含 W / 取余 / 有无符号）。
    in_names = {n for _, n in ins}

    def rnd(w, n):
        if n == "io_in_valid":
            return "($urandom_range(0,3)!=0)"   # 常发
        if n == "io_out_ready":
            return "$urandom_range(0,1)"        # 随机背压
        if n == "io_flush_valid":
            return "($urandom_range(0,7)==0)"   # 偶发冲刷
        if n == "io_flush_bits_level":
            return "$urandom_range(0,1)"
        if n == "io_in_bits_ctrl_fuOpType":
            return "divops[$urandom_range(0,7)]"
        # robIdx 压到小空间提高冲刷命中
        if n in ("io_in_bits_ctrl_robIdx_value", "io_flush_bits_robIdx_value"):
            return "8'($urandom_range(0,15))"
        if n in ("io_in_bits_ctrl_robIdx_flag", "io_flush_bits_robIdx_flag"):
            return "$urandom_range(0,1)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    T.append("  // 合法除法 fuOpType（10xxx）：div=10000 rem=10001 divu=10010 remu=10011")
    T.append("  //   divw=10100 remw=10101 divuw=10110 remuw=10111")
    T.append("  logic [8:0] divops [0:7] = '{9'h10, 9'h11, 9'h12, 9'h13, 9'h14, 9'h15, 9'h16, 9'h17};")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in ("io_in_valid", "io_flush_valid", "io_out_ready"):
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
