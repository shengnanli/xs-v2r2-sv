#!/usr/bin/env python3
"""
WayLookup：解析 golden 端口生成 wrapper(golden 同名 WayLookup)、_xs 镜像、
随机比对 tb。

WayLookup 的端口已是逐字段扁平形式（io_*），与核 xs_WayLookup_core 端口一一同名，
故 wrapper / _xs 只是把这些端口透传给核（u_core），无需打包/拆分逻辑，也无需 fm_map
（寄存器命名已沿用 golden，Formality 按名 / 展平规则匹配）。
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


def emit(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    # 核与顶层端口同名，直接 .name(name) 透传
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_WayLookup_core #(")
    L.append("    .NWAY(32), .PTR_W(5), .VSETIDX_W(8), .WAYMASK_W(4), .PTAG_W(36),")
    L.append("    .EXCP_W(2), .PBMT_W(2), .META_W(1), .GPADDR_W(56),")
    L.append("    .BLKPADDR_W(42), .UPDVSET_W(8)")
    L.append("  ) u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("WayLookup")
    hdr = "// 自动生成：scripts/gen_waylookup.py —— 勿手改\n"

    (XSSV / "rtl/frontend/WayLookup_wrapper.sv").write_text(hdr + emit("WayLookup", ps))
    ut = XSSV / "verif/ut/WayLookup"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("WayLookup_xs", ps))

    # ---- testbench ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_waylookup.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
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
    T.append(f"  WayLookup    u_g ({', '.join(gg)});")
    T.append(f"  WayLookup_xs u_i ({', '.join(ig)});")

    # 随机激励：握手位单独控制以制造背压/前压；vSetIdx/ptag 压缩值域提高 update 命中率。
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_flush <= 1'b0;")
    T.append("      io_write_valid <= 1'b0;")
    T.append("      io_read_ready <= 1'b0;")
    T.append("      io_update_valid <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n == "io_flush":
            # 偶发 flush
            T.append(f"      {n} <= ($urandom_range(0,63)==0);")
        elif n == "io_write_valid":
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")
        elif n == "io_read_ready":
            T.append(f"      {n} <= ($urandom_range(0,2)!=0);")
        elif n == "io_update_valid":
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n in ("io_write_bits_entry_vSetIdx_0", "io_write_bits_entry_vSetIdx_1",
                   "io_update_bits_vSetIdx"):
            T.append(f"      {n} <= {w}'($urandom_range(0,7));")
        elif n in ("io_write_bits_entry_ptag_0", "io_write_bits_entry_ptag_1"):
            T.append(f"      {n} <= {w}'($urandom_range(0,15));")
        elif n == "io_update_bits_blkPaddr":
            # 低 6 位无关；tag=[41:6] 取小值域以匹配 ptag
            T.append(f"      {n} <= {{{w-6}'($urandom_range(0,15)), 6'($urandom)}};")
        elif n in ("io_write_bits_entry_waymask_0", "io_write_bits_entry_waymask_1",
                   "io_update_bits_waymask"):
            T.append(f"      {n} <= {w}'($urandom_range(0,15));")
        elif n in ("io_write_bits_entry_itlb_exception_0",
                   "io_write_bits_entry_itlb_exception_1"):
            # 偏向 gpf(2) 以覆盖 gpf 路径
            T.append(f"      {n} <= {w}'($urandom_range(0,3));")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=30) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"WayLookup: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
