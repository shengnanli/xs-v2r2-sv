#!/usr/bin/env python3
"""
LsqWrapper 生成器。

LsqWrapper 的可读核 xs_LsqWrapper_core 例化 LoadQueue + StoreQueue 两个 golden 子模块
（与 golden 完全一致），并在其上手写**包装级控制逻辑**（入队拆分 / canAccept /
非缓存仲裁 FSM / 异常地址选择 / perf 打拍）。

绝大多数子模块端口是“顶层端口 <-> 子模块端口”的直通连接；只有少数端口被包装级
逻辑接管（enq、uncache、exceptionAddr、perf、canAccept、SQ→LQ 就绪向量）。

本脚本：
  1. 从 golden/chisel-rtl/LsqWrapper.sv 解析两个子模块实例的端口连接表，
     把“被逻辑接管”的连接改接到可读核里手写的 readable 信号，其余直通照搬，
     生成 rtl/memblock/LsqWrapper_inst.svh（被可读核 include）。
  2. 生成 golden 同名 wrapper（FM/ST 用）与 _xs 镜像、随机比对 tb（UT 用）。

可读核本体（手写）见 rtl/memblock/LsqWrapper.sv，公共类型见 lsq_pkg.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "LsqWrapper.sv").read_text()
LINES = GSV.splitlines()


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module LsqWrapper\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


# ----------------------------------------------------------------------------
# 实例连接表解析：返回 [(port, value_expr), ...]
# ----------------------------------------------------------------------------
def inst_conns(head_re):
    start = next(i for i, l in enumerate(LINES) if re.match(head_re, l))
    i = start + 1
    raw = []
    while not re.match(r"^   \);|^  \);", LINES[i]):
        raw.append(LINES[i])
        i += 1
    res, cur = [], None
    for l in raw:
        m = re.match(r"^\s*\.(\w+)\s*(.*)$", l)
        if m and (m.group(2).strip() == "" or m.group(2).strip().startswith("(")):
            if cur:
                res.append(cur)
            cur = [m.group(1), m.group(2).strip()]
        else:
            cur[1] += " " + l.strip()
    if cur:
        res.append(cur)
    return [(p, re.sub(r"\s+", " ", v).strip().rstrip(",")) for p, v in res]


def unwrap(v):
    v = v.strip()
    if v.startswith("(") and v.endswith(")"):
        return v[1:-1].strip()
    return v


# ----------------------------------------------------------------------------
# 把一条子模块连接重写为可读核内部信号（who in {"lq","sq"}）。
# 返回 None 表示按 golden 原样直通（顶层端口直连）。
# ----------------------------------------------------------------------------
def rewrite(who, port, val):
    v = unwrap(val)

    # --- 入队拆分：needAlloc 取对应 bit、valid 与 needAlloc 相与 ---
    m = re.match(r"^io_enq_needAlloc_(\d+)$", port)
    if m:
        return f"{who}_enq_need[{m.group(1)}]"
    m = re.match(r"^io_enq_req_(\d+)_valid$", port)
    if m and ("io_enq_needAlloc" in v and "&" in v):
        return f"{who}_enq_fire[{m.group(1)}]"

    # --- canAccept 双向联立 ---
    if port == "io_enq_canAccept":
        return "lq_can_accept" if who == "lq" else "sq_can_accept"
    if port == "io_enq_sqCanAccept":   # LoadQueue 看 StoreQueue 能否收
        return "sq_can_accept"
    if port == "io_enq_lqCanAccept":   # StoreQueue 看 LoadQueue 能否收
        return "lq_can_accept"

    # --- StoreQueue → LoadQueue 的地址/数据就绪互联（仅内部，不出顶层）---
    #     Vec 类做成 packed 向量、用下标连接；指针/标志保持子字段名。
    def sq2lq(field):
        m2 = re.match(r"^(stAddrReadyVec|stDataReadyVec)_(\d+)$", field)
        if m2:
            return f"sq2lq_{m2.group(1)}[{m2.group(2)}]"
        return "sq2lq_" + field
    if who == "lq":
        m = re.match(r"^io_sq_(\w+)$", port)
        if m:
            return sq2lq(m.group(1))
    if who == "sq":
        if port.startswith("io_stAddrReadyVec_") or port.startswith("io_stDataReadyVec_") \
           or port.startswith("io_stAddrReadySqPtr_") or port.startswith("io_stDataReadySqPtr_") \
           or port.startswith("io_stIssuePtr_"):
            return sq2lq(port[len("io_"):])

    # --- uncache：核内 readable 输出网 + 由 FSM 驱动的输入 ---
    if port == "io_uncache_req_ready":
        return f"{who}_unc_req_ready"
    if port.startswith("io_uncache_req_"):
        return f"{who}_unc_" + port[len("io_uncache_"):]
    if port == "io_uncache_resp_valid":
        return f"{who}_unc_resp_valid"
    if port == "io_uncache_idResp_valid":
        return f"{who}_unc_idResp_valid"

    # --- exceptionAddr：核内 readable 输出网 ---
    if port.startswith("io_exceptionAddr_"):
        return f"{who}_exc_" + port[len("io_exceptionAddr_"):]

    # --- sqEmpty 既给 LQ 也出顶层；这里子模块输出接核内网 ---
    if who == "sq" and port == "io_sqEmpty":
        return "sq2lq_sqEmpty"   # 顶层 io_sqEmpty 在核里另接

    # --- nack_rollback：golden 经内部 wire（兼作 _probe）再到顶层；直接接顶层端口 ---
    if who == "lq" and port == "io_nack_rollback_0_valid":
        return "io_nack_rollback_0_valid"

    # --- perf：核内 readable 输出网，供打拍 ---
    m = re.match(r"^io_perf_(\d+)_value$", port)
    if m:
        return f"{who}_perf[{m.group(1)}]"

    return None  # 直通


def emit_inst(modname, instname, head_re, who):
    conns = inst_conns(head_re)
    out = [f"  {modname} {instname} ("]
    body = []
    for port, val in conns:
        if port in ("clock", "reset"):
            body.append(f"    .{port}({port})")
            continue
        rw = rewrite(who, port, val)
        if rw is None:
            # 直通：连到顶层同名端口（val 去括号即顶层端口名/表达式）
            body.append(f"    .{port}({unwrap(val)})")
        else:
            body.append(f"    .{port}({rw})")
    out.append(",\n".join(body))
    out.append("  );")
    return "\n".join(out)


# ----------------------------------------------------------------------------
# 生成可读核 include 文件（两个子模块实例 + 内部网声明）
# ----------------------------------------------------------------------------
def gen_inst_svh():
    lq = emit_inst("LoadQueue", "u_load_queue",
                   r"^  LoadQueue loadQueue \(", "lq")
    sq = emit_inst("StoreQueue", "u_store_queue",
                   r"^  StoreQueue storeQueue \(", "sq")
    hdr = ("// 自动生成：scripts/gen_lsqwrapper.py —— 勿手改\n"
           "// 由 xs_LsqWrapper_core 通过 `include 引入：LoadQueue / StoreQueue 两实例的\n"
           "// 端口连接表。直通端口连顶层同名口；被包装级逻辑接管的端口连核内 readable 网。\n\n")
    (XSSV / "rtl/memblock/LsqWrapper_inst.svh").write_text(hdr + lq + "\n\n" + sq + "\n")
    return lq, sq


# ----------------------------------------------------------------------------
# wrapper / _xs / tb
# ----------------------------------------------------------------------------
def emit_flat_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_LsqWrapper_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    in_names = {n for _, n in ins}

    T = ["""// 自动生成：scripts/gen_lsqwrapper.py —— 勿手改
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
    T.append(f"  LsqWrapper    u_g ({', '.join(gg)});")
    T.append(f"  LsqWrapper_xs u_i ({', '.join(ig)});")

    # 随机激励：valid 类信号分别给合适的发生率以覆盖各路握手；地址/数据全随机；
    # uncache resp/idResp 的 is2lq 随机以覆盖 Load/Store 两条回送路径；needAlloc
    # 用 2 bit 随机以触发 enq 拆分。
    valid_rate = {
        "io_brqRedirect_valid":     "($urandom_range(0,15)==0)",
        "io_uncache_req_ready":     "($urandom_range(0,1))",
        "io_uncache_resp_valid":    "($urandom_range(0,3)==0)",
        "io_uncache_idResp_valid":  "($urandom_range(0,3)==0)",
        "io_uncache_resp_bits_is2lq":   "($urandom_range(0,1))",
        "io_uncache_idResp_bits_is2lq": "($urandom_range(0,1))",
        "io_exceptionAddr_isStore": "($urandom_range(0,1))",
        "io_uncacheOutstanding":    "($urandom_range(0,3)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        # 各类 *_valid / *_ready / *_fire 默认中等发生率，覆盖握手
        if n.endswith("_valid") or n.endswith("_ready") or n.endswith("_fire") \
           or n.endswith("_canAccept"):
            return "$urandom_range(0,1)"
        if n.startswith("io_enq_needAlloc"):
            return "2'($urandom)"  # 2 bit：bit0→LQ, bit1→SQ
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 逐拍比对所有输出（跳过 golden 为 X 的不可达态——子模块大量无复位寄存器）
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def gen_ports_svh(ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    hdr = ("// 自动生成：scripts/gen_lsqwrapper.py —— 勿手改\n"
           "// 可读核 xs_LsqWrapper_core 的端口列表（与 golden LsqWrapper 同名扁平端口）。\n")
    (XSSV / "rtl/memblock/LsqWrapper_ports.svh").write_text(hdr + ",\n".join(decls) + "\n")


def gen_perf_out_svh():
    L = ["// 自动生成：scripts/gen_lsqwrapper.py —— 勿手改",
         "// 36 路性能计数器打两拍后接出顶层端口。"]
    for i in range(36):
        L.append(f"  assign io_perf_{i}_value = perf_stage2[{i}];")
    (XSSV / "rtl/memblock/LsqWrapper_perf_out.svh").write_text("\n".join(L) + "\n")


def main():
    ps = top_ports()
    hdr = "// 自动生成：scripts/gen_lsqwrapper.py —— 勿手改\n"
    gen_inst_svh()
    gen_ports_svh(ps)
    gen_perf_out_svh()
    (XSSV / "rtl/memblock/LsqWrapper_wrapper.sv").write_text(hdr + emit_flat_wrapper("LsqWrapper", ps))
    ut = XSSV / "verif/ut/LsqWrapper"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_flat_wrapper("LsqWrapper_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))
    ins = sum(1 for d, _, _ in ps if d == "input")
    outs = sum(1 for d, _, _ in ps if d == "output")
    print(f"LsqWrapper: {len(ps)} ports ({ins} in / {outs} out)")


if __name__ == "__main__":
    main()
