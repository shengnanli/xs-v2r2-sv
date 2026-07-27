#!/usr/bin/env python3
"""生成 PipeGroupConnect 的可读核 wrapper / _xs 变体 / UT tb。

golden PipeGroupConnect = 6 lane 组流水连接。每 lane payload 110 字段(in/out 同名同序)。
wrapper 把每 lane 的 in_bits_<field> 按声明序拼成 in_bits[lane] 总线, 再从 out_bits[lane]
拆回各 out_bits_<field>。valid/ready/flush/outAllFire 直连。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
NAME = "PipeGroupConnect"
CORE = "xs_PipeGroupConnect_core"
NLANE = 6


def parse_ports():
    text = (GOLDEN / f"{NAME}.sv").read_text()
    m = re.search(rf"^module {NAME}\((.*?)\n\);", text, re.S | re.M)
    assert m
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            d, w, n = pm.group(1), pm.group(2), pm.group(3)
            ports.append((d, int(w) + 1 if w else 1, n))
    return ports


def lane_bits(ports, io, lane):
    """返回 lane 的 [(width, field_suffix)] 按声明序。"""
    pref = f"io_{io}_{lane}_bits_"
    return [(w, nm[len(pref):]) for d, w, nm in ports if nm.startswith(pref)]


def port_decl(ports):
    lines = []
    n = len(ports)
    for i, (d, w, nm) in enumerate(ports):
        wid = "" if w == 1 else f"[{w-1}:0] "
        lines.append(f"  {d} {wid}{nm}{'' if i == n-1 else ','}")
    return "\n".join(lines)


def gen(ports, modname):
    # 各 lane 独立字段序/位宽(lane0 多 snapshot 字段)。
    lane_fields = [lane_bits(ports, "in", l) for l in range(NLANE)]
    widths = [sum(w for w, _ in lf) for lf in lane_fields]

    lines = []
    for lane in range(NLANE):
        fields = lane_fields[lane]
        dw = widths[lane]
        # in_bits 打包。
        terms = ", ".join(f"io_in_{lane}_bits_{suf}" for _, suf in fields)
        lines.append(f"  wire [{dw-1}:0] in_bus_{lane} = {{{terms}}};")
        lines.append(f"  wire [{dw-1}:0] out_bus_{lane};")
        # out_bits 拆分。
        hi = dw - 1
        for w, suf in fields:
            lines.append(f"  assign io_out_{lane}_bits_{suf} = out_bus_{lane}[{hi}:{hi-w+1}];")
            hi -= w

    in_valid = "{" + ", ".join(f"io_in_{l}_valid" for l in reversed(range(NLANE))) + "}"
    out_ready = "{" + ", ".join(f"io_out_{l}_ready" for l in reversed(range(NLANE))) + "}"
    wparams = ", ".join(f".W{l}({widths[l]})" for l in range(NLANE))
    inbus = "\n    ".join(f".in_bits_{l}(in_bus_{l})," for l in range(NLANE))
    outbus = "\n    ".join(f".out_bits_{l}(out_bus_{l}){',' if l < NLANE-1 else ''}"
                           for l in range(NLANE))

    inst = f"""  {CORE} #({wparams}) u_core (
    .clock(clock),
    .reset(reset),
    .io_flush(io_flush),
    .io_outAllFire(io_outAllFire),
    .in_valid({in_valid}),
    .out_ready({out_ready}),
    .in_ready({{io_in_5_ready, io_in_4_ready, io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}}),
    .out_valid({{io_out_5_valid, io_out_4_valid, io_out_3_valid, io_out_2_valid, io_out_1_valid, io_out_0_valid}}),
    {inbus}
    {outbus}
  );"""

    hdr = port_decl(ports)
    return f"module {modname}(\n{hdr}\n);\n" + "\n".join(lines) + "\n" + inst + "\nendmodule\n"


def gen_tb(ports):
    ins = [(w, nm) for d, w, nm in ports if d == "input" and nm not in ("clock", "reset")]
    outs = [(w, nm) for d, w, nm in ports if d == "output"]

    def decl(s, w):
        return f"logic {'' if w==1 else f'[{w-1}:0] '}{s};"

    in_sig = "\n  ".join(decl(nm, w) for w, nm in ins)
    g_sig = "\n  ".join(decl("g_" + nm, w) for w, nm in outs)
    i_sig = "\n  ".join(decl("i_" + nm, w) for w, nm in outs)

    def cn(p):
        L = [".clock(clk)", ".reset(reset)"]
        for w, nm in ins:
            L.append(f".{nm}({nm})")
        for w, nm in outs:
            L.append(f".{nm}({p}{nm})")
        return ",\n    ".join(L)

    drive = "\n    ".join(f"{nm} = $urandom;" for w, nm in ins)
    checks = "\n    ".join(
        f'if (!$isunknown(g_{nm}) && (g_{nm}) !== (i_{nm})) begin errors++; '
        f'if (errors<=60) $display("[%0t] {nm} g=%h i=%h",$time,g_{nm},i_{nm}); end checks++;'
        for w, nm in outs)

    tb = f"""// 自动生成: scripts/gen_pgc.py —— PipeGroupConnect UT: golden vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  {in_sig}
  {g_sig}
  {i_sig}

  {NAME} u_g (
    {cn("g_")}
  );
  {NAME}_xs u_i (
    {cn("i_")}
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    {drive}
  endtask
  task automatic check_outputs();
    {checks}
  endtask

  initial begin
    drive_inputs(); reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
"""
    (XSSV / "verif/ut/PipeGroupConnect/tb.sv").write_text(tb)


def main():
    ports = parse_ports()
    (XSSV / "verif/ut/PipeGroupConnect").mkdir(parents=True, exist_ok=True)
    (XSSV / "rtl/backend/PipeGroupConnect_wrapper.sv").write_text(
        "// 自动生成: scripts/gen_pgc.py —— golden 同名 wrapper(FM impl), 例化 " + CORE + "。\n"
        + gen(ports, NAME))
    (XSSV / "verif/ut/PipeGroupConnect/variants_xs.sv").write_text(
        "// 自动生成: scripts/gen_pgc.py —— _xs 变体(UT)。\n" + gen(ports, NAME + "_xs"))
    gen_tb(ports)
    print("generated PipeGroupConnect wrapper/_xs/tb; fields/lane:",
          len(lane_bits(ports, "in", 0)))


if __name__ == "__main__":
    main()
