#!/usr/bin/env python3
"""
LoadPipe：解析 golden 端口生成 wrapper(golden 同名 LoadPipe)、_xs 镜像、随机比对 tb。

LoadPipe 的 golden 端口已是逐字段扁平形式(io_*)，与可读核 xs_LoadPipe_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核(u_core)，无需打包/拆分逻辑。

设计意图来自 src/main/scala/xiangshan/cache/dcache/loadpipe/LoadPipe.scala(四级 s0~s3)。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/LoadPipe.sv
(端口表 + LoadPipe_core_body.svh)。

本顶层配置裁剪(golden 已固化)：WPU 关、io.nack 恒 0、meta_read 恒 ready。
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


def emit_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_LoadPipe_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_core(ps):
    """拼接可读核 LoadPipe.sv：模块头 + 端口表 + 手写主体(_core_body.svh)。
    端口名/序与 golden 完全一致，主体从 LoadPipe.scala 设计意图重写。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    body = (XSSV / "rtl/memblock/LoadPipe_core_body.svh").read_text()
    L = ["// 自动生成框架(端口表) + 手写主体(LoadPipe_core_body.svh)",
         "//   由 scripts/gen_loadpipe.py 拼接。可读核本体改 LoadPipe_core_body.svh。",
         "module xs_LoadPipe_core(", ",\n".join(decls) + "\n);", body, "endmodule"]
    return "\n".join(L)


def main():
    ps = ports("LoadPipe")
    hdr = "// 自动生成：scripts/gen_loadpipe.py —— 勿手改\n"

    (XSSV / "rtl/memblock/LoadPipe.sv").write_text(emit_core(ps))
    (XSSV / "rtl/memblock/LoadPipe_wrapper.sv").write_text(hdr + emit_wrapper("LoadPipe", ps))
    ut = XSSV / "verif/ut/LoadPipe"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("LoadPipe_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    in_names = {n for _, n in ins}

    T = ["""// 自动生成：scripts/gen_loadpipe.py —— 勿手改
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
    T.append(f"  LoadPipe    u_g ({', '.join(gg)});")
    T.append(f"  LoadPipe_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 关键覆盖点：tag 命中(需 4 路 tag_resp 中某路 == paddr[47:12] 且 coh 有效) /
    # 各种 cmd(load/pf) / 128b / nack_data(banked_data_read_ready 偶 0) / miss(req_ready 偶 0)。
    # 为了让 tag 命中可达：把 paddr 高位与某一路 tag_resp 高位"对齐"困难——改为
    # 让 tag_resp_k 与 paddr[47:12] 共享一个小随机域(36 位压窄成 ~4 位随机)，
    # 这样 4 路里命中概率显著，覆盖 hit/coh/btot 分支。
    def rnd(w, n):
        # tag/paddr 压窄高位以提高命中概率
        if n in ("io_tag_resp_0", "io_tag_resp_1", "io_tag_resp_2", "io_tag_resp_3"):
            # enc tag 43 位：低 36 位是 tag(压窄)，高 7 位是 ecc(随机)
            return "{7'($urandom), 34'h0, 2'($urandom_range(0,3))}"
        if n in ("io_lsu_s1_paddr_dup_lsu", "io_lsu_s1_paddr_dup_dcache"):
            # paddr 48 位：[47:12] tag 区压成低 2 位随机，[11:0] 偏移随机
            return "{34'h0, 2'($urandom_range(0,3)), 12'($urandom)}"
        # coh 状态 2 位：有效概率高(覆盖 Branch/Trunk/Dirty)
        if n.endswith("_coh_state"):
            return "2'($urandom_range(0,3))"
        # cmd：覆盖 load(0)/pfr(2)/pfw(3) 与写类(让 has_perm/btot 分支动)
        if n == "io_lsu_req_bits_cmd":
            return "5'($urandom_range(0,15))"
        if n == "io_lsu_req_bits_instrtype":
            return "4'($urandom_range(0,3))"   # 含 3==prefetch source
        if n in ("io_lsu_req_valid", "io_tag_read_ready", "io_banked_data_read_ready",
                 "io_miss_req_ready"):
            return "($urandom_range(0,4)!=0)"   # 多数拍 ready/valid
        if n in ("io_lsu_s1_kill", "io_lsu_s2_kill"):
            return "($urandom_range(0,7)==0)"   # 偶发 kill
        if n in ("io_occupy_fail", "io_wbq_block_miss_req", "io_bank_conflict_slow"):
            return "($urandom_range(0,5)==0)"
        if n == "io_load128Req":
            return "($urandom_range(0,3)==0)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    if "io_lsu_req_valid" in in_names:
        T.append("      io_lsu_req_valid <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出(跳过 golden 为 X 的不可达态)。
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    print(f"LoadPipe: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
