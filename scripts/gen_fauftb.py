#!/usr/bin/env python3
"""
FauFTB：解析 golden FauFTB.sv 端口，生成 wrapper(golden 同名 `FauFTB`) + _xs 镜像
(`FauFTB_xs`) + 随机比对 tb。

wrapper 例化参数化核 xs_FauFTB_core：
  - 大多数端口名一致直连。
  - s1.full_pred 的 4 个 dup（io_out_s1_full_pred_<d>_<field>）共享核的单份 fp_<field>
    输出（核内已证明 4 dup 内容相同），由 wrapper 扇出连接。
  - 核内例化 golden 同名子模块 FauFTBWay（由 rtl/frontend/FauFTBWay_wrapper.sv 提供）。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# full_pred 字段名（去掉 io_out_s1_full_pred_<d>_ 前缀后的后缀）→ 核 fp_<suffix>
FP_RE = re.compile(r"^io_out_s1_full_pred_(\d)_(.+)$")


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def emit_module(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);", ""]

    # full_pred：核仅一份 fp_<field> 输出 → 接到内部线 fpw_<field>，再扇出到 4 dup。
    fp_fields = {}   # suffix -> width
    for d, w, n in ps:
        m = FP_RE.match(n)
        if m and m.group(1) == "0":
            fp_fields[m.group(2)] = w
    for suf, w in fp_fields.items():
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {ws}fpw_{suf};")
    L.append("")

    # 核例化
    conns = []
    fp_done = set()
    for d, w, n in ps:
        if n in ("clock", "reset"):
            conns.append(f"    .{n}({n})")
            continue
        m = FP_RE.match(n)
        if m:
            suf = m.group(2)
            if suf not in fp_done:        # 仅连一次：核端口 fp_<suf> → 内部线
                conns.append(f"    .fp_{suf}(fpw_{suf})")
                fp_done.add(suf)
            continue
        conns.append(f"    .{n}({n})")
    L.append("  xs_FauFTB_core #(")
    L.append("    .NUM_WAYS(32), .NUM_BR(2), .TAG_W(16), .PC_W(50), .RV_W(48), .META_W(516)")
    L.append("  ) u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("")
    # 扇出到 4 个 dup
    for d, w, n in ps:
        m = FP_RE.match(n)
        if m:
            L.append(f"  assign {n} = fpw_{m.group(2)};")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("FauFTB")
    hdr = "// 自动生成：scripts/gen_fauftb.py —— 勿手改\n"

    (XSSV / "rtl/frontend/FauFTB_wrapper.sv").write_text(hdr + emit_module("FauFTB", ps))
    ut = XSSV / "verif/ut/FauFTB"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_module("FauFTB_xs", ps))

    # ---- tb ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["""// 自动生成：scripts/gen_fauftb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
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
    T.append(f"  FauFTB    u_g ({', '.join(gg)});")
    T.append(f"  FauFTB_xs u_i ({', '.join(ig)});")

    # 激励：复位后随机驱动。pc 类压缩值域提高 tag 命中率；fire/valid 概率化。
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_update_valid <= 1'b0;")
    T.append("      io_s0_fire_0 <= 1'b0; io_s0_fire_1 <= 1'b0;")
    T.append("      io_s0_fire_2 <= 1'b0; io_s0_fire_3 <= 1'b0;")
    T.append("      io_s1_fire_0 <= 1'b0; io_s1_fire_1 <= 1'b0;")
    T.append("      io_s1_fire_2 <= 1'b0; io_s1_fire_3 <= 1'b0;")
    T.append("      io_s2_fire_0 <= 1'b0; io_s2_fire_1 <= 1'b0;")
    T.append("      io_s2_fire_2 <= 1'b0; io_s2_fire_3 <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n in ("io_s0_fire_0", "io_s0_fire_1", "io_s0_fire_2", "io_s0_fire_3",
                 "io_s1_fire_0", "io_s1_fire_1", "io_s1_fire_2", "io_s1_fire_3",
                 "io_s2_fire_0", "io_s2_fire_1", "io_s2_fire_2", "io_s2_fire_3"):
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n in ("io_update_valid", "io_ctrl_ubtb_enable"):
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n in ("io_in_bits_s0_pc_0", "io_in_bits_s0_pc_1",
                   "io_in_bits_s0_pc_2", "io_in_bits_s0_pc_3", "io_update_bits_pc"):
            # 低位（tag = pc[16:1]）压缩值域，提升命中率；其余位随机
            T.append(f"      {n} <= {{{w-17}'($urandom), 16'($urandom_range(0,31)), 1'b0}};")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    # 比对：复位后，等组合稳定再逐拍比对所有输出。
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=30) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    print(f"FauFTB: {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
