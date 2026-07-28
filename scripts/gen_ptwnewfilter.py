#!/usr/bin/env python3
"""
PTWNewFilter：生成 golden 同名 wrapper（FM 用）+ _xs 镜像（UT 用）+ 随机比对 tb。

wrapper 例化 golden 三组过滤器(PTWFilterEntry / PTWFilterEntry_1 ×2)+仲裁器
  (RRArbiterInit_10)+DelayN_1(flush)，均两侧同源 elaborate(纯逻辑非黑盒)，并与可读核
  xs_PTWNewFilter_core(ptwResp/last_REG/hint 寄存 bank + resp/hint/rob 路由 glue)互连。

设计意图: src/main/scala/xiangshan/cache/mmu/Repeater.scala class PTWNewFilter。
本脚本只做机械端口适配 + 子模块例化 + tb，可读核本体见 rtl/memblock/PTWNewFilter.sv。
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


# ptwResp 字段的 filter 输入连接（golden filter 只吃 ptwResp 子集）。
FILTER_RESP_FIELDS = [
    "s2xlate", "s1_entry_tag", "s1_entry_asid", "s1_entry_vmid", "s1_entry_n",
    "s1_entry_perm_g", "s1_entry_level", "s1_addr_low",
    "s1_valididx_0", "s1_valididx_1", "s1_valididx_2", "s1_valididx_3",
    "s1_valididx_4", "s1_valididx_5", "s1_valididx_6", "s1_valididx_7",
    "s2_entry_tag", "s2_entry_vmid", "s2_entry_n", "s2_entry_level",
]


def filter_inst(mod, inst, tlb_ports, arb_idx, resp_last, refill_net, ptw_valid_net,
                ptw_vpn_net, ptw_s2x_net, getGpa_out, rob_net, is_load):
    L = [f"  {mod} {inst} ("]
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid),")
    L.append("    .io_csr_hgatp_vmid(io_csr_hgatp_vmid),")
    for li, gp in enumerate(tlb_ports):
        L.append(f"    .io_tlb_req_{li}_valid(io_tlb_req_{gp}_valid),")
        L.append(f"    .io_tlb_req_{li}_bits_vpn(io_tlb_req_{gp}_bits_vpn),")
        L.append(f"    .io_tlb_req_{li}_bits_s2xlate(io_tlb_req_{gp}_bits_s2xlate),")
        L.append(f"    .io_tlb_req_{li}_bits_getGpa(io_tlb_req_{gp}_bits_getGpa),")
    L.append(f"    .io_ptw_req_0_ready(arb_in_{arb_idx}_ready),")
    L.append(f"    .io_ptw_req_0_valid({ptw_valid_net}),")
    L.append(f"    .io_ptw_req_0_bits_vpn({ptw_vpn_net}),")
    L.append(f"    .io_ptw_req_0_bits_s2xlate({ptw_s2x_net}),")
    L.append(f"    .io_ptw_resp_valid({resp_last}),")
    for f in FILTER_RESP_FIELDS:
        L.append(f"    .io_ptw_resp_bits_{f}(cr_{f}),")
    if is_load:
        L.append("    .io_hint_req_0_id(lf_hint_req_0_id), .io_hint_req_0_full(lf_hint_req_0_full),")
        L.append("    .io_hint_req_1_id(lf_hint_req_1_id), .io_hint_req_1_full(lf_hint_req_1_full),")
        L.append("    .io_hint_req_2_id(lf_hint_req_2_id), .io_hint_req_2_full(lf_hint_req_2_full),")
        L.append("    .io_hint_resp_valid(lf_hint_resp_valid), .io_hint_resp_bits_id(lf_hint_resp_bits_id),")
        L.append("    .io_hint_resp_bits_replay_all(lf_hint_resp_bits_replay_all),")
    L.append(f"    .io_rob_head_miss_in_tlb({rob_net}),")
    L.append("    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),")
    L.append("    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),")
    L.append("    .io_flush(flush),")
    L.append(f"    .io_refill({refill_net}),")
    L.append(f"    .io_getGpa({getGpa_out})")
    L.append("  );")
    return "\n".join(L)


def build_wrapper(modname, core_inst):
    ps = golden_ports("PTWNewFilter")
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = []
    L.append("// 自动生成：scripts/gen_ptwnewfilter.py —— 勿手改")
    L.append(f"module {modname} (")
    L.append(",\n".join(decls))
    L.append(");")
    # 内部 net
    L.append("""
  // ---- flush（DelayN_1）----
  wire flush;
  DelayN_1 flush_delay (.clock(clock),
    .io_in(io_sfence_valid | io_csr_satp_changed | io_csr_priv_virt & io_csr_vsatp_changed),
    .io_out(flush));

  // ---- 核 ↔ filter 共用的锁存 ptwResp（核输出）----
  wire [1:0]  cr_s2xlate; wire [34:0] cr_s1_entry_tag; wire [15:0] cr_s1_entry_asid;
  wire [13:0] cr_s1_entry_vmid; wire cr_s1_entry_n, cr_s1_entry_perm_g;
  wire [1:0]  cr_s1_entry_level; wire [2:0] cr_s1_addr_low;
  wire cr_s1_valididx_0, cr_s1_valididx_1, cr_s1_valididx_2, cr_s1_valididx_3;
  wire cr_s1_valididx_4, cr_s1_valididx_5, cr_s1_valididx_6, cr_s1_valididx_7;
  wire [37:0] cr_s2_entry_tag; wire [13:0] cr_s2_entry_vmid; wire cr_s2_entry_n;
  wire [1:0]  cr_s2_entry_level;

  // 三组 ptw_resp_valid（延迟版, 核产生）
  wire lf_resp_last, sf_resp_last, pf_resp_last;

  // 三组 filter → arbiter 的 ptw req
  wire lf_ptw_valid; wire [37:0] lf_ptw_vpn; wire [1:0] lf_ptw_s2x;
  wire sf_ptw_valid; wire [37:0] sf_ptw_vpn; wire [1:0] sf_ptw_s2x;
  wire pf_ptw_valid; wire [37:0] pf_ptw_vpn; wire [1:0] pf_ptw_s2x;
  wire arb_in_0_ready, arb_in_1_ready, arb_in_2_ready;

  // 三组 refill / rob_head_miss
  wire lf_refill, sf_refill, pf_refill;
  wire lf_rob, sf_rob, pf_rob;

  // load 组 hint
  wire [3:0] lf_hint_req_0_id; wire lf_hint_req_0_full;
  wire [3:0] lf_hint_req_1_id; wire lf_hint_req_1_full;
  wire [3:0] lf_hint_req_2_id; wire lf_hint_req_2_full;
  wire lf_hint_resp_valid; wire [3:0] lf_hint_resp_bits_id; wire lf_hint_resp_bits_replay_all;
