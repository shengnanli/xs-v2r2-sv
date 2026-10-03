#!/usr/bin/env python3
"""生成 ActiveGenerationTable 的双例化 UT testbench（tb.sv）。

golden ActiveGenerationTable vs 重写 ActiveGenerationTable_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
逐拍比全部 17 个输出口。

激励（区域 tag 纯随机几乎不会命中，所以全部偏置）：
  * 区域 tag 取自一个小池子，池子大小按 mode 分四档（6 / 20 / 40 / 12）：小池子让表项长期驻留、
    访问计数涨到 15 封顶；大池子（> 16 项）逼出 PLRU 替换与"有效项被换出"；
  * p1/m1 tag 7/8 概率取 tag±1（真实邻区），1/8 随机；allow_cross 随机；
  * dcache evict 的 vaddr 按哈希反推成池子里的 tag（三段哈希里两段取同一个随机数互相抵消）；
  * region_vaddr 的低 11 位 1/4 概率取 0 或全 1 附近，配合 act_stride 打"预取目标越界"；
  * act_threshold / act_stride / agt_en 低频变化（1/64 概率重抽），lookup valid 按 mode 分 稀疏/半数/背靠背。
不复位寄存器：S2 两组输出寄存器（pht_lookup / evict）在第一次装载之前两侧初值不同（+random 档），
所以在两组各自至少装载过一次之后才开始比（arm）。表项阵列虽不复位，但只在 valid 之后才被读。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [3:0] agt_thr = 4'd2;
logic [5:0] agt_stride = 6'd1;
logic       agt_en_hold = 1'b1;
function automatic logic [10:0] agt_rnd_tag(input int unsigned mode);
  int unsigned pool;
  case (mode % 4)
    0:       pool = 6;
    1:       pool = 20;
    2:       pool = 40;
    default: pool = 12;
  endcase
  // 池内下标 -> tag：低 6 位顺序排，高 5 位（哈希段）在 0/1 间交替，让比较覆盖到高位
  agt_rnd_tag = 11'($urandom_range(0, pool - 1));
  agt_rnd_tag[10:6] = 5'(agt_rnd_tag[0]);
endfunction
"""

STIM = """
logic [10:0] t, et;
logic [4:0]  r;
t = agt_rnd_tag(@mode);
@io_s0_lookup_bits_region_tag = t;
@io_s0_lookup_bits_region_p1_tag = ($urandom_range(0, 7) == 0) ? 11'($urandom) : agt_rnd_tag(@mode);
@io_s0_lookup_bits_region_m1_tag = ($urandom_range(0, 7) == 0) ? 11'($urandom) : agt_rnd_tag(@mode);
case ((@mode / 4) % 3)
  0: @io_s0_lookup_valid = ($urandom_range(0, 5) == 0);
  1: ;
  2: @io_s0_lookup_valid = ($urandom_range(0, 15) != 0);
endcase
et = agt_rnd_tag(@mode);
r  = 5'($urandom);
@io_s0_dcache_evict_bits_vaddr = {19'($urandom), r, r ^ et[10:6], 5'h0, et[5:0], 10'($urandom)};
@io_s0_dcache_evict_bits_vaddr[20:16] = 5'h0 ^ et[10:6] ^ r ^ r;
@io_s0_dcache_evict_bits_vaddr[25:21] = r;
@io_s0_dcache_evict_bits_vaddr[30:26] = r;
if ($urandom_range(0, 3) == 0)
  @io_s0_lookup_bits_region_vaddr[10:0] = $urandom_range(0, 1) ? 11'($urandom_range(0, 3)) : 11'h7ff - 11'($urandom_range(0, 3));
if ($urandom_range(0, 63) == 0) agt_thr = 4'($urandom);
if ($urandom_range(0, 63) == 0) agt_stride = 6'($urandom);
if ($urandom_range(0, 63) == 0) agt_en_hold = ($urandom_range(0, 7) != 0);
@io_act_threshold = agt_thr;
@io_act_stride = agt_stride;
@io_agt_en = agt_en_hold;
"""

