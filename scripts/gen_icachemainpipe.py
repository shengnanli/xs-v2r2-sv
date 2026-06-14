#!/usr/bin/env python3
"""
ICacheMainPipe：解析 golden 端口生成 wrapper(golden 同名 ICacheMainPipe)、_xs 镜像、
随机比对 tb。

ICacheMainPipe 端口已是逐字段扁平形式（io_*），与核 xs_ICacheMainPipe_core 端口一一
同名，故 wrapper / _xs 只是把这些端口透传给核（u_core），无需打包/拆分逻辑，也无需
fm_map（寄存器命名已沿用 golden，Formality 按名 / 展平规则匹配）。

注：golden 含子模块 Arbiter2_ICacheMissReq（toMSHRArbiter），手写核已将其内联，故
UT/FM 的 ref 侧需带上该子模块文件（见 Makefile GOLDEN_SRCS / FM_REF_DEPS）。
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
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_ICacheMainPipe_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("ICacheMainPipe")
    hdr = "// 自动生成：scripts/gen_icachemainpipe.py —— 勿手改\n"

    (XSSV / "rtl/frontend/ICacheMainPipe_wrapper.sv").write_text(hdr + emit("ICacheMainPipe", ps))
    ut = XSSV / "verif/ut/ICacheMainPipe"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("ICacheMainPipe_xs", ps))

    # ---- testbench ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_icachemainpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 120000;
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
    T.append(f"  ICacheMainPipe    u_g ({', '.join(gg)});")
    T.append(f"  ICacheMainPipe_xs u_i ({', '.join(ig)});")

    # 随机激励：握手位单独控制以制造背压/前压；vSetIdx/ptag 压缩值域提高 MSHR 命中率。
    # 关键约束：wayLookup.vSetIdx 必须与 ftq pcMemRead_4 的 vSet 一致（golden 有断言，
    # 虽在 SYNTHESIS 下关闭，但保持一致更接近真实），这里把二者绑同源随机量。
    T.append("  // 共享随机量：把 ftq pcMemRead_4 的 vSet 与 wayLookup vSetIdx 对齐")
    T.append("  logic [7:0] rnd_vset0, rnd_vset1;")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for _, n in ins:
        if n in ("io_flush", "io_fetch_req_valid", "io_wayLookupRead_valid",
                 "io_dataArray_toIData_3_ready", "io_mshr_req_ready", "io_mshr_resp_valid",
                 "io_respStall", "io_ecc_enable"):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    T.append("      rnd_vset0 <= 8'($urandom_range(0,3));")
    T.append("      rnd_vset1 <= 8'($urandom_range(0,3));")
    for w, n in ins:
        if n == "io_flush":
            T.append(f"      {n} <= ($urandom_range(0,31)==0);")
        elif n == "io_fetch_req_valid":
            T.append(f"      {n} <= ($urandom_range(0,2)!=0);")
        elif n == "io_wayLookupRead_valid":
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")
        elif n == "io_dataArray_toIData_3_ready":
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")
        elif n == "io_mshr_req_ready":
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n == "io_mshr_resp_valid":
            T.append(f"      {n} <= ($urandom_range(0,2)==0);")
        elif n == "io_respStall":
            T.append(f"      {n} <= ($urandom_range(0,3)==0);")
        elif n == "io_ecc_enable":
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")
        # vSet 对齐：ftq pcMemRead_4 的 [13:6] 与 wayLookup vSetIdx 取同源小值域
        elif n == "io_fetch_req_bits_pcMemRead_4_startAddr":
            T.append(f"      {n} <= {{36'($urandom), rnd_vset0, 6'($urandom)}};")
        elif n == "io_fetch_req_bits_pcMemRead_4_nextlineStart":
            T.append(f"      {n} <= {{36'($urandom), rnd_vset1, 6'($urandom)}};")
        elif n in ("io_wayLookupRead_bits_entry_vSetIdx_0",):
            T.append(f"      {n} <= rnd_vset0;")
        elif n in ("io_wayLookupRead_bits_entry_vSetIdx_1",):
            T.append(f"      {n} <= rnd_vset1;")
        # ptag/blkPaddr 压缩值域，提高 MSHR tag 比较命中率
        elif n in ("io_wayLookupRead_bits_entry_ptag_0", "io_wayLookupRead_bits_entry_ptag_1"):
            T.append(f"      {n} <= {w}'($urandom_range(0,7));")
        elif n == "io_mshr_resp_bits_blkPaddr":
            # tag=[41:6]，低 6 位无关；取小值域以匹配 ptag
            T.append(f"      {n} <= {{{w-6}'($urandom_range(0,7)), 6'($urandom)}};")
        elif n == "io_mshr_resp_bits_vSetIdx":
            T.append(f"      {n} <= 8'($urandom_range(0,3));")
        elif n in ("io_wayLookupRead_bits_entry_waymask_0", "io_wayLookupRead_bits_entry_waymask_1"):
            # waymask 偏向 one-hot/全0 以覆盖 hit_num 0/1/多 各路径
            T.append(f"      {n} <= {w}'($urandom_range(0,15));")
        elif n in ("io_wayLookupRead_bits_entry_itlb_exception_0",
                   "io_wayLookupRead_bits_entry_itlb_exception_1",
                   "io_wayLookupRead_bits_entry_itlb_pbmt_0",
                   "io_wayLookupRead_bits_entry_itlb_pbmt_1"):
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
        T.append(f"      if(errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    print(f"ICacheMainPipe: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
