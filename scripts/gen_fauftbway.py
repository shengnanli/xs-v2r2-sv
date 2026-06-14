#!/usr/bin/env python3
"""
FauFTBWay：解析 golden 端口生成 wrapper(golden同名)+_xs镜像+随机比对 tb + fm_map。
entry 作为打包 data 整体存取；wrapper 把 golden 扁平字段（io_write_entry_<f> /
io_resp_<f>）拼接成核的 io_write_entry/io_resp，并输出字段位偏移映射供 FM
match_packed_payload 把 golden 逐字段寄存器 data_<f> 对到核的 data_reg 切片。
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


def main():
    ps = ports("FauFTBWay")
    # 实体字段：io_write_entry_<suffix>（声明序）；resp 按同 suffix
    fields = [(w, n[len("io_write_entry_"):]) for d, w, n in ps if n.startswith("io_write_entry_")]
    entry_w = sum(w for w, _ in fields)
    # LSB 优先布局（与 PipelineConnect 一致，便于 FM 位号对齐）
    pos, lo = {}, 0
    for w, suf in fields:
        pos[suf] = (lo + w - 1, lo)
        lo += w

    def emit(modname):
        decls = []
        for d, w, n in ps:
            ws = f"[{w-1}:0] " if w > 1 else ""
            decls.append(f"  {d:6s} {ws}{n}")
        L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
        # 写 entry 打包（首字段 LSB → 拼接列表反序，左为 MSB）
        wparts = [f"io_write_entry_{suf}" for _, suf in reversed(fields)]
        L.append(f"  wire [{entry_w-1}:0] resp_packed;")
        # resp 字段拆分
        for d, w, n in ps:
            if n.startswith("io_resp_") and n != "io_resp_hit":
                suf = n[len("io_resp_"):]
                hi, lo2 = pos[suf]
                sl = f"[{hi}:{lo2}]" if (hi, lo2) != (entry_w - 1, 0) else ""
                L.append(f"  assign {n} = resp_packed{sl};")
        L.append(f"  xs_FauFTBWay #(.TAG_W(16), .ENTRY_W({entry_w})) u_core (")
        L.append(f"    .clock(clock), .reset(reset),")
        L.append(f"    .io_req_tag(io_req_tag), .io_resp(resp_packed), .io_resp_hit(io_resp_hit),")
        L.append(f"    .io_update_req_tag(io_update_req_tag), .io_update_hit(io_update_hit),")
        L.append(f"    .io_write_valid(io_write_valid),")
        L.append(f"    .io_write_entry({{{', '.join(wparts)}}}),")
        L.append(f"    .io_write_tag(io_write_tag)")
        L.append(f"  );")
        L.append("endmodule\n")
        return "\n".join(L)

    hdr = "// 自动生成：scripts/gen_fauftbway.py —— 勿手改\n"
    (XSSV / "rtl/frontend/FauFTBWay_wrapper.sv").write_text(hdr + emit("FauFTBWay"))
    ut = XSSV / "verif/ut/FauFTBWay"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("FauFTBWay_xs"))
    # fm_map：golden data_<suffix> → 核 data_reg[lo+b]
    (ut / "fm_map").mkdir(exist_ok=True)
    (ut / "fm_map" / "FauFTBWay.txt").write_text(
        "".join(f"{suf} {pos[suf][1]} {w}\n" for w, suf in fields))

    # tb
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["""// 自动生成：scripts/gen_fauftbway.py —— 勿手改
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
    T.append(f"  FauFTBWay    u_g ({', '.join(gg)});")
    T.append(f"  FauFTBWay_xs u_i ({', '.join(ig)});")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) io_write_valid <= 1'b0;")
    T.append("    else begin")
    for w, n in ins:
        if n == "io_write_valid":
            T.append(f"      {n} <= ($urandom_range(0,3)==0);")
        elif n in ("io_req_tag", "io_update_req_tag", "io_write_tag"):
            # 压缩 tag 值域以提高命中率
            T.append(f"      {n} <= {w}'($urandom_range(0,15));")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=20) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    print(f"FauFTBWay: entry_w={entry_w}, {len(fields)} fields")


if __name__ == "__main__":
    main()
