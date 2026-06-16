#!/usr/bin/env python3
"""
StoreMisalignBuffer：解析 golden 端口，生成 wrapper(golden 同名)、_xs 镜像、随机比对 tb。

golden 端口已是逐字段扁平形式（io_*），与可读核 xs_StoreMisalignBuffer_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核（u_core）。

设计意图来自 src/main/scala/xiangshan/mem/lsqueue/StoreMisalignBuffer.scala。
本脚本只做机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/StoreMisalignBuffer.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MOD = "StoreMisalignBuffer"
CORE = "xs_StoreMisalignBuffer_core"


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
    L.append(f"  {CORE} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports(MOD)
    hdr = "// 自动生成：scripts/gen_storemisalignbuffer.py —— 勿手改\n"

    (XSSV / f"rtl/memblock/{MOD}_wrapper.sv").write_text(hdr + emit(MOD, ps))
    ut = XSSV / f"verif/ut/{MOD}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit(f"{MOD}_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = [f"""// 自动生成：scripts/gen_storemisalignbuffer.py —— 勿手改
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
    T.append(f"  {MOD}    u_g ({', '.join(gg)});")
    T.append(f"  {MOD}_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 3 个 enq 口互斥优先级；地址压窄低 5 位以高频触发跨 16B 拆分；fuOpType 限制在
    # load 合法编码（0..6, 0x10..0x1E 区间）以走有意义的 size 分支；
    # splitLoadResp 的 rep/异常/uncache 偶发以覆盖各转移；vaddr 低位偏置非对齐。
    valid_rate = {
        "io_enq_0_req_valid": "($urandom_range(0,1))",
        "io_enq_1_req_valid": "($urandom_range(0,2)==0)",
        "io_redirect_valid":  "($urandom_range(0,15)==0)",
        "io_splitStoreReq_ready":  "($urandom_range(0,2)!=0)",
        "io_splitStoreResp_valid": "($urandom_range(0,2)!=0)",
        "io_splitStoreResp_bits_need_rep": "($urandom_range(0,4)==0)",
        "io_writeBack_ready":     "($urandom_range(0,2)!=0)",
        "io_storeOutValid":       "($urandom_range(0,7)==0)",
        "io_storeVecOutValid":    "($urandom_range(0,7)==0)",
        "io_rob_pendingst":       "($urandom_range(0,2)!=0)",
        "io_sqControl_toStoreMisalignBuffer_doDeq": "($urandom_range(0,2)!=0)",
        "io_enq_0_revoke":        "($urandom_range(0,7)==0)",
        "io_enq_1_revoke":        "($urandom_range(0,7)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n == "io_redirect_bits_level":
            return None
        # fuOpType：限制为 store 合法编码（低 2 位 size；高位覆盖 hsv）。
        if n.endswith("_uop_fuOpType"):
            return "{4'h0, 5'($urandom_range(0,24))}"
        # alignedType：限制 0..3（向量 size）。
        if n.endswith("_alignedType"):
            return "{1'b0, 2'($urandom)}"
        # 地址类：压窄高位，强随机低 13 位以触发跨 16B 与跨 4KB 分支。
        if n.endswith("_vaddr"):
            return f"{{{w-13}'($urandom_range(0,1)), 13'($urandom)}}"
        if n.endswith("_paddr"):
            return f"{{{w-5}'($urandom_range(0,3)), 5'($urandom)}}"
        # robIdx/pendingPtr：压窄以提高 robMatch 命中。
        if n.endswith("_robIdx_value") or n.endswith("_pendingPtr_value"):
            return "{4'h0, 4'($urandom)}"
        if "exceptionVec" in n:
            return "($urandom_range(0,7)==0)"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_enq_0_req_valid", "io_enq_1_req_valid",
        "io_redirect_valid", "io_splitStoreResp_valid",
    ]
    in_names = {n for _, n in ins}

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
    if "io_redirect_bits_level" in in_names:
        T.append("      io_redirect_bits_level <= $urandom_range(0,1);")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍比对所有输出（跳过 golden 为 X 的不可达态）。
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
    print(f"{MOD}: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