""")
    # filter 例化
    L.append(filter_inst("PTWFilterEntry", "load_filter_load_entry", [0, 1, 2, 3], 0,
                         "lf_resp_last", "lf_refill", "lf_ptw_valid", "lf_ptw_vpn", "lf_ptw_s2x",
                         "io_tlb_resp_bits_getGpa_0", "lf_rob", True))
    L.append(filter_inst("PTWFilterEntry_1", "store_filter_store_entry", [4, 5], 1,
                         "sf_resp_last", "sf_refill", "sf_ptw_valid", "sf_ptw_vpn", "sf_ptw_s2x",
                         "io_tlb_resp_bits_getGpa_4", "sf_rob", False))
    L.append(filter_inst("PTWFilterEntry_1", "prefetch_filter_prefetch_entry", [6, 7], 2,
                         "pf_resp_last", "pf_refill", "pf_ptw_valid", "pf_ptw_vpn", "pf_ptw_s2x",
                         "io_tlb_resp_bits_getGpa_6", "pf_rob", False))
    # arbiter
    L.append("""
  RRArbiterInit_10 ptw_arb (
    .clock(clock), .reset(reset),
    .io_in_0_ready(arb_in_0_ready), .io_in_0_valid(lf_ptw_valid),
    .io_in_0_bits_vpn(lf_ptw_vpn), .io_in_0_bits_s2xlate(lf_ptw_s2x),
    .io_in_1_ready(arb_in_1_ready), .io_in_1_valid(sf_ptw_valid),
    .io_in_1_bits_vpn(sf_ptw_vpn), .io_in_1_bits_s2xlate(sf_ptw_s2x),
    .io_in_2_ready(arb_in_2_ready), .io_in_2_valid(pf_ptw_valid),
    .io_in_2_bits_vpn(pf_ptw_vpn), .io_in_2_bits_s2xlate(pf_ptw_s2x),
    .io_out_ready(io_ptw_req_0_ready), .io_out_valid(io_ptw_req_0_valid),
    .io_out_bits_vpn(io_ptw_req_0_bits_vpn), .io_out_bits_s2xlate(io_ptw_req_0_bits_s2xlate)
  );
