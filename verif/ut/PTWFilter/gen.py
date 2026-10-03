#!/usr/bin/env python3
"""生成 PTWFilter 的双例化 UT testbench（tb.sv）。

golden PTWFilter（连同 golden DelayN_1）vs 重写 PTWFilter_xs，每拍逐位比较全部输出。
受约束随机（约束里引用 golden 实例内部状态，两侧输入永远相同）：
  * ITLB 请求：vpn 从一个 8 项的小池子里抽（每 1000 拍换池；池子按 mode 分同扇区 / 同 2MB 页 / 全随机三档），让「同一页连问 / 三个口同问 /
    队列里已有」三种合并都大量出现；s2xlate 多数拍 0，按 mode 混入 1/2/3。
  * L2TLB 回应：多数拍照着 golden 队列里某一项（随机挑）的 vpn / s2xlate 造 tag，asid / vmid
    多数拍对上 CSR，level / n / valididx 随机 —— 这样「命中队列项」「napot / 大页命中」
    「asid 不对不命中」都走到；1/4 的拍照着池子里的 vpn 造（打中正在入队的请求 = 假入队）。
  * CSR asid / vmid 偶尔切换；sfence / satp 变化（flush）稀疏；ptw req ready 3/4。
不复位寄存器：队列内容（vpn/s2xlate/getGpa）、ptwResp、寄存的请求 bits。arm 条件：
golden 累计入队 >= 8（8 个槽都写过）、三个口各 valid 过、ptw 回应 valid 过。

注：issue_filtered（要发的项已被上一拍回应覆盖）在本激励下几乎到不了——回应命中的项在回应当拍就被清掉，
只有 CSR asid/vmid 恰在两拍之间切换才可能；不列覆盖闸，由 FM 证明该路径。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "pf_u_gold."

DECLS = """
logic [7:0][37:0] pf_pool;
logic [7:0][37:0] pf_vpns;
logic [7:0][1:0]  pf_s2xs;
logic [37:0]      pf_tvpn;
logic [1:0]       pf_ts2x;
int unsigned      pf_enq_total = 0;
function automatic logic [1:0] pf_s2x(input int unsigned mode);
  case (mode % 4)
    0:       return 2'd0;
    1:       return 2'd2;
    2:       return 2'($urandom_range(0, 3));
    default: return {1'($urandom), 1'b1};   // onlyStage1 / allStage
  endcase