G = "agt_u_gold."
cnt15 = " || ".join("(%svalids_%d && %sentries_%d_access_cnt == 4'hf)" % (G, i, G, i) for i in range(16))
has_hist = "%sprev_lookup_valid_last_REG && (%s_io_s1_sel_stride_T || %ss1_update_last_REG)" % (G, G, G)
COV = [
    ("s0_alloc", G + "s0_alloc"),
    ("s0_update", G + "s0_update"),
    ("s0_match_prev_blocks_alloc",
     "@io_s0_lookup_valid && !(|%s_any_region_match_T) && !%ss0_alloc" % (G, G)),
    ("s0_update_conflict", "@io_s0_lookup_valid && (|%s_any_region_match_T) && !%ss0_update" % (G, G)),
    ("s0_do_dcache_evict", G + "s0_do_dcache_evict"),
    ("s0_dcache_evict_blocked_by_lookup", "@io_s0_dcache_evict_valid && @io_s0_lookup_valid"),
    ("s0_dcache_evict_conflict", "@io_s0_dcache_evict_valid && !%s_io_s0_dcache_evict_ready_T_1" % G),
    ("s0_m1_hit", "@io_s0_lookup_valid && %sany_region_m1_match" % G),
    ("s0_p1_hit", "@io_s0_lookup_valid && %sany_region_p1_match" % G),
    ("s1_alloc_decr_mode", "%ss1_alloc_last_REG && %ss1_agt_entry_decr_mode" % (G, G)),
    ("s1_alloc_evicts_valid", "%ss1_alloc_last_REG && %ss1_evict_valid" % (G, G)),
    ("s1_alloc_into_empty", "%ss1_alloc_last_REG && !%ss1_evict_valid" % (G, G)),
    ("s1_dcache_evict", G + "s1_do_dcache_evict_last_REG"),
    ("s1_in_active_page", "%s && %ss1_in_active_page" % (has_hist, G)),
    ("s1_pf_gen_blocks_pht", "%sprev_lookup_valid_last_REG && !%ss1_pht_lookup_valid" % (G, G)),
    ("s1_out_of_range_inc", "%s && %s_s1_pf_gen_vaddr_inc_T_2[15]" % (has_hist, G)),
    ("s1_out_of_range_dec", "%s && %s_s1_pf_gen_vaddr_dec_T_2[15]" % (has_hist, G)),
    ("s1_sel_stride", "@io_s1_sel_stride"),
    ("access_cnt_saturated", cnt15),
    ("s2_pht_lookup", "@io_s2_pht_lookup_valid"),
    ("s2_evict_real", "@io_s2_evict_valid && %ss2_real_update" % G),
    ("s2_evict_real_dropped_onehot", "%ss2_evict_valid_last_REG && %ss2_real_update && !@io_s2_evict_valid" % (G, G)),
    ("s2_evict_single_update", "@io_s2_evict_valid && @io_s2_evict_bits_single_update"),
    ("s2_evict_has_been_updated", "@io_s2_evict_valid && @io_s2_evict_bits_has_been_signal_updated"),
    ("s2_evict_decr", "@io_s2_evict_valid && @io_s2_evict_bits_decr_mode"),
    ("agt_disabled", "!@io_agt_en"),
]

PAIRS = [
    Pair("ActiveGenerationTable", "agt_", clocked=True, stim=STIM, decls=DECLS, cov=COV,
         mode_period=3000, reset_period=12000, cov_min=100,
         arm=["@io_s2_pht_lookup_valid", G + "s2_evict_valid_last_REG"]),
]

HEADER = """自动生成：verif/ut/ActiveGenerationTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
ActiveGenerationTable 双例化逐拍比对：golden vs 重写 ActiveGenerationTable_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
