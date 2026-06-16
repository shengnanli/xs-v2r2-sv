#!/usr/bin/env python3
"""
LoadUnit：解析 golden 端口生成 wrapper(golden 同名 LoadUnit)、_xs 镜像、随机比对 tb。

LoadUnit 的端口已是逐字段扁平形式（io_*），与可读核 xs_LoadUnit_core 端口一一同名，
故 wrapper / _xs 只把端口透传给核（u_core），无需打包/拆分逻辑。

核内部例化叶子子模块 MemTrigger（断点匹配），golden 也例化同一模块；UT 两侧共用同一份
golden MemTrigger.sv（黑盒），FM 时作为两侧共享黑盒。

设计意图来自 src/main/scala/xiangshan/mem/pipeline/LoadUnit.scala（4 级流水 S0~S3）。
本脚本只负责机械端口适配 + 随机激励 tb，可读核本体见 rtl/memblock/LoadUnit.sv。
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
    L.append("  xs_LoadUnit_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_core(ps):
    """拼接可读核 LoadUnit.sv：模块头 + 端口表 + 手写主体（_core_body.svh）。
    端口名/序与 golden 完全一致，主体从 LoadUnit.scala 设计意图重写。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    body = (XSSV / "rtl/memblock/LoadUnit_core_body.svh").read_text()
    L = ["// 自动生成框架（端口表）+ 手写主体（LoadUnit_core_body.svh）",
         "//   由 scripts/gen_loadunit.py 拼接。可读核本体改 LoadUnit_core_body.svh。",
         "module xs_LoadUnit_core(", ",\n".join(decls) + "\n);", body, "endmodule"]
    return "\n".join(L)


def main():
    ps = ports("LoadUnit")
    hdr = "// 自动生成：scripts/gen_loadunit.py —— 勿手改\n"

    (XSSV / "rtl/memblock/LoadUnit.sv").write_text(emit_core(ps))
    (XSSV / "rtl/memblock/LoadUnit_wrapper.sv").write_text(hdr + emit("LoadUnit", ps))
    ut = XSSV / "verif/ut/LoadUnit"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit("LoadUnit_xs", ps))

    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = ["""// 自动生成：scripts/gen_loadunit.py —— 勿手改
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
    T.append(f"  LoadUnit    u_g ({', '.join(gg)});")
    T.append(f"  LoadUnit_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # LoadUnit 有 8 个互斥优先级输入源（misalign/super_rep/fast_rep/mmio/nc/lsq_rep/
    # vec/int + prefetch + l2l）。各 valid 独立随机以覆盖优先级仲裁；地址类压窄高位以
    # 提高跨级 paddr/vaddr 命中；TLB exception one-hot 化避免 golden 断言误触。
    onehot_excp = {
        "io_tlb_resp_bits_excp_0_gpf_ld", "io_tlb_resp_bits_excp_0_gpf_st",
        "io_tlb_resp_bits_excp_0_pf_ld", "io_tlb_resp_bits_excp_0_pf_st",
        "io_tlb_resp_bits_excp_0_af_ld", "io_tlb_resp_bits_excp_0_af_st",
    }
    # 各输入源的 valid 拉高概率（高优先级少发，低优先级多发，保证仲裁覆盖）
    valid_rate = {
        "io_misalign_ldin_valid": "($urandom_range(0,5)==0)",   # 最高优先级，少发
        "io_replay_valid":        "($urandom_range(0,2)!=0)",   # super/lsq replay
        "io_fast_rep_in_valid":   "($urandom_range(0,3)==0)",
        "io_lsq_uncache_valid":   "($urandom_range(0,4)==0)",
        "io_lsq_nc_ldin_valid":   "($urandom_range(0,4)==0)",
        "io_prefetch_req_valid":  "($urandom_range(0,3)==0)",
        "io_vecldin_valid":       "($urandom_range(0,2)!=0)",
        "io_ldin_valid":          "($urandom_range(0,1))",      # int issue，常发
        "io_l2l_fwd_in_valid":    "($urandom_range(0,3)==0)",
        "io_redirect_valid":      "($urandom_range(0,15)==0)",  # 偶发冲刷
        "io_tlb_resp_valid":      "($urandom_range(0,3)!=0)",
        "io_dcache_resp_valid":   "($urandom_range(0,3)!=0)",
        "io_dcache_req_ready":    "($urandom_range(0,4)!=0)",
        "io_ldout_ready":         "($urandom_range(0,3)!=0)",
        "io_tlb_resp_bits_miss":  "($urandom_range(0,3)==0)",
    }

    def rnd(w, n):
        if n in onehot_excp:
            return None  # 统一 one-hot 赋值
        if n in valid_rate:
            return valid_rate[n]
        if n == "io_redirect_bits_level":
            return None
        # 地址类：压窄高位以提高 paddr/vaddr 跨级命中（仍覆盖低位对齐/跨界）
        addr_lo6 = {
            "io_ldin_bits_src_0", "io_vecldin_bits_vaddr", "io_l2l_fwd_in_data",
        }
        if n in addr_lo6:
            return "{58'($urandom_range(0,3)), 6'($urandom)}"
        if n in ("io_misalign_ldin_bits_vaddr", "io_replay_bits_vaddr",
                 "io_fast_rep_in_bits_vaddr"):
            return f"{{{w-6}'($urandom_range(0,3)), 6'($urandom)}}"
        if n in ("io_tlb_resp_bits_paddr_0", "io_tlb_resp_bits_paddr_1",
                 "io_replay_bits_paddr", "io_fast_rep_in_bits_paddr",
                 "io_lsq_nc_ldin_bits_paddr", "io_prefetch_req_bits_paddr"):
            return f"{{{w-6}'($urandom_range(0,3)), 6'($urandom)}}"
        if n in ("io_tlb_resp_bits_gpaddr_0", "io_tlb_resp_bits_fullva"):
            return "{52'($urandom_range(0,3)), 12'($urandom)}"
        # nuke query paddr：与 s2 paddr 高位重叠以触发 nuke
        if n in ("io_stld_nuke_query_0_bits_paddr", "io_stld_nuke_query_1_bits_paddr"):
            return f"{{{w-6}'($urandom_range(0,3)), 6'($urandom)}}"
        # tdata2：低位与地址有一定重叠以触发 trigger（高位压窄）
        if n.endswith("_tdata2"):
            return "{52'($urandom_range(0,3)), 12'($urandom)}"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    reset_valids = [
        "io_misalign_ldin_valid", "io_replay_valid", "io_fast_rep_in_valid",
        "io_lsq_uncache_valid", "io_lsq_nc_ldin_valid", "io_prefetch_req_valid",
        "io_vecldin_valid", "io_ldin_valid", "io_l2l_fwd_in_valid",
        "io_redirect_valid", "io_tlb_resp_valid", "io_dcache_resp_valid",
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
    # TLB excp one-hot（含全 0）：LoadUnit 为 load-only，仅有 pf_ld/af_ld/gpf_ld。
    if "io_tlb_resp_bits_excp_0_pf_ld" in in_names:
        T.append("      begin int oh; oh = $urandom_range(0,3);")
        T.append("        io_tlb_resp_bits_excp_0_pf_ld  <= (oh==1);")
        T.append("        io_tlb_resp_bits_excp_0_af_ld  <= (oh==2);")
        T.append("        io_tlb_resp_bits_excp_0_gpf_ld <= (oh==3); end")
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
    print(f"LoadUnit: {len(ps)} ports, {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
