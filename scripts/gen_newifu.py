#!/usr/bin/env python3
"""
NewIFU 验证脚手架生成器。

NewIFU 端口已是逐字段扁平形式（io_*），手写核 xs_NewIFU_core 端口与其一一同名，
故 wrapper / _xs 只是把端口透传给核 u_core，无打包/拆分逻辑。寄存器名亦沿用 golden，
Formality 按名 / 展平规则即可匹配，无需 fm_map。

NewIFU 例化 5 类子模块：PreDecode / PredChecker / FrontendTrigger / F3Predecoder /
RVCExpander（x17）。手写核直接按 golden 同名例化这些子模块；UT/FM 两侧都带上这些
golden 子模块文件（见 Makefile GOLDEN_SRCS / FM_REF_DEPS / WRAPPER 侧 RTL_SRCS），
两侧子模块网表一致，FM 逐层比对即匹配。

产物：
  rtl/frontend/NewIFU_wrapper.sv      模块名 NewIFU（golden 同名），透传到 u_core
  verif/ut/NewIFU/variants_xs.sv      模块名 NewIFU_xs，透传到 u_core
  verif/ut/NewIFU/tb.sv               golden NewIFU vs NewIFU_xs 双例化逐拍比对
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


def emit(modname, ps, core="xs_NewIFU_core"):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append(f"  {core} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("NewIFU")
    hdr = "// 自动生成：scripts/gen_newifu.py —— 勿手改\n"

    (XSSV / "rtl/frontend/NewIFU_wrapper.sv").write_text(hdr + emit("NewIFU", ps))
    ut = XSSV / "verif/ut/NewIFU"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("NewIFU_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    # 握手 / 控制类输入：复位清 0，跑起来后用偏置随机制造背压前压
    ready_like = {
        "io_ftqInter_fromFtq_req_valid", "io_icacheInter_resp_valid",
        "io_icacheInter_icacheReady", "io_toIbuffer_ready", "io_iTLBInter_req_ready",
        "io_iTLBInter_resp_valid", "io_uncacheInter_fromUncache_valid",
        "io_uncacheInter_toUncache_ready", "io_ftqInter_fromFtq_redirect_valid",
        "io_ftqInter_fromFtq_flushFromBpu_s2_valid",
        "io_ftqInter_fromFtq_flushFromBpu_s3_valid",
        "io_mmioCommitRead_mmioLastCommit", "io_frontendTrigger_tUpdate_valid",
    }

    T = ["""// 自动生成：scripts/gen_newifu.py —— 勿手改
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
    T.append(f"  NewIFU    u_g ({', '.join(gg)});")
    T.append(f"  NewIFU_xs u_i ({', '.join(ig)});")

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for _, n in ins:
        if n in ready_like:
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n in ready_like:
            # 偏置：多数拍拉高 ready/valid 让流水推进，偶尔拉低制造停顿
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")
        elif n == "io_csr_fsIsOff":
            T.append(f"      {n} <= ($urandom_range(0,7)==0);")
        # 地址类压缩值域以提高内部比较/命中覆盖
        elif n in ("io_ftqInter_fromFtq_req_bits_startAddr",
                   "io_ftqInter_fromFtq_req_bits_nextlineStart",
                   "io_ftqInter_fromFtq_req_bits_nextStartAddr"):
            T.append(f"      {n} <= {{{w-8}'($urandom), 8'($urandom_range(0,63))}};")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
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
    print(f"NewIFU: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