""")
    # core
    L.append(f"  {core_inst} u_core (")
    L.append("    .clock(clock), .reset(reset), .io_flush(flush),")
    # ptw resp in (full)
    resp_in = [n for _, _, n in ps if n.startswith("io_ptw_resp")]
    L.append("    " + ", ".join(f".{n}({n})" for n in resp_in) + ",")
    # core outputs to filters (last + ptwResp subset)
    L.append("    .o_load_ptw_resp_valid_last(lf_resp_last), .o_store_ptw_resp_valid_last(sf_resp_last),")
    L.append("    .o_prefetch_ptw_resp_valid_last(pf_resp_last),")
    for f in FILTER_RESP_FIELDS:
        L.append(f"    .o_ptwResp_{f}(cr_{f}),")
    # filters → core
    L.append("    .i_load_refill(lf_refill), .i_store_refill(sf_refill), .i_prefetch_refill(pf_refill),")
    L.append("    .i_load_rob_head_miss(lf_rob), .i_store_rob_head_miss(sf_rob), .i_prefetch_rob_head_miss(pf_rob),")
    L.append("    .i_hint_req_0_id(lf_hint_req_0_id), .i_hint_req_0_full(lf_hint_req_0_full),")
    L.append("    .i_hint_req_1_id(lf_hint_req_1_id), .i_hint_req_1_full(lf_hint_req_1_full),")
    L.append("    .i_hint_req_2_id(lf_hint_req_2_id), .i_hint_req_2_full(lf_hint_req_2_full),")
    L.append("    .i_hint_resp_valid(lf_hint_resp_valid), .i_hint_resp_bits_id(lf_hint_resp_bits_id),")
    L.append("    .i_hint_resp_bits_replay_all(lf_hint_resp_bits_replay_all),")
    # core → top outputs（getGpa_0/4/6 由三组 filter 的 io_getGpa 直连, 不经核）
    top_outs = [n for _, _, n in ps
                if (n.startswith("io_tlb_resp") and not n.startswith("io_tlb_resp_bits_getGpa"))
                or n.startswith("io_hint") or n == "io_rob_head_miss_in_tlb"]
    L.append("    " + ", ".join(f".{n}({n})" for n in top_outs))
    L.append("  );")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def build_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["// 自动生成：scripts/gen_ptwnewfilter.py —— 勿手改",
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
    T.append(f"  PTWNewFilter    u_g ({', '.join(gg)});")
    T.append(f"  PTWNewFilter_xs u_i ({', '.join(ig)});")

    valid_rate = {
        "io_ptw_req_0_ready":  "($urandom_range(0,1))",
        "io_ptw_resp_valid":   "($urandom_range(0,2)==0)",
        "io_sfence_valid":     "($urandom_range(0,63)==0)",
        "io_csr_satp_changed": "($urandom_range(0,63)==0)",
        "io_csr_vsatp_changed":"($urandom_range(0,63)==0)",
        "io_csr_hgatp_changed":"($urandom_range(0,63)==0)",
        "io_debugTopDown_robHeadVaddr_valid":"($urandom_range(0,7)==0)",
    }
    for i in range(8):
        valid_rate[f"io_tlb_req_{i}_valid"] = "($urandom_range(0,1))"

    def rnd(w, n):
        if n in valid_rate:
            return valid_rate[n]
        if "vpn" in n:
            return f"{w}'($urandom_range(0,63))"  # 压窄 vpn 提高跨组命中/合并
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
    ps = golden_ports("PTWNewFilter")
    (XSSV / "rtl/memblock/PTWNewFilter_wrapper.sv").write_text(
        build_wrapper("PTWNewFilter", "xs_PTWNewFilter_core"))
    ut = XSSV / "verif/ut/PTWNewFilter"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(build_wrapper("PTWNewFilter_xs", "xs_PTWNewFilter_core"))
    (ut / "tb.sv").write_text(build_tb(ps))
    print(f"PTWNewFilter: {len(ps)} golden ports")


if __name__ == "__main__":
    main()
