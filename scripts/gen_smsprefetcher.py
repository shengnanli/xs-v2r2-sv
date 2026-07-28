#!/usr/bin/env python3
"""
SMSPrefetcher：生成 golden 同名 wrapper（FM 用）+ _xs 镜像（UT 用）+ 随机比对 tb。

wrapper 例化 golden 5 子模块(SMSTrainFilter/ActiveGenerationTable/StridePF/
  PatternHistoryTable/PrefetchFilter)，均两侧同源 elaborate；pht 内 SRAMTemplate_134 →
  厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht 为唯一黑盒(两侧对称)。
glue(s0 特征寄存/门控/输出) 由可读核 xs_SMSPrefetcher_core 承担。

设计意图: src/main/scala/xiangshan/mem/prefetch/SMSPrefetcher.scala class SMSPrefetcher。
本脚本只做子模块例化 + 核互连 + tb，可读核本体见 rtl/memblock/SMSPrefetcher.sv。
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
  // ---- net ----
  wire        tf_valid; wire [49:0] tf_vaddr; wire [47:0] tf_paddr; wire [49:0] tf_pc;
  // 核 → AGT/Stride s0
  wire        cr_s0_lookup_valid; wire [10:0] cr_region_tag, cr_region_p1_tag, cr_region_m1_tag;
  wire [3:0]  cr_region_offset; wire [4:0] cr_pht_index; wire [12:0] cr_pht_tag;
  wire        cr_allow_cross_p1, cr_allow_cross_m1; wire [37:0] cr_region_paddr; wire [39:0] cr_region_vaddr;
  wire [9:0]  cr_stride_pc;
  // AGT → Stride / PHT
  wire        agt_s1_sel_stride;
  wire        agt_pht_lookup_valid; wire [4:0] agt_pht_lookup_index; wire [12:0] agt_pht_lookup_tag;
  wire [39:0] agt_pht_lookup_paddr; wire [39:0] agt_pht_lookup_vaddr; wire [3:0] agt_pht_lookup_offset;
  wire        agt_evict_valid; wire [4:0] agt_evict_index; wire [12:0] agt_evict_tag;
  wire [15:0] agt_evict_region_bits; wire [15:0] agt_evict_region_bit_single; wire [3:0] agt_evict_offset;
  wire [3:0]  agt_evict_access_cnt; wire agt_evict_decr_mode, agt_evict_single_update, agt_evict_has_been_signal_updated;
  // PHT → filter
  wire        pht_gen_valid; wire [10:0] pht_gen_region_tag; wire [39:0] pht_gen_region_addr;
  wire [15:0] pht_gen_region_bits; wire pht_gen_paddr_valid, pht_gen_decr_mode;
  wire        pf_gen_valid;      // 核门控后
  // filter → 核
  wire        pf_l2_addr_valid; wire [47:0] pf_l2_addr_bits;

  // ==== 可读核 glue ====
  xs_SMSPrefetcher_core u_core (
    .clock(clock), .reset(reset), .io_enable(io_enable), .io_pht_en(io_pht_en),
    .i_train_valid(tf_valid), .i_train_vaddr(tf_vaddr), .i_train_paddr(tf_paddr), .i_train_pc(tf_pc),
    .o_s0_lookup_valid(cr_s0_lookup_valid),
    .o_region_tag_s0(cr_region_tag), .o_region_p1_tag_s0(cr_region_p1_tag), .o_region_m1_tag_s0(cr_region_m1_tag),
    .o_region_offset_s0(cr_region_offset), .o_pht_index_s0(cr_pht_index), .o_pht_tag_s0(cr_pht_tag),
    .o_allow_cross_region_p1_s0(cr_allow_cross_p1), .o_allow_cross_region_m1_s0(cr_allow_cross_m1),
    .o_region_paddr_s0(cr_region_paddr), .o_region_vaddr_s0(cr_region_vaddr), .o_stride_s0_pc(cr_stride_pc),
    .i_pht_gen_req_valid(pht_gen_valid), .o_pf_gen_req_valid(pf_gen_valid),
    .i_pf_l2_addr_valid(pf_l2_addr_valid), .i_pf_l2_addr_bits(pf_l2_addr_bits),
    .io_l2_req_valid(io_l2_req_valid), .io_l2_req_bits_addr(io_l2_req_bits_addr)
  );

  // ==== golden 子模块（两侧同源 elaborate）====
  SMSTrainFilter train_filter (
    .clock(clock), .reset(reset),
    .io_ld_in_0_valid(io_ld_in_0_valid), .io_ld_in_0_bits_uop_pc(io_ld_in_0_bits_uop_pc),
    .io_ld_in_0_bits_uop_robIdx_flag(io_ld_in_0_bits_uop_robIdx_flag),
    .io_ld_in_0_bits_uop_robIdx_value(io_ld_in_0_bits_uop_robIdx_value),
    .io_ld_in_0_bits_vaddr(io_ld_in_0_bits_vaddr), .io_ld_in_0_bits_paddr(io_ld_in_0_bits_paddr),
    .io_ld_in_1_valid(io_ld_in_1_valid), .io_ld_in_1_bits_uop_pc(io_ld_in_1_bits_uop_pc),
    .io_ld_in_1_bits_uop_robIdx_flag(io_ld_in_1_bits_uop_robIdx_flag),
    .io_ld_in_1_bits_uop_robIdx_value(io_ld_in_1_bits_uop_robIdx_value),
    .io_ld_in_1_bits_vaddr(io_ld_in_1_bits_vaddr), .io_ld_in_1_bits_paddr(io_ld_in_1_bits_paddr),
    .io_ld_in_2_valid(io_ld_in_2_valid), .io_ld_in_2_bits_uop_pc(io_ld_in_2_bits_uop_pc),
    .io_ld_in_2_bits_uop_robIdx_flag(io_ld_in_2_bits_uop_robIdx_flag),
    .io_ld_in_2_bits_uop_robIdx_value(io_ld_in_2_bits_uop_robIdx_value),
    .io_ld_in_2_bits_vaddr(io_ld_in_2_bits_vaddr), .io_ld_in_2_bits_paddr(io_ld_in_2_bits_paddr),
    .io_train_req_valid(tf_valid), .io_train_req_bits_vaddr(tf_vaddr),
    .io_train_req_bits_paddr(tf_paddr), .io_train_req_bits_pc(tf_pc)
  );
  ActiveGenerationTable active_gen_table (
    .clock(clock), .reset(reset), .io_agt_en(io_agt_en),
    .io_s0_lookup_valid(cr_s0_lookup_valid),
    .io_s0_lookup_bits_region_tag(cr_region_tag),
    .io_s0_lookup_bits_region_p1_tag(cr_region_p1_tag),
    .io_s0_lookup_bits_region_m1_tag(cr_region_m1_tag),
    .io_s0_lookup_bits_region_offset(cr_region_offset),
    .io_s0_lookup_bits_pht_index(cr_pht_index),
    .io_s0_lookup_bits_pht_tag(cr_pht_tag),
    .io_s0_lookup_bits_allow_cross_region_p1(cr_allow_cross_p1),
    .io_s0_lookup_bits_allow_cross_region_m1(cr_allow_cross_m1),
    .io_s0_lookup_bits_region_paddr({2'h0, cr_region_paddr}),
    .io_s0_lookup_bits_region_vaddr(cr_region_vaddr),
    .io_s0_dcache_evict_valid(io_dcache_evict_valid),
    .io_s0_dcache_evict_bits_vaddr(io_dcache_evict_bits_vaddr),
    .io_s1_sel_stride(agt_s1_sel_stride),
    .io_s2_pht_lookup_valid(agt_pht_lookup_valid),
    .io_s2_pht_lookup_bits_pht_index(agt_pht_lookup_index),
    .io_s2_pht_lookup_bits_pht_tag(agt_pht_lookup_tag),
    .io_s2_pht_lookup_bits_region_paddr(agt_pht_lookup_paddr),
    .io_s2_pht_lookup_bits_region_vaddr(agt_pht_lookup_vaddr),
    .io_s2_pht_lookup_bits_region_offset(agt_pht_lookup_offset),
    .io_s2_evict_valid(agt_evict_valid),
    .io_s2_evict_bits_pht_index(agt_evict_index),
    .io_s2_evict_bits_pht_tag(agt_evict_tag),
    .io_s2_evict_bits_region_bits(agt_evict_region_bits),
    .io_s2_evict_bits_region_bit_single(agt_evict_region_bit_single),
    .io_s2_evict_bits_region_offset(agt_evict_offset),
    .io_s2_evict_bits_access_cnt(agt_evict_access_cnt),
    .io_s2_evict_bits_decr_mode(agt_evict_decr_mode),
    .io_s2_evict_bits_single_update(agt_evict_single_update),
    .io_s2_evict_bits_has_been_signal_updated(agt_evict_has_been_signal_updated),
    .io_act_threshold(io_act_threshold), .io_act_stride(io_act_stride)
  );
  StridePF stride (
    .clock(clock), .reset(reset),
    .io_s0_lookup_valid(cr_s0_lookup_valid), .io_s0_lookup_bits_pc(cr_stride_pc),
    .io_s1_valid(agt_s1_sel_stride)
  );
  PatternHistoryTable pht (
    .clock(clock), .reset(reset),
    .io_agt_update_valid(agt_evict_valid),
    .io_agt_update_bits_pht_index(agt_evict_index),
    .io_agt_update_bits_pht_tag(agt_evict_tag),
    .io_agt_update_bits_region_bits(agt_evict_region_bits),
    .io_agt_update_bits_region_bit_single(agt_evict_region_bit_single),
    .io_agt_update_bits_region_offset(agt_evict_offset),
    .io_agt_update_bits_access_cnt(agt_evict_access_cnt),
    .io_agt_update_bits_decr_mode(agt_evict_decr_mode),
    .io_agt_update_bits_single_update(agt_evict_single_update),
    .io_agt_update_bits_has_been_signal_updated(agt_evict_has_been_signal_updated),
    .io_s2_agt_lookup_valid(agt_pht_lookup_valid),
    .io_s2_agt_lookup_bits_pht_index(agt_pht_lookup_index),
    .io_s2_agt_lookup_bits_pht_tag(agt_pht_lookup_tag),
    .io_s2_agt_lookup_bits_region_paddr(agt_pht_lookup_paddr),
    .io_s2_agt_lookup_bits_region_vaddr(agt_pht_lookup_vaddr),
    .io_s2_agt_lookup_bits_region_offset(agt_pht_lookup_offset),
    .io_pf_gen_req_valid(pht_gen_valid),
    .io_pf_gen_req_bits_region_tag(pht_gen_region_tag),
    .io_pf_gen_req_bits_region_addr(pht_gen_region_addr),
    .io_pf_gen_req_bits_region_bits(pht_gen_region_bits),
    .io_pf_gen_req_bits_paddr_valid(pht_gen_paddr_valid),
    .io_pf_gen_req_bits_decr_mode(pht_gen_decr_mode),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );
  PrefetchFilter pf_filter (
    .clock(clock), .reset(reset),
    .io_gen_req_valid(pf_gen_valid),
    .io_gen_req_bits_region_tag(pht_gen_region_tag),
    .io_gen_req_bits_region_addr(pht_gen_region_addr),
    .io_gen_req_bits_region_bits(pht_gen_region_bits),
    .io_gen_req_bits_paddr_valid(pht_gen_paddr_valid),
    .io_gen_req_bits_decr_mode(pht_gen_decr_mode),
    .io_tlb_req_req_valid(io_tlb_req_req_valid), .io_tlb_req_req_bits_vaddr(io_tlb_req_req_bits_vaddr),
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
    .io_l2_pf_addr_valid(pf_l2_addr_valid), .io_l2_pf_addr_bits(pf_l2_addr_bits)
  );
"""