endfunction
"""

L = []
A = L.append
# 池子的局部性按 mode 分三档：同一扇区（vpn[37:3] 相同）/ 同一 2MB 页 / 全随机，
# 让扇区命中、大页 / napot 命中、以及一次回应覆盖多个队列项（issue_filtered）都走到
A("if (cyc % 1000 == 0) begin")
A("  pf_pool[0] = 38'({$urandom, $urandom});")
A("  for (int k = 1; k < 8; k++) pf_pool[k] = (@mode % 3 == 0) ? {pf_pool[0][37:3], 3'($urandom)}")
A("                                          : (@mode % 3 == 1) ? {pf_pool[0][37:9], 9'($urandom)} : 38'({$urandom, $urandom});")
A("end")
A("if (%sdo_enq) pf_enq_total += %s_enqNum_T_2;" % (G, G))
A("pf_vpns = {%svpn_7, %svpn_6, %svpn_5, %svpn_4, %svpn_3, %svpn_2, %svpn_1, %svpn_0};" % ((G,) * 8))
A("pf_s2xs = {%ss2xlate_7, %ss2xlate_6, %ss2xlate_5, %ss2xlate_4, %ss2xlate_3, %ss2xlate_2, %ss2xlate_1, %ss2xlate_0};" % ((G,) * 8))
# CSR
A("if ($urandom_range(0, 63) != 0) @io_csr_satp_asid = 16'h12;")
A("if ($urandom_range(0, 63) != 0) @io_csr_vsatp_asid = 16'h34;")
A("if ($urandom_range(0, 63) != 0) @io_csr_hgatp_vmid = 16'h5;")
for s in ["io_sfence_valid", "io_csr_satp_changed", "io_csr_vsatp_changed", "io_csr_hgatp_changed", "io_csr_priv_virt_changed"]:
    A("@%s = ($urandom_range(0, 499) == 0);" % s)
# ITLB 请求
for w in range(3):
    A("@io_tlb_req_%d_valid = (@mode %% 8 == 7) ? 1'($urandom) : ($urandom_range(0, 15) == 0);" % w)
    A("if ($urandom_range(0, 3) != 0) @io_tlb_req_%d_bits_vpn = pf_pool[$urandom_range(0, 7)];" % w)
    A("@io_tlb_req_%d_bits_s2xlate = pf_s2x(@mode);" % w)
# L2TLB
A("@io_ptw_req_0_ready = ($urandom_range(0, 7) != 0);")
A("@io_ptw_resp_valid = (@mode % 8 == 6) ? ($urandom_range(0, 15) == 0) : 1'($urandom);")
A("if ($urandom_range(0, 3) == 0) begin pf_tvpn = pf_pool[$urandom_range(0, 7)]; pf_ts2x = pf_s2x(@mode); end")
A("else begin pf_tvpn = pf_vpns[$urandom_range(0, 7)]; pf_ts2x = pf_s2xs[$urandom_range(0, 7)]; end")
A("if ($urandom_range(0, 7) != 0) begin")
A("  @io_ptw_resp_bits_s2xlate = pf_ts2x;")
A("  @io_ptw_resp_bits_s1_entry_tag = pf_tvpn[37:3];")
A("  @io_ptw_resp_bits_s1_addr_low = pf_tvpn[2:0];")
A("  @io_ptw_resp_bits_s2_entry_tag = pf_tvpn;")
A("end")
A("if ($urandom_range(0, 7) != 0) @io_ptw_resp_bits_s1_entry_asid = (pf_ts2x == 2'd0) ? @io_csr_satp_asid : @io_csr_vsatp_asid;")
A("if ($urandom_range(0, 7) != 0) @io_ptw_resp_bits_s1_entry_vmid = @io_csr_hgatp_vmid[13:0];")
A("if ($urandom_range(0, 7) != 0) @io_ptw_resp_bits_s2_entry_vmid = @io_csr_hgatp_vmid[13:0];")
A("if ($urandom_range(0, 1)) @io_ptw_resp_bits_s1_entry_level = 2'd0;")
A("if ($urandom_range(0, 1)) @io_ptw_resp_bits_s2_entry_level = 2'd0;")
A("@io_ptw_resp_bits_s1_entry_n = ($urandom_range(0, 7) == 0);")
A("@io_ptw_resp_bits_s2_entry_n = ($urandom_range(0, 7) == 0);")
A("@io_ptw_resp_bits_s1_entry_perm_g = ($urandom_range(0, 3) == 0);")
A("if ($urandom_range(0, 7) != 0) @io_ptw_resp_bits_s1_valididx_0 = 1'b1;")
STIM = "\n".join(L)
# 上面最后一行把 valididx[0] 压成多数拍为 1；其余位随机。请求的 vpn[2:0] 随机，所以 1/8 命中位 0。

COV = [
    ("enq", G + "do_enq"),
    ("enq2plus", G + "do_enq && %s_enqNum_T_2 >= 2'd2" % G),
    ("enq_blocked", "(|{%sreqs_0_valid, %sreqs_1_valid, %sreqs_2_valid}) && !%scanEnqueue" % (G, G, G, G)),
    ("ready_low", "!@io_tlb_req_0_ready"),
    ("full", G + "counter == 4'd8"),
    ("deq", G + "do_deq"),
    ("iss_fire", "@io_ptw_req_0_valid && @io_ptw_req_0_ready"),
    ("iss_skip_dead", "!%s_GEN_15 && !%sisEmptyIss" % (G, G)),
    ("inflight_full", G + "inflight_counter == 4'd8"),
    ("resp_hit_entry", "@io_ptw_resp_valid && (|{%sptwResp_OldMatchVec_0, %sptwResp_OldMatchVec_3, %sptwResp_OldMatchVec_7})" % (G, G, G)),
    ("resp_miss_all", "@io_ptw_resp_valid && !%sptwResp_valid_last_REG" % G),
    ("tlb_resp", "@io_tlb_resp_valid"),
    ("fake_enq", G + "reqs_0_valid && %scanEnqueue && %stlb_req_flushed_0" % (G, G)),
    ("merge_last_resp", "@io_tlb_req_1_valid && !%stlb_req_1_valid_last_REG" % G),
    ("merge_old", G + "tlb_req_0_valid_last_REG && %soldMatchVec_last_REG" % G),
    ("merge_port", G + "tlb_req_2_valid_last_REG && (%snewMatchVec_last_REG_6 || %snewMatchVec_last_REG_7)" % (G, G)),
    ("flush", G + "_flush_delay_io_out"),
    ("flush_kills_resp", G + "_flush_delay_io_out && %sptwResp_valid_last_REG" % G),
    ("hit_noS2", "@io_ptw_resp_valid && @io_ptw_resp_bits_s2xlate == 2'd0 && %sptwResp_OldMatchVec_1" % G),
    ("hit_onlyS2", "@io_ptw_resp_valid && @io_ptw_resp_bits_s2xlate == 2'd2 && %sptwResp_OldMatchVec_1" % G),
    ("hit_allS1", "@io_ptw_resp_valid && @io_ptw_resp_bits_s2xlate[0] && %sptwResp_OldMatchVec_1" % G),
    ("hit_napot", "@io_ptw_resp_valid && @io_ptw_resp_bits_s1_entry_n && %sptwResp_OldMatchVec_1" % G),
    ("hit_super", "@io_ptw_resp_valid && @io_ptw_resp_bits_s1_entry_level != 2'd0 && %sptwResp_OldMatchVec_1" % G),
    ("hit_g", "@io_ptw_resp_valid && @io_ptw_resp_bits_s1_entry_perm_g && @io_ptw_resp_bits_s1_entry_asid != @io_csr_satp_asid && %sptwResp_OldMatchVec_1" % G),
    ("getGpa", "@io_tlb_resp_valid && @io_tlb_resp_bits_data_getGpa"),
]

ARM = ["pf_enq_total >= 8", "@io_tlb_req_0_valid", "@io_tlb_req_1_valid", "@io_tlb_req_2_valid", "@io_ptw_resp_valid"]

PAIRS = [
    Pair("PTWFilter", "pf_", clocked=True, stim=STIM, cov=COV, decls=DECLS, arm=ARM, arm_delay=2,
         mode_period=1000, reset_period=50000, cov_min=50),
]

HEADER = """自动生成：verif/ut/PTWFilter/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
PTWFilter 双例化逐拍比对：golden PTWFilter vs 重写 PTWFilter_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
