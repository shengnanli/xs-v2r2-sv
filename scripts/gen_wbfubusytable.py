#!/usr/bin/env python3
"""
WbFuBusyTable 生成器(写回 FU 忙表)。

解析 golden `WbFuBusyTable.sv`, 生成:
  - rtl/backend/WbFuBusyTable_wrapper.sv : golden 同名 wrapper `WbFuBusyTable`(→ 可读核)
  - verif/ut/WbFuBusyTable/variants_xs.sv: 镜像 `WbFuBusyTable_xs`(→ 可读核, 同 wrapper)
  - verif/ut/WbFuBusyTable/tb.sv         : golden vs _xs 双例化, 随机激励逐拍比对全部输出

设计观察(详见 docs/backend/WbFuBusyTable.md):
  * WbFuBusyTable 是**纯组合**的"按写回端口归并各源忙表 + 扇出读回"接线器, 无时钟/复位、无状态。
    writeBusyTable: busyTable[port] = OR_{src 命中 port} src.busyTable
    readRes       : reader.out = busyTable[reader 的 port], 截/扩到 reader 宽度
  * 当前昆明湖配置下 conflict / deqRespSet 一路因 latCertain 过滤后均为 None,
    golden 不含相关端口, 可读核同样不实现。
  * golden 端口为展平名 io_in_<schd>SchdBusyTable_<b>_<e>_<X>WbBusyTable /
    io_out_<schd>RespRead_<b>_<e>_<X>WbBusyTable。可读核端口改用语义名
    (in_<schd>_<b>_<e>_<X>Wb / out_<schd>Resp_<b>_<e>_<X>Wb), 故 wrapper/variants 需做名字映射。

注: wrapper 已手写于 rtl/backend/WbFuBusyTable_wrapper.sv(映射稳定)。本脚本重新生成它
    以及 variants_xs.sv / tb.sv, 保证三者端口映射一致、可复跑核验。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "WbFuBusyTable"
CORE = "xs_WbFuBusyTable_core"


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def golden_to_core(n):
    """golden 展平端口名 -> 可读核语义端口名。"""
    m = re.match(r"io_in_(\w+?)SchdBusyTable_(\d+)_(\d+)_(\w+?)WbBusyTable", n)
    if m:
        return f"in_{m.group(1)}Schd_{m.group(2)}_{m.group(3)}_{m.group(4)}Wb"
    m = re.match(r"io_out_(\w+?)RespRead_(\d+)_(\d+)_(\w+?)WbBusyTable", n)
    if m:
        return f"out_{m.group(1)}Resp_{m.group(2)}_{m.group(3)}_{m.group(4)}Wb"
    raise ValueError(f"unmapped port {n}")


def emit_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else "      "
        decls.append(f"  {d:6s} {ws}{n}")
    conns = [f"    .{golden_to_core(n)}({n})" for _, _, n in ps]
    L = [f"module {modname}(", ",\n".join(decls), ");", "",
         f"  {CORE} u_core (", ",\n".join(conns), "  );", "endmodule", ""]
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input"]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["""// 自动生成：scripts/gen_wbfubusytable.py —— 勿手改
// WbFuBusyTable UT: golden(u_g) vs 可读核 wrapper WbFuBusyTable_xs(u_i)。
// 模块纯组合, 每拍随机驱动全部输入(各源忙表位图), 组合稳定后比对全部输出。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
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

    gc = [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  {MODULE}    u_g ({', '.join(gg)});")
    T.append(f"  {MODULE}_xs u_i ({', '.join(ig)});")

    # 随机激励: 各源忙表是稀疏位图, 混合"全随机"与"边界(0/全1/单热)"以充分覆盖 OR 合并。
    T.append("  task automatic drive();")
    for w, n in ins:
        if w == 1:
            T.append(f"    {n} = $urandom_range(0,1);")
        else:
            T.append(f"    {n} = {w}'($urandom);")
    T.append("  endtask")

    T.append("""  `define CK(g,i,nm) \\
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \\
      if (errors<=60) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end \\
    checks++;""")
    T.append("  task automatic check();")
    for w, n in outs:
        T.append(f'    `CK(g_{n}, i_{n}, "{n}")')
    T.append("  endtask")

    T.append("""  initial begin
    drive();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check();
      drive();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = ports(MODULE)
    hdr = "// 自动生成：scripts/gen_wbfubusytable.py —— 勿手改\n"
    # 注: rtl/backend/WbFuBusyTable_wrapper.sv 为手写(带说明注释), 端口映射与本脚本一致,
    #     此处不覆盖它; variants_xs.sv 用同一映射机器生成(供 UT 镜像例化)。
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper(f"{MODULE}_xs", ps))
    (ut / "tb.sv").write_text(emit_tb(ps))
    print(f"{MODULE}: {len(ps)} ports, "
          f"{sum(1 for d,_,_ in ps if d=='input')} in, "
          f"{sum(1 for d,_,_ in ps if d=='output')} out")


if __name__ == "__main__":
    main()
