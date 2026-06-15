#!/usr/bin/env python3
"""
ICache 顶层：解析 golden ICache 端口，生成
  · rtl/frontend/ICache_wrapper.sv      —— golden 同名 wrapper，端口透传给可读核 xs_ICache_core
  · verif/ut/ICache/variants_xs.sv      —— _xs 镜像（同 wrapper，例化核）
  · verif/ut/ICache/tb.sv               —— golden vs _xs 双例化、随机激励、逐拍比对全部输出

可读核 xs_ICache_core 的端口与 golden 完全同名同序同宽（含全部 sideband），故 wrapper/_xs
仅做 1:1 端口透传，无任何逻辑（可读性体现在核的模块体：分节/具名/注释）。8 个子模块
（MainPipe/Prefetch/MissUnit/WayLookup/Meta/DataArray/Replacer/CtrlUnit）由核直接例化 golden
同名模块；UT 双例化时 golden 侧与 _xs 侧用同一批 golden 子模块实现，故比对只检验顶层互联/
仲裁是否等价；FM 时这些子模块两侧均不读源 → hdlin_unresolved_modules=black_box 统一黑盒。
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
    L.append("  xs_ICache_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


# 不参与随机驱动的握手/控制输入：复位区清 0，活动区给特定概率分布
PROB = {
    "io_flush":               "($urandom_range(0,31)==0)",
    "io_fencei":              "($urandom_range(0,63)==0)",
    "io_fetch_req_valid":     "($urandom_range(0,2)!=0)",
    "io_ftqPrefetch_req_valid":"($urandom_range(0,2)!=0)",
    "io_softPrefetch_0_valid":"($urandom_range(0,7)==0)",
    "io_softPrefetch_1_valid":"($urandom_range(0,7)==0)",
    "io_softPrefetch_2_valid":"($urandom_range(0,7)==0)",
    "io_stop":                "($urandom_range(0,3)==0)",
    "io_wfi_wfiReq":          "($urandom_range(0,15)==0)",
    "io_csr_pf_enable":       "($urandom_range(0,3)!=0)",
    "auto_ctrlUnitOpt_in_a_valid":"($urandom_range(0,3)==0)",
    "auto_ctrlUnitOpt_in_d_ready":"($urandom_range(0,1)==0)",
    "auto_client_out_a_ready":"($urandom_range(0,1)==0)",
    "auto_client_out_d_valid":"($urandom_range(0,2)==0)",
    "io_itlb_0_resp_bits_miss":"($urandom_range(0,3)==0)",
    "io_itlb_1_resp_bits_miss":"($urandom_range(0,3)==0)",
}
# 复位区需清 0 的控制位（valid/flush 类，避免复位期间发起事务）
RST0 = list(PROB.keys())


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_icache.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
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
    T.append(f"  ICache    u_g ({', '.join(gg)});")
    T.append(f"  ICache_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # vSetIdx 压缩到小值域以提高 cache 命中/MSHR 合并；ptag/blkPaddr 压缩值域；
    # 取指请求的 pcMemRead_4（mainpipe 实际用的 vSet 源）与 prefetch 起始地址绑同源小值域。
    T.append("  logic [7:0] rnd_vset;")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in RST0:
        if n in dict((nn, ww) for ww, nn in ins):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    T.append("      rnd_vset <= 8'($urandom_range(0,7));")
    for w, n in ins:
        if n in PROB:
            T.append(f"      {n} <= {PROB[n]};")
        elif n in ("io_fetch_req_bits_pcMemRead_0_startAddr",
                   "io_fetch_req_bits_pcMemRead_1_startAddr",
                   "io_fetch_req_bits_pcMemRead_2_startAddr",
                   "io_fetch_req_bits_pcMemRead_3_startAddr",
                   "io_fetch_req_bits_pcMemRead_4_startAddr",
                   "io_ftqPrefetch_req_bits_startAddr",
                   "io_softPrefetch_0_bits_vaddr",
                   "io_softPrefetch_1_bits_vaddr",
                   "io_softPrefetch_2_bits_vaddr"):
            # [13:6]=vSetIdx 取小值域；其余随机
            T.append(f"      {n} <= {{36'($urandom), 8'($urandom_range(0,7)), 6'($urandom)}};")
        elif n in ("io_fetch_req_bits_pcMemRead_0_nextlineStart",
                   "io_fetch_req_bits_pcMemRead_1_nextlineStart",
                   "io_fetch_req_bits_pcMemRead_2_nextlineStart",
                   "io_fetch_req_bits_pcMemRead_3_nextlineStart",
                   "io_fetch_req_bits_pcMemRead_4_nextlineStart",
                   "io_ftqPrefetch_req_bits_nextlineStart"):
            T.append(f"      {n} <= {{36'($urandom), 8'($urandom_range(0,7)), 6'($urandom)}};")
        elif n in ("io_itlb_0_resp_bits_paddr_0", "io_itlb_1_resp_bits_paddr_0"):
            # paddr[47:12]=ptag 压缩值域，提高 tag 命中
            T.append(f"      {n} <= {{36'($urandom_range(0,15)), 12'($urandom)}};")
        elif n == "auto_client_out_d_bits_data":
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出（跳过 golden 未写项 X）
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (20) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = ports("ICache")
    hdr = "// 自动生成：scripts/gen_icache.py —— 勿手改\n"

    (XSSV / "rtl/frontend/ICache_wrapper.sv").write_text(hdr + emit("ICache", ps))
    ut = XSSV / "verif/ut/ICache"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("ICache_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))

    ins = [p for p in ps if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ps if p[0] == "output"]
    print(f"ICache: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
