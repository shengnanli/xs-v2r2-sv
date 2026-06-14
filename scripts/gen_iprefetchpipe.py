#!/usr/bin/env python3
"""
IPrefetchPipe：解析 golden 端口生成 wrapper(golden 同名 IPrefetchPipe)、_xs 镜像、
随机比对 tb。

IPrefetchPipe 的端口已是逐字段扁平形式（io_*），与核 xs_IPrefetchPipe_core 端口一一
同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。寄存器命名沿用
golden（s1_*/s2_*/state/has_send_*/REG* 等全为标量），Formality 按名直接匹配，无需 fm_map。
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
    L.append("  xs_IPrefetchPipe_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("IPrefetchPipe")
    hdr = "// 自动生成：scripts/gen_iprefetchpipe.py —— 勿手改\n"

    (XSSV / "rtl/frontend/IPrefetchPipe_wrapper.sv").write_text(hdr + emit("IPrefetchPipe", ps))
    ut = XSSV / "verif/ut/IPrefetchPipe"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("IPrefetchPipe_xs", ps))

    # ---- testbench ----
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_iprefetchpipe.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
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
    T.append(f"  IPrefetchPipe    u_g ({', '.join(gg)});")
    T.append(f"  IPrefetchPipe_xs u_i ({', '.join(ig)});")

    # 随机激励：握手/valid 单独控制制造背压；地址类压窄值域提高 tag/vSet 命中率。
    # ITLB miss 偶发以覆盖多周期重发；exception/pbmt one-hot 化避免 golden 断言误触。
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_req_valid <= 1'b0;")
    T.append("      io_flush <= 1'b0;")
    T.append("      io_MSHRResp_valid <= 1'b0;")
    T.append("      io_flushFromBpu_s2_valid <= 1'b0;")
    T.append("      io_flushFromBpu_s3_valid <= 1'b0;")
    T.append("    end else begin")

    def rnd(w, n):
        # exception one-hot: 只让 pf/gpf/af 中至多一个为 1（golden 断言要求 one-hot）
        if n in ("io_itlb_0_resp_bits_excp_0_gpf_instr", "io_itlb_0_resp_bits_excp_0_pf_instr",
                 "io_itlb_0_resp_bits_excp_0_af_instr", "io_itlb_1_resp_bits_excp_0_gpf_instr",
                 "io_itlb_1_resp_bits_excp_0_pf_instr", "io_itlb_1_resp_bits_excp_0_af_instr"):
            return None  # 在下面统一 one-hot 赋值
        if n == "io_req_valid":
            return "($urandom_range(0,2)!=0)"
        if n == "io_flush":
            return "($urandom_range(0,31)==0)"
        if n in ("io_flushFromBpu_s2_valid", "io_flushFromBpu_s3_valid"):
            return "($urandom_range(0,15)==0)"
        if n == "io_csr_pf_enable":
            return "($urandom_range(0,3)!=0)"
        if n in ("io_metaRead_toIMeta_ready", "io_wayLookupWrite_ready", "io_MSHRReq_ready"):
            return "($urandom_range(0,2)!=0)"
        if n in ("io_itlb_0_resp_bits_miss", "io_itlb_1_resp_bits_miss"):
            return "($urandom_range(0,2)==0)"  # ~1/3 miss
        if n == "io_MSHRResp_valid":
            return "($urandom_range(0,3)==0)"
        if n in ("io_req_bits_startAddr", "io_req_bits_nextlineStart",
                 "io_req_bits_ftqIdx_value"):
            return None  # 见下
        # paddr/tag/vSet 类压窄以提高比较命中
        if n in ("io_itlb_0_resp_bits_paddr_0", "io_itlb_1_resp_bits_paddr_0"):
            return f"{{{w-12}'($urandom_range(0,7)), 12'($urandom)}}"
        if n in ("io_metaRead_fromIMeta_metas_0_0_tag", "io_metaRead_fromIMeta_metas_0_1_tag",
                 "io_metaRead_fromIMeta_metas_0_2_tag", "io_metaRead_fromIMeta_metas_0_3_tag",
                 "io_metaRead_fromIMeta_metas_1_0_tag", "io_metaRead_fromIMeta_metas_1_1_tag",
                 "io_metaRead_fromIMeta_metas_1_2_tag", "io_metaRead_fromIMeta_metas_1_3_tag"):
            return f"{w}'($urandom_range(0,7))"
        if n == "io_MSHRResp_bits_blkPaddr":
            return f"{{{w-6}'($urandom_range(0,7)), 6'($urandom)}}"
        if n == "io_MSHRResp_bits_vSetIdx":
            return f"{w}'($urandom_range(0,15))"
        if n in ("io_itlb_0_resp_bits_pbmt_0", "io_itlb_1_resp_bits_pbmt_0",
                 "io_req_bits_backendException"):
            return f"{w}'($urandom_range(0,3))"
        if n == "io_MSHRResp_bits_waymask":
            return f"{w}'($urandom_range(0,15))"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    for w, n in ins:
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    # 地址：低位含 doubleline 位[5]/vSet[13:6]，压窄高位以提高命中
    T.append("      io_req_bits_startAddr <= {44'($urandom_range(0,7)), 6'($urandom)};")
    T.append("      io_req_bits_nextlineStart <= {44'($urandom_range(0,7)), 6'($urandom)};")
    T.append("      io_req_bits_ftqIdx_value <= 6'($urandom);")
    # ITLB excp one-hot（含全 0）：取 0..3，>0 时点亮对应一位
    for p in ("0", "1"):
        T.append(f"      begin int oh; oh = $urandom_range(0,3);")
        T.append(f"        io_itlb_{p}_resp_bits_excp_0_pf_instr  <= (oh==1);")
        T.append(f"        io_itlb_{p}_resp_bits_excp_0_gpf_instr <= (oh==2);")
        T.append(f"        io_itlb_{p}_resp_bits_excp_0_af_instr  <= (oh==3); end")
    T.append("    end")
    T.append("  end")

    # 比对：复位后每拍在时钟稳定区比对所有输出
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (ut / "tb.sv").write_text("\n".join(T))
    print(f"IPrefetchPipe: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
