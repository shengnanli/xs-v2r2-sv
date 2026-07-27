#!/usr/bin/env python3
"""生成 PipelineConnectPipe 的可读核 wrapper / _xs 变体 / UT tb。

golden PipelineConnectPipe = 阻塞式单级流水缓冲。payload 有 100 个 out_bits 字段,
其中 97 个有对应 in_bits 字段, 3 个(lsrc_3/lsrc_4/vpu_vmask)常量 0 输出(无输入)。
data 总线按 out_bits 声明序拼接; 有输入的字段喂对应 in_bits, 无输入的喂 0。
输出侧再按同序把 data 总线拆回各 out_bits 字段。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
NAME = "PipelineConnectPipe"


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


def port_decl(ports, xs=False):
    """golden 同名端口声明串(module header)。"""
    lines = []
    n = len(ports)
    for i, (d, w, nm) in enumerate(ports):
        wid = "" if w == 1 else f"[{w-1}:0] "
        comma = "," if i < n - 1 else ""
        lines.append(f"  {d} {wid}{nm}{comma}")
    return "\n".join(lines)


def gen(ports, modname):
    in_bits = [(w, nm) for d, w, nm in ports if nm.startswith("io_in_bits_")]
    out_bits = [(w, nm) for d, w, nm in ports if nm.startswith("io_out_bits_")]
    in_suffixes = {nm[len("io_in_bits_"):] for _, nm in in_bits}

    # data 总线按 out_bits 声明序拼接(MSB 优先)。
    data_width = sum(w for w, _ in out_bits)

    # 输入侧: 每个 out 字段, 若有对应 in 则喂 in_bits_<suf>, 否则喂 0。
    in_terms = []
    for w, nm in out_bits:
        suf = nm[len("io_out_bits_"):]
        if suf in in_suffixes:
            in_terms.append(f"io_in_bits_{suf}")
        else:
            in_terms.append(f"{w}'h0")
    in_bus = "{" + ", ".join(in_terms) + "}"

    # 输出侧: 从总线切片拆回各 out 字段。
    out_assigns = []
    hi = data_width - 1
    for w, nm in out_bits:
        out_assigns.append(f"  assign {nm} = out_bus[{hi}:{hi-w+1}];")
        hi -= w

    hdr = port_decl(ports)
    body = f"""  wire [{data_width-1}:0] out_bus;
{chr(10).join(out_assigns)}
  xs_PipelineConnectPipe #(.DATA_WIDTH({data_width})) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({in_bus}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );"""
    return f"module {modname}(\n{hdr}\n);\n{body}\nendmodule\n"


def main():
    ports = parse_ports()

    # 1) golden 同名 wrapper (FM impl 侧)
    wrapper = ("// 自动生成: scripts/gen_pcp.py —— 勿手改\n"
               "// golden 同名 PipelineConnectPipe wrapper(FM/UT impl 侧), 例化 xs_PipelineConnectPipe。\n"
               + gen(ports, NAME))
    (XSSV / "rtl/backend/PipelineConnectPipe_wrapper.sv").write_text(wrapper)

    # 2) _xs 变体 (UT 用, 与 golden 同时例化)
    xs = ("// 自动生成: scripts/gen_pcp.py —— 勿手改\n"
          + gen(ports, NAME + "_xs"))
    (XSSV / "verif/ut/PipelineConnectPipe/variants_xs.sv").write_text(xs)

    # 3) tb: golden vs _xs 逐拍逐输出比对
    gen_tb(ports)
    print("generated PipelineConnectPipe wrapper/_xs/tb")


def gen_tb(ports):
    # 输入端口(除 clock/reset), 输出端口
    ins = [(w, nm) for d, w, nm in ports if d == "input" and nm not in ("clock", "reset")]
    outs = [(w, nm) for d, w, nm in ports if d == "output"]

    def decl(sig, w):
        return f"logic {'' if w==1 else f'[{w-1}:0] '}{sig};"

    in_sig = "\n  ".join(decl(nm, w) for w, nm in ins)
    g_sig = "\n  ".join(decl("g_" + nm, w) for w, nm in outs)
    i_sig = "\n  ".join(decl("i_" + nm, w) for w, nm in outs)

    def conn(prefix):
        lines = [".clock(clk)", ".reset(reset)"]
        for w, nm in ins:
            lines.append(f".{nm}({nm})")
        for w, nm in outs:
            lines.append(f".{nm}({prefix}{nm})")
        return ",\n    ".join(lines)

    drive = "\n    ".join(f"{nm} = $urandom;" for w, nm in ins)
    checks = "\n    ".join(
        f'if (!$isunknown(g_{nm}) && (g_{nm}) !== (i_{nm})) begin errors++; '
        f'if (errors<=60) $display("[%0t] {nm} g=%h i=%h",$time,g_{nm},i_{nm}); end checks++;'
        for w, nm in outs)

    tb = f"""// 自动生成: scripts/gen_pcp.py —— 勿手改
// tb —— PipelineConnectPipe UT: golden vs 可读核 _xs 逐拍逐输出比对。
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
    {conn("g_")}
  );

  {NAME}_xs u_i (
    {conn("i_")}
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    {drive}
  endtask

  task automatic check_outputs();
    {checks}
  endtask

  initial begin
    drive_inputs();
    reset = 1;
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
    (XSSV / "verif/ut/PipelineConnectPipe/tb.sv").write_text(tb)


if __name__ == "__main__":
    main()
