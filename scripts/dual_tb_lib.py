#!/usr/bin/env python3
"""dual_tb_lib.py —— 双例化 UT testbench 的公共生成库（dcache lane 起用）。

不是生成器本身（没有 main），被各 UT 目录的 gen.py import。一个 tb 里可以放多对
"golden <Top> vs 重写 <Top>_xs"，每对：
  * 端口表从 G1 golden 现读（只认 `input|output [hi:lo] name` 平铺端口，解析不了即失败）；
  * 每拍在 negedge 给全部输入灌随机值（位宽 > 32 的拼 $urandom），pair 可附一段 SV
    覆写部分输入（偏置激励）；
  * 在下一个 posedge 前 1ns 逐位比较全部输出（`!==`，X 也算失配）；
  * 覆盖闸：每个输出位都见过 0 和 1（可列豁免），外加 pair 自带的计数表达式
    （每项 >= cov_min，否则 TEST FAILED）。
带时钟的 pair 有 clock/reset：前 RESET_CYC 拍拉 reset，之后按 1/reset_period 概率
再打一拍 reset（异步复位路径也要走到）；reset_period=0 表示只打上电复位。

用法（gen.py 里）：
    from dual_tb_lib import Pair, render, write_or_check
    txt = render([Pair(...), ...], header="...")
    sys.exit(write_or_check(path, txt, check='--check' in sys.argv))
"""
import os
import re

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def golden_ports(top):
    txt = open(f"{G}/{top}.sv").read()
    key = f"\nmodule {top}("
    if key not in txt:
        raise SystemExit(f"golden {top}.sv 里找不到 module {top}(")
    body = txt[txt.index(key) + 1:]
    head = body[:body.index("\n);")]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{top}: 端口行解析失败: {ln!r}")
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


class Pair(object):
    """一对双例化。

    top        golden 顶层名（impl 为 <top>_xs）
    pfx        本对信号前缀（tb 内唯一）
    clocked    有 clock/reset 端口
    stim       SV 代码，每拍默认随机之后执行，可引用 <pfx><端口名> 与 cyc / <pfx>mode
    cov        [(名字, SV 布尔表达式)]，每拍比较窗口内为真则计数，要求 >= cov_min
               表达式里 `@name` 替换为 golden 侧信号（输入即输入，输出为 g_ 侧）
    exempt     不要求见过 0/1 的输出位 ["端口名"] 或 ["端口名[3]"]
    warmup     开始比较前的拍数（不复位寄存器需要被写满时用）
    arm        [SV 布尔表达式]：每一项都至少为真过一次（粘滞）之后才开始比较——
               给"不复位的数据寄存器要先被写过一次，两侧初值才一致"的情形用；
               表达式同 cov 的 @ 替换规则。arm 之前的拍数会打印出来。
    arm_delay  全部 arm 条件满足之后再多等几拍才开始比（读出数据还要过一级锁存的情形）
    has_reset  clocked=True 时 golden 是否有 reset 端口（默认 True）。False 给"只有 clock、
               寄存器全不复位"的模块用（如 NewCSR 的 Debug）：clock 仍接 tb 的 clk，
               不驱动 reset；不复位寄存器靠 warmup/arm 冲刷。
    mode_period 每隔多少拍重抽一次 <pfx>mode（0..15），供 stim 做分阶段偏置
    decls      模块级 SV 声明（stim 要用的辅助 function / 变量），原样放进 tb 模块体
    """

    def __init__(self, top, pfx, clocked=False, stim="", cov=(), exempt=(),
                 warmup=0, mode_period=4000, reset_period=40000, cov_min=100, arm=(),
                 decls="", arm_delay=0, has_reset=True):
        self.top = top
        self.pfx = pfx
        self.clocked = clocked
        self.stim = stim
        self.cov = list(cov)
        self.exempt = set(exempt)
        self.warmup = warmup
        self.mode_period = mode_period
        self.reset_period = reset_period
        self.cov_min = cov_min
        self.arm = list(arm)
        self.decls = decls
        self.arm_delay = arm_delay
        self.has_reset = has_reset
        self.ports = golden_ports(top)
        names = [n for _, _, n in self.ports]
        if clocked and ("clock" not in names or (has_reset and "reset" not in names)):
            raise SystemExit(f"{top}: clocked=True 但 golden 无 clock/reset 端口")
        if clocked and not has_reset and "reset" in names:
            raise SystemExit(f"{top}: has_reset=False 但 golden 有 reset 端口")

    def subst(self, expr):
        outs = {n for d, _, n in self.ports if d == "output"}

        def rep(m):
            n = m.group(1)
            return f"{self.pfx}g_{n}" if n in outs else f"{self.pfx}{n}"
        return re.sub(r'@(\w+)', rep, expr)