def build_wrapper(modname):
    ps = golden_ports("SMSPrefetcher")
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = []
    L.append("// 自动生成：scripts/gen_smsprefetcher.py —— 勿手改")
    L.append(f"module {modname} (")
    L.append(",\n".join(decls))
    L.append(");")
    L.append(BODY)
    L.append("endmodule")
    return "\n".join(L) + "\n"


def build_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_smsprefetcher.py —— 勿手改",
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
    T.append(f"  SMSPrefetcher    u_g ({', '.join(gg)});")
    T.append(f"  SMSPrefetcher_xs u_i ({', '.join(ig)});")

    valid_rate = {
        "io_enable":  "($urandom_range(0,3)!=0)",
        "io_agt_en":  "($urandom_range(0,3)!=0)",
        "io_pht_en":  "($urandom_range(0,3)!=0)",
        "io_tlb_req_resp_valid": "($urandom_range(0,2)==0)",
        "io_dcache_evict_valid": "($urandom_range(0,3)==0)",
        "boreChildrenBd_bore_re": "($urandom_range(0,7)==0)",
        "boreChildrenBd_bore_we": "($urandom_range(0,7)==0)",
    }
    for i in range(3):
        valid_rate[f"io_ld_in_{i}_valid"] = "($urandom_range(0,1))"

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if "vaddr" in n or "paddr" in n or n.endswith("_pc"):
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
    ps = golden_ports("SMSPrefetcher")
    (XSSV / "rtl/memblock/SMSPrefetcher_wrapper.sv").write_text(build_wrapper("SMSPrefetcher"))
    ut = XSSV / "verif/ut/SMSPrefetcher"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(build_wrapper("SMSPrefetcher_xs"))
    (ut / "tb.sv").write_text(build_tb(ps))
    print(f"SMSPrefetcher: {len(ps)} golden ports")


if __name__ == "__main__":
    main()
