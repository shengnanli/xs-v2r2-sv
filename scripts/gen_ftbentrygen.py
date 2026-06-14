#!/usr/bin/env python3
"""
为 FTBEntryGen 生成 wrapper（golden 同名）+ _xs 镜像 + UT testbench。

FTBEntryGen 是单实例纯组合模块，端口为扁平 io_* 命名。手写核心
xs_FTBEntryGen_core 复用了完全相同的端口名，故 wrapper 只是逐端口直连
（无数组打包/参数化），结构与 PreDecode 范例一致但更简单。

产物：
  rtl/frontend/FTBEntryGen_wrapper.sv   module FTBEntryGen      (FM impl 顶层)
  verif/ut/FTBEntryGen/variants_xs.sv   module FTBEntryGen_xs   (UT 镜像)
  verif/ut/FTBEntryGen/tb.sv            随机向量驱动，比对 golden vs _xs
"""
import re
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
            res.append((pm.group(1),
                        int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def emit_wrapper(ps, modname):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} logic {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    L.append("  xs_FTBEntryGen_core u_core (")
    L.append(",\n".join(f"    .{n}({n})" for _, _, n in ps))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input"]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    L = ["""// 自动生成：scripts/gen_ftbentrygen.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int errors = 0, checks = 0;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {ws}g_{n};")
        L.append(f"  wire {ws}i_{n};")
    gg = [f".{n}({n})" for _, n in ins] + [f".{n}(g_{n})" for _, n in outs]
    ig = [f".{n}({n})" for _, n in ins] + [f".{n}(i_{n})" for _, n in outs]
    L.append(f"  FTBEntryGen    u_g ({', '.join(gg)});")
    L.append(f"  FTBEntryGen_xs u_i ({', '.join(ig)});")
    L.append("  initial begin")
    L.append("    for (int t = 0; t < NVEC; t++) begin")
    for w, n in ins:
        if w <= 32:
            L.append(f"      {n} = {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            L.append(f"      {n} = {w}'({{{', '.join(['$urandom()']*rep)}}});")
    L.append("      #1; checks++;")
    for w, n in outs:
        L.append(f"      if (g_{n} !== i_{n}) begin errors++;")
        L.append(f"        if (errors<=20) $display(\"vec %0d {n}: g=%h i=%h\", t, g_{n}, i_{n}); end")
    L.append("    end")
    L.append("""    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    ps = ports("FTBEntryGen")
    hdr = "// 自动生成：scripts/gen_ftbentrygen.py —— 勿手改\n"
    (XSSV / "rtl/frontend/FTBEntryGen_wrapper.sv").write_text(
        hdr + emit_wrapper(ps, "FTBEntryGen"))
    ut = XSSV / "verif/ut/FTBEntryGen"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper(ps, "FTBEntryGen_xs"))
    (ut / "tb.sv").write_text(emit_tb(ps))
    print(f"FTBEntryGen: {len(ps)} ports, "
          f"{sum(1 for d,_,_ in ps if d=='output')} outputs")


if __name__ == "__main__":
    main()
