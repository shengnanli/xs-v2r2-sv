#!/usr/bin/env python3
"""
为 PreDecode 生成 wrapper（golden 同名）+ _xs 镜像 + UT testbench。
PreDecode 是单实例纯组合模块；wrapper 把 golden 的扁平端口（io_in_bits_data_i /
io_out_pd_i_* / io_out_instr_i / ...）映射到参数化核 xs_PreDecode_core 的 arrayed 端口。
firtool 裁掉的恒定输出（如 pd_0_valid 恒1、hasHalfValid_0/1）不在 golden 端口里，
wrapper 自然不连。
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
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit_wrapper(ps, modname):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    # 输入数据数组
    L.append("  wire [16:0][15:0] data_arr;")
    for d, w, n in ps:
        m = re.match(r"io_in_bits_data_(\d+)$", n)
        if m:
            L.append(f"  assign data_arr[{m.group(1)}] = {n};")
    # core arrayed 输出网
    L.append("  wire [15:0]       c_valid, c_isRVC, c_isCall, c_isRet, c_hasHalfValid;")
    L.append("  wire [15:0][1:0]  c_brType;")
    L.append("  wire [15:0][31:0] c_instr;")
    L.append("  wire [15:0][63:0] c_jumpOffset;")
    L.append("  xs_PreDecode_core #(.PW(16), .XLEN(64)) u_core (")
    L.append("    .io_data(data_arr),")
    L.append("    .pd_valid(c_valid), .pd_isRVC(c_isRVC), .pd_brType(c_brType),")
    L.append("    .pd_isCall(c_isCall), .pd_isRet(c_isRet), .hasHalfValid(c_hasHalfValid),")
    L.append("    .instr(c_instr), .jumpOffset(c_jumpOffset)")
    L.append("  );")
    # 输出端口绑定
    pat = [
        (r"io_out_pd_(\d+)_valid$",  "c_valid[{i}]"),
        (r"io_out_pd_(\d+)_isRVC$",  "c_isRVC[{i}]"),
        (r"io_out_pd_(\d+)_brType$", "c_brType[{i}]"),
        (r"io_out_pd_(\d+)_isCall$", "c_isCall[{i}]"),
        (r"io_out_pd_(\d+)_isRet$",  "c_isRet[{i}]"),
        (r"io_out_hasHalfValid_(\d+)$", "c_hasHalfValid[{i}]"),
        (r"io_out_instr_(\d+)$",     "c_instr[{i}]"),
        (r"io_out_jumpOffset_(\d+)$","c_jumpOffset[{i}]"),
    ]
    for d, w, n in ps:
        if d != "output":
            continue
        for rgx, tmpl in pat:
            mm = re.match(rgx, n)
            if mm:
                L.append(f"  assign {n} = {tmpl.format(i=mm.group(1))};")
                break
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    L = ["""// 自动生成：scripts/gen_predecode.py —— 勿手改
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
    gc = [f".{n}({n})" for _, n in ins] + [".clock(1'b0)", ".reset(1'b0)"]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    L.append(f"  PreDecode    u_g ({', '.join(gg)});")
    L.append(f"  PreDecode_xs u_i ({', '.join(ig)});")
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
    ps = ports("PreDecode")
    hdr = "// 自动生成：scripts/gen_predecode.py —— 勿手改\n"
    (XSSV / "rtl/frontend/PreDecode_wrapper.sv").write_text(hdr + emit_wrapper(ps, "PreDecode"))
    ut = XSSV / "verif/ut/PreDecode"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper(ps, "PreDecode_xs"))
    (ut / "tb.sv").write_text(emit_tb(ps))
    print(f"PreDecode: {len(ps)} ports, "
          f"{sum(1 for d,_,_ in ps if d=='output')} outputs")


if __name__ == "__main__":
    main()
