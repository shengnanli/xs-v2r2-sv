#!/usr/bin/env python3
"""
PTWRepeaterNB：生成 golden 同名 wrapper（FM 用）+ _xs 镜像（UT 用）+ 随机比对 tb。

wrapper 例化 golden 黑盒 DelayN_1（sfence/csr 变更 2 拍延迟 → flush）+ 可读核
  xs_PTWRepeaterNB_core（全部逻辑）。DelayN_1 两侧同源 elaborate（纯逻辑移位链，非黑盒）。

设计意图: src/main/scala/xiangshan/cache/mmu/Repeater.scala class PTWRepeaterNB。
本脚本只做机械端口透传 + DelayN 例化 + tb，可读核本体见 rtl/memblock/PTWRepeaterNB.sv。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = Path("/home/eda/xs-env/G0-canonical/golden-rtl")


def golden_ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def build_wrapper(modname, core_inst):
    ps = golden_ports("PTWRepeaterNB")
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    # 核端口 = golden 端口 - {clock,reset,4个csr/sfence标量} + {clock,reset,io_flush}
    #   然后其余端口逐一同名透传（golden 与核端口名一致）。
    core_ports = [n for _, _, n in ps
                  if n not in ("clock", "reset", "io_sfence_valid",
                               "io_csr_satp_changed", "io_csr_vsatp_changed",
                               "io_csr_hgatp_changed")]
    conn = [".clock(clock)", ".reset(reset)", ".io_flush(flush)"] + \
           [f".{n}({n})" for n in core_ports]
    L = []
    L.append("// 自动生成：scripts/gen_ptwrepeaternb.py —— 勿手改")
    L.append(f"module {modname} import xs_ptwrepeaternb_pkg::*; (")
    L.append(",\n".join(decls))
    L.append(");")
    L.append("  // DelayN_1 黑盒：sfence/csr 变更延迟 2 拍产生 flush（两侧同源 elaborate）")
    L.append("  wire flush;")
    L.append("  DelayN_1 delay (.clock(clock),")
    L.append("    .io_in(io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed | io_csr_hgatp_changed),")
    L.append("    .io_out(flush));")
    L.append(f"  {core_inst} u_core (")
    L.append("    " + ",\n    ".join(conn))
    L.append("  );")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def build_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_ptwrepeaternb.py —— 勿手改",
         "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk=0, rst; int errors=0, checks=0;",
         "  always #5 clk = ~clk;"]
    for w, n in ins:
        T.append(f"  logic {('['+str(w-1)+':0] ') if w>1 else ''}{n};")
    for w, n in outs:
        ws = ('['+str(w-1)+':0] ') if w > 1 else ''
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  PTWRepeaterNB    u_g ({', '.join(gg)});")
    T.append(f"  PTWRepeaterNB_xs u_i ({', '.join(ig)});")

    valid_rate = {
        "io_tlb_req_0_valid":  "($urandom_range(0,1))",
        "io_tlb_resp_ready":   "($urandom_range(0,1))",
        "io_ptw_req_0_ready":  "($urandom_range(0,1))",
        "io_ptw_resp_valid":   "($urandom_range(0,2)==0)",
        "io_sfence_valid":     "($urandom_range(0,63)==0)",
        "io_csr_satp_changed": "($urandom_range(0,63)==0)",
        "io_csr_vsatp_changed":"($urandom_range(0,63)==0)",
        "io_csr_hgatp_changed":"($urandom_range(0,63)==0)",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    in_names = {n for _, n in ins}
    reset_valids = [n for n in valid_rate if n in in_names]
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
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
    return "\n".join(T)


def main():
    ps = golden_ports("PTWRepeaterNB")
    (XSSV / "rtl/memblock/PTWRepeaterNB_wrapper.sv").write_text(
        build_wrapper("PTWRepeaterNB", "xs_PTWRepeaterNB_core"))
    ut = XSSV / "verif/ut/PTWRepeaterNB"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(build_wrapper("PTWRepeaterNB_xs", "xs_PTWRepeaterNB_core"))
    (ut / "tb.sv").write_text(build_tb(ps))
    print(f"PTWRepeaterNB: {len(ps)} golden ports")


if __name__ == "__main__":
    main()
