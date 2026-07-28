#!/usr/bin/env python3
"""
L1Prefetcher：生成 golden 同名 wrapper（FM 用）+ _xs 镜像（UT 用）+ 随机比对 tb。

wrapper 例化 golden 5 子预取器(TrainFilter/StrideMetaArray/TrainFilter_1/
  StreamBitVectorArray/MutiLevelPrefetchFilter)，均两侧同源 elaborate(纯逻辑非黑盒)，
  glue(训练门控/req 二选一/输出门控)由可读核 xs_L1Prefetcher_core 承担。

设计意图: src/main/scala/xiangshan/mem/prefetch/L1PrefetchComponent.scala class L1Prefetcher。
本脚本只做子模块例化 + 核互连 + tb，可读核本体见 rtl/memblock/L1Prefetcher.sv。
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


BODY = r"""
  // ---- 子预取器 ↔ 核的 net ----
  wire        stride_g0_valid, stride_g1_valid, stride_g2_valid;
  wire        stream_g0_valid, stream_g1_valid, stream_g2_valid;
  // stride 训练过滤 → stride 元数据表
  wire        stf_req_valid; wire [49:0] stf_req_vaddr; wire [49:0] stf_req_pc;
  wire        sma_req_ready;
  // stride 元数据表 → 核
  wire        sma_l1_valid; wire [39:0] sma_l1_region; wire [15:0] sma_l1_bit_vec;
  wire        sma_l2_valid; wire [39:0] sma_l2_region; wire [15:0] sma_l2_bit_vec;
  wire        sma_stream_lookup_valid; wire [49:0] sma_stream_lookup_vaddr;
  // stream 训练过滤 → stream 位向量表
  wire        smtf_req_valid; wire [49:0] smtf_req_vaddr; wire smtf_req_miss; wire smtf_req_pfHitStream;
  wire        sbva_req_ready;
  // stream 位向量表 → 核
  wire        sbva_l1_valid; wire [39:0] sbva_l1_region; wire [15:0] sbva_l1_bit_vec;
  wire        sbva_l2_valid; wire [39:0] sbva_l2_region; wire [15:0] sbva_l2_bit_vec; wire [1:0] sbva_l2_sink;
  wire        sbva_stream_lookup_resp;   // _probe (unused)
  // 合并后 → pf_queue_filter
  wire        pf_l1_valid; wire [39:0] pf_l1_region; wire [15:0] pf_l1_bit_vec; wire [2:0] pf_l1_source_value;
  wire        pf_l2_valid; wire [39:0] pf_l2_region; wire [15:0] pf_l2_bit_vec; wire [1:0] pf_l2_sink; wire [2:0] pf_l2_source_value;
  wire        pf_l1_req_ready;
  // pf_queue_filter → 核
  wire        pf_tlb_req_valid; wire pf_l1_out_valid;
  wire        pf_l2_addr_valid; wire [47:0] pf_l2_addr_bits;

  // ==== 可读核 glue ====
  xs_L1Prefetcher_core u_core (
    .io_enable(io_enable), .pf_ctrl_enable(pf_ctrl_enable),
    .stride_train_0_valid(stride_train_0_valid), .stride_train_1_valid(stride_train_1_valid),
    .stride_train_2_valid(stride_train_2_valid),
    .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_2_valid(io_ld_in_2_valid),
    .stride_g0_valid(stride_g0_valid), .stride_g1_valid(stride_g1_valid), .stride_g2_valid(stride_g2_valid),
    .stream_g0_valid(stream_g0_valid), .stream_g1_valid(stream_g1_valid), .stream_g2_valid(stream_g2_valid),
    .stream_l1_valid(sbva_l1_valid), .stream_l1_region(sbva_l1_region), .stream_l1_bit_vec(sbva_l1_bit_vec),
    .stream_l2_valid(sbva_l2_valid), .stream_l2_region(sbva_l2_region), .stream_l2_bit_vec(sbva_l2_bit_vec),
    .stream_l2_sink(sbva_l2_sink),
    .stride_l1_valid(sma_l1_valid), .stride_l1_region(sma_l1_region), .stride_l1_bit_vec(sma_l1_bit_vec),
    .stride_l2_valid(sma_l2_valid), .stride_l2_region(sma_l2_region), .stride_l2_bit_vec(sma_l2_bit_vec),
    .pf_l1_valid(pf_l1_valid), .pf_l1_region(pf_l1_region), .pf_l1_bit_vec(pf_l1_bit_vec),
    .pf_l1_source_value(pf_l1_source_value),
    .pf_l2_valid(pf_l2_valid), .pf_l2_region(pf_l2_region), .pf_l2_bit_vec(pf_l2_bit_vec),
    .pf_l2_sink(pf_l2_sink), .pf_l2_source_value(pf_l2_source_value),
    .io_l1_req_ready(io_l1_req_ready), .pf_l1_req_ready(pf_l1_req_ready),
    .pf_tlb_req_valid(pf_tlb_req_valid), .pf_l1_out_valid(pf_l1_out_valid),
    .pf_l2_addr_valid(pf_l2_addr_valid), .pf_l2_addr_bits(pf_l2_addr_bits),
    .io_tlb_req_req_valid(io_tlb_req_req_valid), .io_l1_req_valid(io_l1_req_valid),
    .io_l2_req_valid(io_l2_req_valid), .io_l2_req_bits_addr(io_l2_req_bits_addr)
  );

  // ==== golden 子预取器（两侧同源 elaborate）====
  TrainFilter stride_train_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_ld_in_0_valid(stride_g0_valid), .io_ld_in_0_bits_uop_pc(stride_train_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag(stride_train_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(stride_train_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(stride_train_0_bits_vaddr),
    .io_ld_in_1_valid(stride_g1_valid), .io_ld_in_1_bits_uop_pc(stride_train_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag(stride_train_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(stride_train_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(stride_train_1_bits_vaddr),
    .io_ld_in_2_valid(stride_g2_valid), .io_ld_in_2_bits_uop_pc(stride_train_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag(stride_train_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(stride_train_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(stride_train_2_bits_vaddr),
    .io_train_req_ready(sma_req_ready), .io_train_req_valid(stf_req_valid),
    .io_train_req_bits_vaddr(stf_req_vaddr), .io_train_req_bits_pc(stf_req_pc)
  );
  StrideMetaArray stride_meta_array (
    .clock(clock), .reset(reset),
    .io_train_req_ready(sma_req_ready), .io_train_req_valid(stf_req_valid),
    .io_train_req_bits_vaddr(stf_req_vaddr), .io_train_req_bits_pc(stf_req_pc),
    .io_l1_prefetch_req_valid(sma_l1_valid), .io_l1_prefetch_req_bits_region(sma_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(sma_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid(sma_l2_valid), .io_l2_l3_prefetch_req_bits_region(sma_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(sma_l2_bit_vec),
    .io_stream_lookup_req_valid(sma_stream_lookup_valid), .io_stream_lookup_req_bits_vaddr(sma_stream_lookup_vaddr)
  );
  TrainFilter_1 stream_train_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_ld_in_0_valid(stream_g0_valid), .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_miss(io_ld_in_0_bits_miss),
    .io_ld_in_0_bits_meta_prefetch(io_ld_in_0_bits_meta_prefetch),
    .io_ld_in_1_valid(stream_g1_valid), .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_miss(io_ld_in_1_bits_miss),
    .io_ld_in_1_bits_meta_prefetch(io_ld_in_1_bits_meta_prefetch),
    .io_ld_in_2_valid(stream_g2_valid), .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_miss(io_ld_in_2_bits_miss),
    .io_ld_in_2_bits_meta_prefetch(io_ld_in_2_bits_meta_prefetch),
    .io_train_req_ready(sbva_req_ready), .io_train_req_valid(smtf_req_valid),
    .io_train_req_bits_vaddr(smtf_req_vaddr), .io_train_req_bits_miss(smtf_req_miss),
    .io_train_req_bits_pfHitStream(smtf_req_pfHitStream)
  );
  StreamBitVectorArray stream_bit_vec_array (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_train_req_ready(sbva_req_ready), .io_train_req_valid(smtf_req_valid),
    .io_train_req_bits_vaddr(smtf_req_vaddr), .io_train_req_bits_miss(smtf_req_miss),
    .io_train_req_bits_pfHitStream(smtf_req_pfHitStream),
    .io_l1_prefetch_req_valid(sbva_l1_valid), .io_l1_prefetch_req_bits_region(sbva_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(sbva_l1_bit_vec),
    .io_l2_l3_prefetch_req_valid(sbva_l2_valid), .io_l2_l3_prefetch_req_bits_region(sbva_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(sbva_l2_bit_vec), .io_l2_l3_prefetch_req_bits_sink(sbva_l2_sink),
    .io_stream_lookup_req_valid(sma_stream_lookup_valid), .io_stream_lookup_req_bits_vaddr(sma_stream_lookup_vaddr),
    .io_stream_lookup_resp(sbva_stream_lookup_resp)
  );
  MutiLevelPrefetchFilter pf_queue_filter (
    .clock(clock), .reset(reset), .io_enable(io_enable),
    .io_l1_prefetch_req_valid(pf_l1_valid), .io_l1_prefetch_req_bits_region(pf_l1_region),
    .io_l1_prefetch_req_bits_bit_vec(pf_l1_bit_vec), .io_l1_prefetch_req_bits_source_value(pf_l1_source_value),
    .io_l2_l3_prefetch_req_valid(pf_l2_valid), .io_l2_l3_prefetch_req_bits_region(pf_l2_region),
    .io_l2_l3_prefetch_req_bits_bit_vec(pf_l2_bit_vec), .io_l2_l3_prefetch_req_bits_sink(pf_l2_sink),
    .io_l2_l3_prefetch_req_bits_source_value(pf_l2_source_value),
    .io_tlb_req_req_valid(pf_tlb_req_valid), .io_tlb_req_req_bits_vaddr(io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_fullva(io_tlb_req_req_bits_fullva),
    .io_tlb_req_req_bits_checkfullva(io_tlb_req_req_bits_checkfullva),
    .io_tlb_req_req_bits_cmd(io_tlb_req_req_bits_cmd), .io_tlb_req_req_bits_hyperinst(io_tlb_req_req_bits_hyperinst),
    .io_tlb_req_req_bits_hlvx(io_tlb_req_req_bits_hlvx), .io_tlb_req_req_bits_kill(io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_isPrefetch(io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_no_translate(io_tlb_req_req_bits_no_translate),
    .io_tlb_req_req_bits_pmp_addr(io_tlb_req_req_bits_pmp_addr),
    .io_tlb_req_req_bits_debug_robIdx_flag(io_tlb_req_req_bits_debug_robIdx_flag),
    .io_tlb_req_req_bits_debug_robIdx_value(io_tlb_req_req_bits_debug_robIdx_value),
    .io_tlb_req_req_bits_debug_isFirstIssue(io_tlb_req_req_bits_debug_isFirstIssue),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid), .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt_0(io_tlb_req_resp_bits_pbmt_0), .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_pmp_resp_ld(io_pmp_resp_ld), .io_pmp_resp_mmio(io_pmp_resp_mmio),
    .io_l1_req_ready(pf_l1_req_ready), .io_l1_req_valid(pf_l1_out_valid),
    .io_l1_req_bits_paddr(io_l1_req_bits_paddr), .io_l1_req_bits_alias(io_l1_req_bits_alias),
    .io_l1_req_bits_confidence(io_l1_req_bits_confidence), .io_l1_req_bits_is_store(io_l1_req_bits_is_store),
    .io_l1_req_bits_pf_source_value(io_l1_req_bits_pf_source_value),
    .io_l2_pf_addr_valid(pf_l2_addr_valid), .io_l2_pf_addr_bits_addr(pf_l2_addr_bits),
    .io_l2_pf_addr_bits_source(io_l2_req_bits_source), .io_confidence(pf_ctrl_confidence)
  );
"""


def build_wrapper(modname):
    ps = golden_ports("L1Prefetcher")
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = []
    L.append("// 自动生成：scripts/gen_l1prefetcher.py —— 勿手改")
    L.append(f"module {modname} (")
    L.append(",\n".join(decls))
    L.append(");")
    L.append(BODY)
    L.append("endmodule")
    return "\n".join(L) + "\n"


def build_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_l1prefetcher.py —— 勿手改",
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
    T.append(f"  L1Prefetcher    u_g ({', '.join(gg)});")
    T.append(f"  L1Prefetcher_xs u_i ({', '.join(ig)});")

    valid_rate = {
        "io_enable":       "($urandom_range(0,3)!=0)",
        "pf_ctrl_enable":  "($urandom_range(0,3)!=0)",
        "io_l1_req_ready": "($urandom_range(0,1))",
        "io_tlb_req_resp_valid": "($urandom_range(0,2)==0)",
    }
    for i in range(3):
        valid_rate[f"io_ld_in_{i}_valid"] = "($urandom_range(0,1))"
        valid_rate[f"stride_train_{i}_valid"] = "($urandom_range(0,1))"

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if "vaddr" in n or "pc" in n:
            return f"{{{w-12}'($urandom_range(0,15)), 12'($urandom)}}"
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
    ps = golden_ports("L1Prefetcher")
    (XSSV / "rtl/memblock/L1Prefetcher_wrapper.sv").write_text(build_wrapper("L1Prefetcher"))
    ut = XSSV / "verif/ut/L1Prefetcher"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(build_wrapper("L1Prefetcher_xs"))
    (ut / "tb.sv").write_text(build_tb(ps))
    print(f"L1Prefetcher: {len(ps)} golden ports")


if __name__ == "__main__":
    main()
