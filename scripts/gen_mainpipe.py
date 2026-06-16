#!/usr/bin/env python3
"""
MainPipe（L1 DCache 主流水）：解析 golden 端口生成 wrapper（golden 同名 MainPipe）、
_xs 镜像、随机比对 tb。

golden MainPipe 的端口已是逐字段扁平形式（io_*），与可读核 xs_MainPipe_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。

核内例化两个 golden 叶子黑盒：
  * AMOALU                —— AMO 算术/逻辑运算单元
  * Arbiter4_MainPipeReq  —— probe/refill/store/atomic 四源固定优先级仲裁
UT 两侧共用同一份 golden 黑盒；FM 时作为两侧共享黑盒。

设计意图来自 src/main/scala/xiangshan/cache/dcache/mainpipe/MainPipe.scala（s0~s3 四级）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/MainPipe.sv。
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
    L.append("  xs_MainPipe_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("MainPipe")
    hdr = "// 自动生成：scripts/gen_mainpipe.py —— 勿手改\n"

    (XSSV / "rtl/memblock/MainPipe_wrapper.sv").write_text(hdr + emit("MainPipe", ps))
    ut = XSSV / "verif/ut/MainPipe"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("MainPipe_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_mainpipe.py —— 勿手改
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
    T.append(f"  MainPipe    u_g ({', '.join(gg)});")
    T.append(f"  MainPipe_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # MainPipe 有 4 个互斥优先级输入源（probe > refill > store > atomic），各 valid 独立
    # 随机以覆盖仲裁。地址类（vaddr/addr）压窄高位以提高 set/tag 跨级命中（练命中/替换/写回路径）。
    # cmd 限制在有意义编码（store/AMO/LR/SC/CAS）。一致性 meta_resp/tag_resp 随机化但
    # 高 ECC 位置 0 避免大量随机 tag-error 噪声（仍能覆盖 hit/miss）。
    valid_rate = {
        "io_probe_req_valid":  "($urandom_range(0,4)==0)",   # 最高优先级，少发
        "io_refill_req_valid": "($urandom_range(0,3)==0)",
        "io_store_req_valid":  "($urandom_range(0,1))",      # 常发
        "io_atomic_req_valid": "($urandom_range(0,3)==0)",
        "io_refill_info_valid":"($urandom_range(0,1))",
        "io_pseudo_error_valid":"($urandom_range(0,7)==0)",
        # 下游 ready 大多为真（练流水推进），偶发 backpressure 练 stall
        "io_miss_req_ready":      "($urandom_range(0,3)!=0)",
        "io_wb_ready":            "($urandom_range(0,3)!=0)",
        "io_data_readline_ready": "($urandom_range(0,3)!=0)",
        "io_tag_read_ready":      "($urandom_range(0,4)!=0)",
        "io_wbq_block_miss_req":  "($urandom_range(0,4)==0)",
        "io_replace_block":       "($urandom_range(0,4)==0)",
        "io_invalid_resv_set":    "($urandom_range(0,7)==0)",
        "io_refill_req_bits_miss":"($urandom_range(0,1))",
    }
    # cmd 字段：从合法访存命令里挑（store=M_XWR, AMO/LR/SC/CAS）
    cmd_pick = "begin int c; c=$urandom_range(0,9); case(c) 0:{N}<=5'h01; 1:{N}<=5'h04; 2:{N}<=5'h08; 3:{N}<=5'h06; 4:{N}<=5'h07; 5:{N}<=5'h1A; 6:{N}<=5'h1B; 7:{N}<=5'h18; 8:{N}<=5'h0A; default:{N}<=5'h01; endcase end"

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n.endswith("_cmd"):
            return None  # 单独处理
        # source 字段限制 0..3
        if n.endswith("_source") and w == 4:
            return "4'($urandom_range(0,3))"
        # 地址类：压窄高位提高跨级 set/tag 命中
        if n.endswith("_vaddr") or n.endswith("_addr") or n == "io_replace_way_set_bits":
            return f"{{{w-8}'($urandom_range(0,3)), 8'($urandom)}}"
        # tag_resp：43 位，高 7 位（ECC）置 0 以减少随机 tag-error 噪声
        if n.startswith("io_tag_resp"):
            return "{7'h0, 36'($urandom_range(0,7))}"
        # meta coh：2 位随机
        if n.endswith("_coh_state"):
            return "2'($urandom)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_probe_req_valid", "io_refill_req_valid", "io_store_req_valid",
        "io_atomic_req_valid", "io_refill_info_valid", "io_pseudo_error_valid",
    ]
    in_names = {n for _, n in ins}
    cmd_names = [n for _, n in ins if n.endswith("_cmd")]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        if n in in_names:
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    for n in cmd_names:
        T.append("      " + cmd_pick.replace("{N}", n) + ";")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出（跳过 golden 为 X 的不可达态）
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
    print(f"MainPipe: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
