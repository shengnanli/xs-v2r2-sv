#!/usr/bin/env python3
"""生成 LoadPipe 的双例化 UT testbench（tb.sv）。

golden LoadPipe vs 重写 LoadPipe_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位比全部输出。
激励（让 tag 命中 / 权限表 / ECC / 各类 nack 都真的发生）：
  · paddr 的两份复制通常相同，1/8 概率 _dup_lsu 的 tag 位不同（BtoT 判定用的是 _dup_lsu）；
  · 每一路 tag：1/3 概率 = 本拍 paddr 的 tag（命中候选），其余随机；
    ECC 位 7/8 概率按 SECDED 正确编码，1/8 随机（→ tag ECC 错）；
  · cmd：一半 M_XRD，其余在 {PFR, PFW, XLR, XWR, AMO…} 与全随机之间；instrtype 1/4 为预取源 3；
  · CtrlUnit 伪错误 1/16 概率 valid；load128Req 1/4；s1/s2 kill 各 1/8；各 ready 3/4 为 1。
不复位的流水寄存器：golden s2_valid 出现过之后才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
function automatic logic [6:0] tb_tag_ecc(input logic [35:0] t);
  logic [5:0] p;
  p[0] = ^(t & 36'h556AAAD5B);
  p[1] = ^(t & 36'h99B33366D);
  p[2] = ^(t & 36'h1E3C3C78E);
  p[3] = ^(t & 36'hE03FC07F0);
  p[4] = ^(t & 36'h003FFF800);
  p[5] = ^(t & 36'hFFC000000);
  return {^{p, t}, p};
endfunction
function automatic logic [42:0] tb_tag_word(input logic [35:0] ptag);
  logic [35:0] t;
  t = ($urandom_range(0, 2) == 0) ? ptag : 36'({$urandom, $urandom});
  if ($urandom_range(0, 7) == 0) return {7'($urandom), t};
  return {tb_tag_ecc(t), t};
endfunction
function automatic logic [4:0] tb_cmd();
  case ($urandom_range(0, 7))
    0, 1, 2, 3: return 5'h00;
    4: return 5'h02;
    5: return 5'h03;
    6: begin
      logic [4:0] c [8] = '{5'h06, 5'h01, 5'h04, 5'h08, 5'h0C, 5'h11, 5'h07, 5'h1A};
      return c[$urandom_range(0, 7)];
    end
    default: return 5'($urandom);
  endcase
endfunction
"""

STIM = """
@io_lsu_s1_paddr_dup_lsu = @io_lsu_s1_paddr_dup_dcache;
if ($urandom_range(0, 7) == 0) @io_lsu_s1_paddr_dup_lsu[47:12] = 36'({$urandom, $urandom});
@io_tag_resp_0 = tb_tag_word(@io_lsu_s1_paddr_dup_dcache[47:12]);
@io_tag_resp_1 = tb_tag_word(@io_lsu_s1_paddr_dup_dcache[47:12]);
@io_tag_resp_2 = tb_tag_word(@io_lsu_s1_paddr_dup_dcache[47:12]);
@io_tag_resp_3 = tb_tag_word(@io_lsu_s1_paddr_dup_dcache[47:12]);
@io_lsu_req_bits_cmd = tb_cmd();
@io_lsu_req_bits_instrtype = ($urandom_range(0, 3) == 0) ? 4'h3 : 4'($urandom);
@io_pseudo_error_valid = ($urandom_range(0, 15) == 0);
@io_load128Req = ($urandom_range(0, 3) == 0);
@io_lsu_s1_kill = ($urandom_range(0, 7) == 0);
@io_lsu_s2_kill = ($urandom_range(0, 7) == 0);
@io_lsu_s1_kill_data_read = ($urandom_range(0, 7) == 0);
@io_tag_read_ready = ($urandom_range(0, 3) != 0);
@io_banked_data_read_ready = ($urandom_range(0, 3) != 0);
@io_miss_req_ready = ($urandom_range(0, 3) != 0);
@io_wbq_block_miss_req = ($urandom_range(0, 7) == 0);
@io_bank_conflict_slow = ($urandom_range(0, 7) == 0);
@io_occupy_fail = ($urandom_range(0, 3) == 0);
@io_read_error_delayed_0 = ($urandom_range(0, 7) == 0);
@io_read_error_delayed_1 = ($urandom_range(0, 7) == 0);
@io_counter_filter_query_resp = ($urandom_range(0, 1) == 0);
if (@mode[1:0] == 2'd0) @io_lsu_req_valid = 1'b1;
"""

G = "lp_u_gold."
COV = [
    ("s1_hit", G + "s1_valid && " + G + "s1_tag_match_dup_dc && " + G + "s1_has_permission"),
    ("s1_hit_noperm", G + "s1_valid && " + G + "s1_tag_match_dup_dc && !" + G + "s1_has_permission"),
    ("s2_real_miss", "@io_lsu_resp_valid && @io_lsu_resp_bits_miss"),
    ("miss_fire", "@io_miss_req_valid && @io_miss_req_ready && !@io_miss_req_bits_cancel"),
    ("nack_no_mshr", G + "s2_nack_no_mshr"),
    ("nack_data", G + "s2_valid && " + G + "s2_nack_data"),
    ("tag_error", G + "s2_valid && (|" + G + "s2_tag_errors)"),
    ("btot", G + "s2_valid && " + G + "s2_grow_perm_btot"),
    ("btot_occupy_fail", G + "s2_valid && " + G + "s2_btot_occupy_fail"),
    ("handled", "@io_lsu_resp_valid && @io_lsu_resp_bits_handled"),
    ("pseudo_tag", G + "s1_valid && @io_pseudo_error_valid && @io_pseudo_error_bits_0_valid"),
    ("error_valid", "@io_error_valid"),
    ("data_error_128", G + "s3_valid && " + G + "s3_load128Req && " + G + "s3_data_error"),
    ("pf_counted", "@io_prefetch_flag_write_valid"),
    ("pf_filtered", "@io_counter_filter_query_req_valid && @io_counter_filter_query_resp"),
    ("late_prefetch_hit", "@io_prefetch_info_naive_late_prefetch_hit"),
    ("pollution", "@io_prefetch_info_fdp_pollution"),
    ("replace_access", "@io_replace_access_valid"),
]

# 结构上恒 0 的输出位（行地址低 6 位、性能值高 5 位），不要求见过 1
EXEMPT = ([f"io_miss_req_bits_addr[{b}]" for b in range(6)] +
          [f"io_wbq_conflict_check_bits[{b}]" for b in range(6)] +
          [f"io_perf_{i}_value[{b}]" for i in range(7) for b in range(1, 6)])

PAIRS = [
    Pair("LoadPipe", "lp_", clocked=True, stim=STIM, cov=COV, decls=DECLS, exempt=EXEMPT,
         mode_period=2000, reset_period=50000, cov_min=200,
         arm=[G + "s2_valid"]),
]

HEADER = """自动生成：verif/ut/LoadPipe/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
LoadPipe 双例化逐拍比对：golden LoadPipe vs 重写 LoadPipe_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
