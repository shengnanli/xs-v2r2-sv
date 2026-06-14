#!/usr/bin/env python3
"""F3Predecoder：解析 golden 端口生成 wrapper(golden同名)+_xs镜像+随机比对 tb。"""
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
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit_wrapper(ps, modname):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    L.append("  wire [15:0][31:0] instr_arr;")
    for d, w, n in ps:
        m = re.match(r"io_in_instr_(\d+)$", n)
        if m:
            L.append(f"  assign instr_arr[{m.group(1)}] = {n};")
    L.append("  wire [15:0][1:0] c_brType;")
    L.append("  wire [15:0]      c_isCall, c_isRet;")
    L.append("  xs_F3Predecoder_core #(.PW(16)) u_core (")
    L.append("    .io_instr(instr_arr), .pd_brType(c_brType),")
    L.append("    .pd_isCall(c_isCall), .pd_isRet(c_isRet)")
    L.append("  );")
    for d, w, n in ps:
        if d != "output":
            continue
        for rgx, tmpl in [(r"io_out_pd_(\d+)_brType$", "c_brType[{i}]"),
                          (r"io_out_pd_(\d+)_isCall$", "c_isCall[{i}]"),
                          (r"io_out_pd_(\d+)_isRet$",  "c_isRet[{i}]")]:
            mm = re.match(rgx, n)
            if mm:
                L.append(f"  assign {n} = {tmpl.format(i=mm.group(1))};")
                break
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input"]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    L = ["""// 自动生成：scripts/gen_f3predecoder.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int errors = 0, checks = 0;
"""]
    for w, n in ins:
        L.append(f"  logic [{w-1}:0] {n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {ws}g_{n};")
        L.append(f"  wire {ws}i_{n};")
    gc = [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    L.append(f"  F3Predecoder    u_g ({', '.join(gg)});")
    L.append(f"  F3Predecoder_xs u_i ({', '.join(ig)});")
    L.append("  initial begin")
    L.append("    for (int t = 0; t < NVEC; t++) begin")
    for w, n in ins:
        L.append(f"      {n} = {w}'($urandom);")
    L.append("      #1; checks++;")
    for w, n in outs:
        L.append(f"      if (g_{n} !== i_{n}) begin errors++;")
        L.append(f"        if (errors<=20) $display(\"vec %0d {n}: g=%h i=%h\", t, g_{n}, i_{n}); end")
    L.append("    end")
    L.append("""    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    ps = ports("F3Predecoder")
    hdr = "// 自动生成：scripts/gen_f3predecoder.py —— 勿手改\n"
    (XSSV / "rtl/frontend/F3Predecoder_wrapper.sv").write_text(hdr + emit_wrapper(ps, "F3Predecoder"))
    ut = XSSV / "verif/ut/F3Predecoder"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper(ps, "F3Predecoder_xs"))
    (ut / "tb.sv").write_text(emit_tb(ps))
    print(f"F3Predecoder: {len(ps)} ports")


if __name__ == "__main__":
    main()
