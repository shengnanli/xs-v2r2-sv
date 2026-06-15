#!/usr/bin/env python3
"""
StoreUnit：解析 golden 端口生成 wrapper(golden 同名 StoreUnit)、_xs 镜像、随机比对 tb。

StoreUnit 的 golden 端口已是逐字段扁平形式（io_*），与可读核 xs_StoreUnit_core 端口
一一同名，故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。

核内部例化叶子子模块 MemTrigger_3（store 断点匹配），golden 也例化同一模块；UT 两侧
共用同一份 golden MemTrigger_3.sv（黑盒），FM 时作为两侧共享黑盒。

设计意图来自 src/main/scala/xiangshan/mem/pipeline/StoreUnit.scala（5 级 s0~s3+sx）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/StoreUnit.sv。
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
    L.append("  xs_StoreUnit_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def main():
    ps = ports("StoreUnit")
    hdr = "// 自动生成：scripts/gen_storeunit.py —— 勿手改\n"

    (XSSV / "rtl/memblock/StoreUnit_wrapper.sv").write_text(hdr + emit("StoreUnit", ps))
    ut = XSSV / "verif/ut/StoreUnit"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("StoreUnit_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_storeunit.py —— 勿手改
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
    T.append(f"  StoreUnit    u_g ({', '.join(gg)});")
    T.append(f"  StoreUnit_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # StoreUnit 有 3 个互斥优先级输入源（misalign/标量stin/向量vecstin）。各 valid 独立
    # 随机以覆盖优先级仲裁；地址类压窄高位提高跨级 paddr/vaddr 命中；TLB exception 与 PMP
    # one-hot 化避免 golden 断言误触（cbo 选择断言、向量 128 对齐断言）。
    valid_rate = {
        "io_misalign_stin_valid": "($urandom_range(0,5)==0)",  # 最高优先级，少发
        "io_vecstin_valid":       "($urandom_range(0,2)!=0)",
        "io_stin_valid":          "($urandom_range(0,1))",     # 标量发射，常发
        "io_redirect_valid":      "($urandom_range(0,15)==0)", # 偶发冲刷
        "io_tlb_resp_valid":      "($urandom_range(0,3)!=0)",
        "io_tlb_resp_bits_miss":  "($urandom_range(0,3)==0)",
        "io_misalign_enq_req_ready": "($urandom_range(0,2)!=0)",
        "io_csrCtrl_hd_misalign_st_enable": "($urandom_range(0,1))",
    }

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if n == "io_redirect_bits_level":
            return None
        # 地址类：压窄高位以提高 paddr/vaddr 跨级命中（仍覆盖低位对齐/跨界）
        if n in ("io_stin_bits_src_0", "io_vecstin_bits_vaddr",
                 "io_misalign_stin_bits_vaddr", "io_prefetch_req_bits_vaddr",
                 "io_tlb_resp_bits_paddr_0", "io_tlb_resp_bits_gpaddr_0",
                 "io_tlb_resp_bits_fullva"):
            return f"{{{w-6}'($urandom_range(0,3)), 6'($urandom)}}"
        # imm 压窄到 12 位有效低位
        if n == "io_stin_bits_uop_imm":
            return "{20'h0, 12'($urandom)}"
        # tdata2：低位与地址有重叠以触发 trigger
        if n.endswith("_tdata2"):
            return "{52'($urandom_range(0,3)), 12'($urandom)}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_misalign_stin_valid", "io_vecstin_valid", "io_stin_valid",
        "io_redirect_valid", "io_tlb_resp_valid",
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
    # TLB excp one-hot（含全 0）：取 0..6，>0 时点亮对应一位（避免多异常并发触发 golden 断言）
    if "io_tlb_resp_bits_excp_0_pf_ld" in in_names:
        T.append("      begin int oh; oh = $urandom_range(0,6);")
        T.append("        io_tlb_resp_bits_excp_0_pf_st  <= (oh==1);")
        T.append("        io_tlb_resp_bits_excp_0_pf_ld  <= (oh==2);")
        T.append("        io_tlb_resp_bits_excp_0_af_st  <= (oh==3);")
        T.append("        io_tlb_resp_bits_excp_0_af_ld  <= (oh==4);")
        T.append("        io_tlb_resp_bits_excp_0_gpf_st <= (oh==5);")
        T.append("        io_tlb_resp_bits_excp_0_gpf_ld <= (oh==6); end")
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
    print(f"StoreUnit: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
