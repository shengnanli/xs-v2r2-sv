#!/usr/bin/env python3
"""生成 Arbiter4_MainPipeReq 的双例化 UT testbench（tb.sv）。

读 G1 golden 端口表，golden Arbiter4_MainPipeReq 与重写件 Arbiter4_MainPipeReq_xs
（ut_common 派生改名）同激励并跑，每拍逐位比较**全部**输出端口。

激励：四路 valid 位图按"全 0 / 单热 / 稀疏 / 全随机"混合（让每一路都有机会胜出，
也覆盖"一路都没请求"时输出兜底取第 3 路载荷的情形）；载荷逐位随机；
out_ready 一半概率为 0。
覆盖闸：每一路单独胜出 >= COV_MIN、无人请求 >= COV_MIN、out_ready=0 >= COV_MIN、
每个输出位都观察到过 0 和 1；任何一项不足即 TEST FAILED。

用法：python3 gen.py          生成/刷新 tb.sv（内容不变不写，幂等）
      python3 gen.py --check  只比较，不一致则 rc=1
"""
import os, re, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
TOP = "Arbiter4_MainPipeReq"
PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def ports():
    txt = open(f"{G}/{TOP}.sv").read()
    body = txt[txt.index(f"\nmodule {TOP}(") + 1:]
    head = body[:body.index("\n);")]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4)))
    return out


def rng(w):
    return f"[{w-1}:0] " if w > 1 else ""


def rand_expr(w):
    n = (w + 31) // 32
    if n == 1:
        return f"{w}'($urandom)"
    return f"{w}'({{" + ", ".join(["$urandom"] * n) + "})"


def gen():
    ps = ports()
    ins = [p for p in ps if p[0] == "input"]
    outs = [p for p in ps if p[0] == "output"]
    L = []
    L.append(f"// 自动生成：verif/ut/{TOP}/gen.py（读 G1 golden 端口表）—— 勿手改")
    L.append(f"// {TOP} 双例化逐拍比对：golden {TOP} vs {TOP}_xs（xs_FixedPriorityArbiter_core）。")
    L.append("// 激励：四路 valid 位图混合全 0/单热/稀疏/全随机，载荷逐位随机，out_ready 半数为 0。")
    L.append("// 覆盖闸：每一路单独胜出、无人请求、out_ready=0 各 >= COV_MIN；每个输出位见过 0 和 1。")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  localparam int COV_MIN = 1000;")
    L.append("  int errors = 0, checks = 0, cov_fail = 0;")
    L.append("  int win [4];")
    L.append("  int none_cnt = 0, stall_cnt = 0;")
    L.append("")
    L.append("  // ---- 输入（两侧共用）----")
    for _, w, n in ins:
        L.append(f"  logic {rng(w)}{n};")
    L.append("  // ---- 输出（g_ = golden，i_ = 重写）----")
    for _, w, n in outs:
        L.append(f"  wire  {rng(w)}g_{n}, i_{n};")
        L.append(f"  logic {rng(w)}seen1_{n}, seen0_{n};")
    L.append("")
    for inst, pre, mod in (("u_gold", "g_", TOP), ("u_impl", "i_", TOP + "_xs")):
        L.append(f"  {mod} {inst} (")
        conns = []
        for d, w, n in ps:
            conns.append(f"    .{n}({n if d == 'input' else pre + n})")
        L.append(",\n".join(conns))
        L.append("  );")
    L.append("")
    L.append("  task automatic drive();")
    L.append("    int mode = $urandom_range(0, 3);")
    L.append("    logic [3:0] v;")
    L.append("    case (mode)")
    L.append("      0: v = 4'b0000;")
    L.append("      1: v = 4'b0001 << $urandom_range(0, 3);")
    L.append("      2: v = 4'($urandom) & 4'($urandom);")
    L.append("      default: v = 4'($urandom);")
    L.append("    endcase")
    L.append("    {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid} = v;")
    for _, w, n in ins:
        if n.endswith("_valid"):
            continue
        L.append(f"    {n} = {rand_expr(w)};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic compare();")
    for _, w, n in outs:
        L.append(f"    if (g_{n} !== i_{n}) begin")
        L.append(f"      errors++;")
        L.append(f"      if (errors <= 20) $display(\"MISMATCH cyc=%0d {n}: g=%h i=%h\", checks, g_{n}, i_{n});")
        L.append(f"    end")
        L.append(f"    seen1_{n} |= g_{n};")
        L.append(f"    seen0_{n} |= ~g_{n};")
    L.append("    checks++;")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"ncycles=%d\", NCYCLES)) ;")
    for _, w, n in outs:
        L.append(f"    seen1_{n} = '0; seen0_{n} = '0;")
    L.append("    for (int c = 0; c < NCYCLES; c++) begin")
    L.append("      drive();")
    L.append("      #1;")
    L.append("      compare();")
    L.append("      if (io_in_0_valid) win[0]++;")
    L.append("      else if (io_in_1_valid) win[1]++;")
    L.append("      else if (io_in_2_valid) win[2]++;")
    L.append("      else if (io_in_3_valid) win[3]++;")
    L.append("      else none_cnt++;")
    L.append("      if (!io_out_ready) stall_cnt++;")
    L.append("      #9;")
    L.append("    end")
    L.append("    $display(\"COVERAGE win_probe=%0d win_refill=%0d win_store=%0d win_atomic=%0d none=%0d out_ready0=%0d\",")
    L.append("             win[0], win[1], win[2], win[3], none_cnt, stall_cnt);")
    L.append("    for (int k = 0; k < 4; k++) if (win[k] < COV_MIN) begin cov_fail++; $display(\"COV FAIL: way %0d wins %0d\", k, win[k]); end")
    L.append("    if (none_cnt < COV_MIN) begin cov_fail++; $display(\"COV FAIL: none\"); end")
    L.append("    if (stall_cnt < COV_MIN) begin cov_fail++; $display(\"COV FAIL: out_ready=0\"); end")
    for _, w, n in outs:
        L.append(f"    if (~seen1_{n} != '0 || ~seen0_{n} != '0) begin cov_fail++; $display(\"COV FAIL: {n} 有位没翻转过 1=%h 0=%h\", seen1_{n}, seen0_{n}); end")
    L.append("    $display(\"checks=%0d errors=%0d cov_fail=%0d\", checks, errors, cov_fail);")
    L.append("    if (errors == 0 && cov_fail == 0) $display(\"TEST PASSED\");")
    L.append("    else $display(\"TEST FAILED\");")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def main():
    txt = gen()
    path = os.path.join(HERE, "tb.sv")
    old = open(path).read() if os.path.exists(path) else None
    if "--check" in sys.argv:
        if old != txt:
            print(f"GEN CHECK FAILED: {path} 与生成器输出不一致")
            sys.exit(1)
        print("GEN CHECK OK")
        return
    if old != txt:
        open(path, "w").write(txt)
        print(f"wrote {path}")
    else:
        print("unchanged")


if __name__ == "__main__":
    main()
