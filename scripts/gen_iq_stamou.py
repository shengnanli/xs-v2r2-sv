#!/usr/bin/env python3
"""
IssueQueueStaMou(访存地址 IQ, StaMou 变体)生成器。

可读核手写在 rtl/backend/IssueQueueStaMou.sv(含顶层 wrapper), 类型/参数在
iq_stamou_pkg.sv。条目阵列 EntriesStaMou 及 3 个年龄检测器直接用 golden 黑盒例化
(IQ 核负责连线 + 访存胶合: mem feedback 折算、sqIdx/isFirstIssue 透传)。

本脚本只生成「flat golden 端口 ↔ 可读核」的穿透 svh + 双例化 tb:
  issuequeue_stamou_ports.svh   —— 顶层端口声明(去 clock/reset)
  issuequeue_stamou_connect.svh —— 例化可读核, 同名端口直连
  verif/ut/IssueQueueStaMou/iq_tb.sv         —— 双例化(u_g golden vs u_i 可读核)
  verif/ut/IssueQueueStaMou/iq_variant_xs.sv —— 顶层重命名 _xs 供 tb 与 golden 共存

设计意图来源: src/main/scala/xiangshan/backend/issue/IssueQueue.scala
            (class IssueQueueMemAddrImp)。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/IssueQueueStaMou"
GEN_HDR = "// 自动生成: scripts/gen_iq_stamou.py —— 勿手改\n"


def parse_ports(modname, fname):
    """返回有序 [(dir,width,name)], 去掉 clock/reset。"""
    text = (GOLDEN / fname).read_text()
    m = re.search(r"^module %s\(\n(.*?)\n\);" % modname, text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            w = int(pm.group(2)) + 1 if pm.group(2) else 1
            n = pm.group(3)
            if n in ("clock", "reset"):
                continue
            res.append((pm.group(1), w, n))
    return res


def decl(d, w, n, suffix=","):
    rng = f"[{w-1}:0] " if w > 1 else ""
    return f"  {d:<7}{rng}{n}{suffix}\n"


def emit_iq_svh():
    ports = parse_ports("IssueQueueStaMou", "IssueQueueStaMou.sv")
    p = [GEN_HDR.replace("\n", " (顶层端口) \n")]
    for d, w, n in ports:
        p.append(decl(d, w, n))
    p[-1] = p[-1].rstrip(",\n") + "\n"   # 最后一个端口去逗号
    (BK / "issuequeue_stamou_ports.svh").write_text("".join(p))

    c = [GEN_HDR.replace("\n", " (顶层连线) \n")]
    c.append("  // 顶层端口与可读核完全同名, 纯穿透例化。\n")
    c.append("  xs_IssueQueueStaMou_core u_core (\n")
    c.append("    .clock(clock), .reset(reset),\n")
    conn = [f"    .{n}({n})" for d, w, n in ports]
    c.append(",\n".join(conn))
    c.append("\n  );\n")
    (BK / "issuequeue_stamou_connect.svh").write_text("".join(c))
    print("wrote issuequeue_stamou_{ports,connect}.svh (ports=%d)" % len(ports))


def emit_iq_tb():
    ports = parse_ports("IssueQueueStaMou", "IssueQueueStaMou.sv")
    ins = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = []
    L.append("// 自动生成: scripts/gen_iq_stamou.py(iq tb)—— 勿手改\n")
    L.append("`timescale 1ns/1ps\nmodule tb;\n")
    L.append("  int unsigned NCYCLES = 200000;\n")
    L.append("  bit clk=0, rst; int errors=0, checks=0;\n")
    L.append("  bit no_flush;\n")
    L.append("  always #5 clk = ~clk;\n")
    for w, n in ins:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {rng}{n};\n")
    for w, n in outs:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {rng}g_{n};\n  wire {rng}i_{n};\n")

    def inst(mod, pfx):
        s = [f"  {mod} u_{pfx} (\n    .clock(clk), .reset(rst),\n"]
        conn = []
        for w, n in ins:
            conn.append(f"    .{n}({n})")
        for w, n in outs:
            conn.append(f"    .{n}({pfx}_{n})")
        s.append(",\n".join(conn))
        s.append("\n  );\n")
        return "".join(s)
    L.append(inst("IssueQueueStaMou", "g"))
    L.append(inst("IssueQueueStaMou_xs", "i"))

    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 适度降低各 valid/handshake 密度, 覆盖 enq/发射/背压/唤醒/mem feedback/重定向\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    # deq ready 偏高(让发射常被接受), 偶尔拉低制造背压
    L.append("    io_deqDelay_0_ready = ($urandom % 8 != 0);\n")
    # mem feedback 慢响应偶发, hit 偏多(放行多于阻塞)
    L.append("    io_memIO_feedbackIO_0_feedbackSlow_valid = ($urandom % 6 == 0);\n")
    L.append("    if (no_flush) io_flush_valid = 1'b0;\n")
    L.append("    else io_flush_valid = ($urandom % 16 == 0);\n")
    L.append("  endtask\n")

    L.append("  task check();\n")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;\n")
        L.append(f"      if(errors<=120) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end\n")
    L.append("    checks++;\n  endtask\n")
    L.append("""  initial begin
    no_flush = $test$plusargs("NO_FLUSH");
    rst = 1; drive_rand();
    repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) begin
      @(negedge clk); drive_rand();
      @(posedge clk); #1 check();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    UT.mkdir(parents=True, exist_ok=True)
    (UT / "iq_tb.sv").write_text("".join(L))
    print("wrote iq_tb.sv (ins=%d outs=%d)" % (len(ins), len(outs)))


def emit_iq_xs_variant():
    """顶层重命名 IssueQueueStaMou_xs 供 tb 与 golden 共存。
    核 xs_IssueQueueStaMou_core 在 IssueQueueStaMou.sv 里定义一次, g/i 两侧共用。"""
    L = [GEN_HDR.replace("\n", " (顶层 _xs 变体) \n")]
    L.append("module IssueQueueStaMou_xs (\n")
    L.append("  input  clock,\n  input  reset,\n")
    L.append('`include "issuequeue_stamou_ports.svh"\n')
    L.append(");\n")
    L.append('`include "issuequeue_stamou_connect.svh"\n')
    L.append("endmodule\n")
    (UT / "iq_variant_xs.sv").write_text("".join(L))
    print("wrote iq_variant_xs.sv")


if __name__ == "__main__":
    emit_iq_svh()
    emit_iq_tb()
    emit_iq_xs_variant()