def render(pairs, header, ncycles=200000):
    P = pairs
    L = []
    for h in header.strip().splitlines():
        L.append("// " + h if h else "//")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append(f"  int unsigned NCYCLES = {ncycles};")
    L.append("  int errors = 0, checks = 0, cov_fail = 0;")
    L.append("  int unsigned cyc = 0;")
    L.append("  logic clk = 1'b0;")
    L.append("  always #5 clk = ~clk;")
    L.append("  localparam int RESET_CYC = 8;")
    for p in P:
        x = p.pfx
        L.append("")
        L.append(f"  // ================= {p.top} =================")
        L.append(f"  int unsigned {x}mode = 0;")
        for d in p.decls.strip().splitlines():
            L.append("  " + d)
        for d, w, n in p.ports:
            if d == "input":
                if p.clocked and n == "clock":
                    continue
                L.append(f"  logic {rng(w)}{x}{n};")
            else:
                L.append(f"  wire  {rng(w)}{x}g_{n}, {x}i_{n};")
                L.append(f"  logic {rng(w)}{x}s0_{n} = '0, {x}s1_{n} = '0;")
        for cn, _ in p.cov:
            L.append(f"  int {x}cov_{cn} = 0;")
        L.append(f"  logic [{max(len(p.arm), 1) - 1}:0] {x}armed = '0;")
        L.append(f"  int {x}armed_at = -1;")
        for inst, pre, mod in (("u_gold", "g_", p.top), ("u_impl", "i_", p.top + "_xs")):
            L.append(f"  {mod} {x}{inst} (")
            conns = []
            for d, w, n in p.ports:
                if d == "input":
                    sig = "clk" if (p.clocked and n == "clock") else f"{x}{n}"
                else:
                    sig = f"{x}{pre}{n}"
                conns.append(f"    .{n}({sig})")
            if conns:
                L.append(",\n".join(conns))
            L.append("  );")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"ncycles=%d\", NCYCLES)) ;")
    L.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    L.append("      @(negedge clk);")
    for p in P:
        x = p.pfx
        L.append(f"      if (cyc % {p.mode_period} == 0) {x}mode = $urandom_range(0, 15);")
        for d, w, n in p.ports:
            if d != "input" or (p.clocked and n in ("clock", "reset")):
                continue
            L.append(f"      {x}{n} = {rand_expr(w)};")
        if p.clocked and not p.has_reset:
            pass
        elif p.clocked and p.reset_period:
            L.append(f"      {x}reset = (cyc < RESET_CYC) || ($urandom_range(0, {p.reset_period - 1}) == 0);")
        elif p.clocked:
            L.append(f"      {x}reset = (cyc < RESET_CYC);")
        if p.stim.strip():
            L.append(f"      begin : stim_{x.rstrip('_')}")
            for s in p.subst(p.stim).strip().splitlines():
                L.append("        " + s)
            L.append("      end")
    L.append("      #4;")
    for p in P:
        x = p.pfx
        outs = [(w, n) for d, w, n in p.ports if d == "output"]
        if not p.arm:
            L.append(f"      {x}armed = 1'b1;")
        if p.arm_delay:
            L.append(f"      if (cyc >= RESET_CYC + {p.warmup} && {x}armed_at >= 0 && cyc >= {x}armed_at) begin")
        else:
            L.append(f"      if (cyc >= RESET_CYC + {p.warmup} && (&{x}armed)) begin")
        for w, n in outs:
            L.append(f"        checks++;")
            L.append(f"        if ({x}g_{n} !== {x}i_{n}) begin")
            L.append(f"          errors++;")
            L.append(f"          if (errors <= 20) $display(\"[MISMATCH] cyc=%0d {p.top}.{n} g=%h i=%h\", cyc, {x}g_{n}, {x}i_{n});")
            L.append(f"        end")
            L.append(f"        {x}s1_{n} |= {x}g_{n};")
            L.append(f"        {x}s0_{n} |= ~{x}g_{n};")
        for cn, ce in p.cov:
            L.append(f"        if ({p.subst(ce)}) {x}cov_{cn}++;")
        L.append("      end")
        # arm 在比较之后更新：本拍发生的写入要到下一个 posedge 才进寄存器
        for k, a in enumerate(p.arm):
            L.append(f"      if ({p.subst(a)}) {x}armed[{k}] = 1'b1;")
        dly = f" + {p.arm_delay}" if p.arm_delay else ""
        L.append(f"      if ({x}armed_at < 0 && (&{x}armed)) {x}armed_at = cyc + 1{dly};")
    L.append("    end")
    L.append("")
    L.append("    // ---- 覆盖闸 ----")
    for p in P:
        x = p.pfx
        for d, w, n in p.ports:
            if d != "output":
                continue
            for b in range(w):
                tag = n if w == 1 else f"{n}[{b}]"
                if n in p.exempt or tag in p.exempt:
                    continue
                sel = "" if w == 1 else f"[{b}]"
                L.append(f"    if (!({x}s0_{n}{sel} && {x}s1_{n}{sel})) begin cov_fail++; "
                         f"$display(\"[COV] {p.top}.{tag} 未见过 0 和 1\"); end")
        L.append(f"    $display(\"[ARM] {p.top} armed_at=%0d\", {x}armed_at);")
        L.append(f"    if ({x}armed_at < 0) begin cov_fail++; $display(\"[ARM] {p.top} 从未 arm\"); end")
        for cn, _ in p.cov:
            L.append(f"    $display(\"[COV] {p.top}.{cn} = %0d\", {x}cov_{cn});")
            L.append(f"    if ({x}cov_{cn} < {p.cov_min}) begin cov_fail++; "
                     f"$display(\"[COV] {p.top}.{cn} < {p.cov_min}\"); end")
    L.append("    $display(\"checks=%0d errors=%0d cov_fail=%0d\", checks, errors, cov_fail);")
    L.append("    if (errors == 0 && cov_fail == 0 && checks > 0) $display(\"TEST PASSED\");")
    L.append("    else $display(\"TEST FAILED\");")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def write_or_check(path, txt, check):
    old = open(path).read() if os.path.exists(path) else None
    if check:
        if old != txt:
            print(f"[gencheck] {path} 与生成结果不一致（请跑 gen.py 刷新）")
            return 1
        print(f"[gencheck] {path} OK")
        return 0
    if old != txt:
        with open(path, "w") as f:
            f.write(txt)
        print(f"wrote {path}")
    else:
        print(f"unchanged {path}")
    return 0
