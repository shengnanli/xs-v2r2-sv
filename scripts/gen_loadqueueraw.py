#!/usr/bin/env python3
"""
LoadQueueRAW：解析 golden 端口生成 wrapper(golden 同名 LoadQueueRAW)、_xs 镜像、
随机比对 tb。

golden 端口已是逐字段扁平形式（io_query_0_*, io_storeIn_1_*, io_rollback_*, ...），
与可读核 xs_LoadQueueRAW_core 的端口一一同名（核在内部用 always_comb 把扁平端口
聚合成数组处理），故 wrapper / _xs 只把端口透传给核（u_core），无打包/拆分逻辑。

设计意图来自 src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAW.scala。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/LoadQueueRAW.sv。
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
    L.append("  xs_LoadQueueRAW_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("LoadQueueRAW")
    hdr = "// 自动生成：scripts/gen_loadqueueraw.py —— 勿手改\n"

    (XSSV / "rtl/memblock/LoadQueueRAW_wrapper.sv").write_text(hdr + emit("LoadQueueRAW", ps))
    ut = XSSV / "verif/ut/LoadQueueRAW"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("LoadQueueRAW_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_loadqueueraw.py —— 勿手改
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
    T.append(f"  LoadQueueRAW    u_g ({', '.join(gg)});")
    T.append(f"  LoadQueueRAW_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # LoadQueueRAW 关键覆盖点：
    #  * query 入队（3 端口）：valid 常发；地址/mask 压窄高位以提高 store CAM 跨条目命中。
    #  * storeIn 写回（2 端口）：valid 常发；paddr/mask 同样压窄，制造与在队 load 的地址重叠。
    #  * sqIdx / robIdx / stAddrReadySqPtr / stIssuePtr：压窄到低几位，使
    #    isBefore/isAfter 年龄比较频繁翻转，覆盖入队条件、出队释放、违例年龄选择。
    #  * redirect：偶发冲刷，覆盖 cancelEnqueue / needCancel / selectOldest 的冲刷扣除。
    #  * revoke：偶发，覆盖入队后撤销释放。
    valid_rate = {
        "io_query_0_req_valid": "($urandom_range(0,1))",
        "io_query_1_req_valid": "($urandom_range(0,1))",
        "io_query_2_req_valid": "($urandom_range(0,1))",
        "io_storeIn_0_valid":   "($urandom_range(0,1))",
        "io_storeIn_1_valid":   "($urandom_range(0,1))",
        "io_redirect_valid":    "($urandom_range(0,15)==0)",
        "io_query_0_revoke":    "($urandom_range(0,7)==0)",
        "io_query_1_revoke":    "($urandom_range(0,7)==0)",
        "io_query_2_revoke":    "($urandom_range(0,7)==0)",
        "io_storeIn_0_bits_wlineflag": "($urandom_range(0,7)==0)",
        "io_storeIn_1_bits_wlineflag": "($urandom_range(0,7)==0)",
        "io_storeIn_0_bits_miss": "($urandom_range(0,3)==0)",
        "io_storeIn_1_bits_miss": "($urandom_range(0,3)==0)",
    }

    # 年龄 / 指针类：压窄到低位（高位置 0），让环形比较频繁翻转、命中入队/出队边界。
    narrow_robidx = {n for _, n in ins if n.endswith("_robIdx_value")}
    narrow_sqidx = {n for _, n in ins if n.endswith("_sqIdx_value") or n.endswith("SqPtr_value")}
    addr_sigs = {n for _, n in ins if n.endswith("_paddr")}
    mask_sigs = {n for _, n in ins if n.endswith("_mask")}

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n in narrow_robidx:
            return "{4'h0, 4'($urandom)}"        # robIdx 低 4 位随机
        # store 地址就绪/发射指针压得更窄（低 2 位），使其常落后于 load 的 sqIdx：
        #   更多在队 load 满足 isBefore(stAddrReadySqPtr, sqIdx) 而不可出队 → 队列堆积，
        #   正向覆盖 freelist 接近满 / lqFull 置位 与背压 ready=0 的路径。
        if n in ("io_stAddrReadySqPtr_value", "io_stIssuePtr_value"):
            return "{4'h0, 2'($urandom)}"
        if n in narrow_sqidx:
            return "{2'h0, 4'($urandom)}"        # load sqIdx 低 4 位随机（跨度更大）
        if n in addr_sigs:
            # paddr：压窄到低 10 位（覆盖 partial paddr 的 cacheline/VWord 段）
            return f"{{{w-10}'h0, 10'($urandom)}}"
        if n in mask_sigs:
            return f"{w}'($urandom)"             # 字节 mask 全随机（覆盖重叠/不重叠）
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_query_0_req_valid", "io_query_1_req_valid", "io_query_2_req_valid",
        "io_storeIn_0_valid", "io_storeIn_1_valid", "io_redirect_valid",
        "io_query_0_revoke", "io_query_1_revoke", "io_query_2_revoke",
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
    print(f"LoadQueueRAW: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
