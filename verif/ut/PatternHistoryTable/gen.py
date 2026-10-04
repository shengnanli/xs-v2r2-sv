#!/usr/bin/env python3
"""生成 PatternHistoryTable 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden PatternHistoryTable vs PatternHistoryTable_xs（child 两侧各用各的：golden 侧 golden child，
重写侧本仓重写 child；厂商 SRAM 宏 sram_array_1p32x148m74s1h0l1b_pftch_pht / array_12 两侧共用 golden 行为模型），
全部输出逐拍逐位 !==。
激励偏置（让表真的学到模式、查得到、发得出预取）：
  * agt_update / s2_agt_lookup 的 pht_index 取 0..3、pht_tag 取 6 个固定值之一 —— 组和 tag 都撞得上；
  * update：region_offset 随机，region_bits 随机，single_update 1/4，has_been_signal_updated 1/4，
    access_cnt 随机（> 4 与 <= 4 都有）；
  * lookup：region_vaddr 低 2 位常落在 0 / 3（下一 / 上一区域跨 4KB 页），其余随机；
  * update / lookup valid 各 1/2；
  * MBIST / SRAM DFT 口 15/16 时间钉 0。
不复位寄存器（s4 三个预取请求的数据寄存器经仲裁器直出；SRAM 的 MBIST 读回寄存器 rdataReg 直出
boreChildrenBd_bore_rdata）：三种预取请求都发生过一次、SRAM 读过一次之后再过 1 拍才开始比（arm）。
厂商 SRAM 行为模型的存储阵列上电初值：0 时刻后把重写侧拷成 golden 侧（见 DECLS）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DFT = ["boreChildrenBd_bore_re", "boreChildrenBd_bore_we", "boreChildrenBd_bore_ack",
       "boreChildrenBd_bore_selectedOH", "boreChildrenBd_bore_array", "boreChildrenBd_bore_wmask",
       "sigFromSrams_bore_ram_hold", "sigFromSrams_bore_ram_bypass", "sigFromSrams_bore_ram_bp_clken",
       "sigFromSrams_bore_ram_aux_clk", "sigFromSrams_bore_ram_aux_ckbp",
       "sigFromSrams_bore_ram_mcp_hold", "sigFromSrams_bore_cgen"]
X = "ph_"
G = X + "u_gold"

STIM = "\n".join([
    "@io_agt_update_valid = ($urandom_range(0, 1) != 0);",
    "@io_agt_update_bits_pht_index = 5'($urandom_range(0, 3));",
    "@io_agt_update_bits_pht_tag = ph_tags[$urandom_range(0, 5)];",
    "@io_agt_update_bits_single_update = ($urandom_range(0, 3) == 0);",
    "@io_agt_update_bits_has_been_signal_updated = ($urandom_range(0, 3) == 0);",
    "@io_s2_agt_lookup_valid = ($urandom_range(0, 1) != 0);",
    "@io_s2_agt_lookup_bits_pht_index = 5'($urandom_range(0, 3));",
    "@io_s2_agt_lookup_bits_pht_tag = ph_tags[$urandom_range(0, 5)];",
    "case ($urandom_range(0, 3))",
    "  0: @io_s2_agt_lookup_bits_region_vaddr[1:0] = 2'b00;",
    "  1: @io_s2_agt_lookup_bits_region_vaddr[1:0] = 2'b11;",
    "  default: ;",
    "endcase",
    "if (ph_mode != 0) begin",
] + ["  @%s = '0;" % d for d in DFT] + ["end"])

DECLS = """
logic [12:0] ph_tags [6];
initial for (int i = 0; i < 6; i++) ph_tags[i] = 13'($urandom);
// 厂商 SRAM 行为模型（两侧同一份 golden array_12_ext）的存储阵列与读地址寄存器上电不复位：
// +vcs+initreg+<seed> 下两个实例各摇各的初值，MBIST 读到没写过的行时两侧不同（与重写无关）。
// 0 时刻之后把重写侧拷成 golden 侧（普通 always 驱动的变量，可直接过程赋值；只对齐上电初值）。
initial begin
  #1;
  for (int k = 0; k < 32; k++)
    ph_u_impl.pht_ram.array.array.array_12_ext.ram[k] = ph_u_gold.pht_ram.array.array.array_12_ext.ram[k];
  ph_u_impl.pht_ram.array.array.array_12_ext.reg_RW0_addr = ph_u_gold.pht_ram.array.array.array_12_ext.reg_RW0_addr;
  ph_u_impl.pht_ram.array.array.array_12_ext.reg_RW0_ren = ph_u_gold.pht_ram.array.array.array_12_ext.reg_RW0_ren;
end
"""

COV = [
    ("evict_hit",    "%s.s2_valid_last_REG && %s.s2_evict && (|%s._s2_pht_hit_T)" % (G, G, G)),
    ("evict_miss",   "%s.s2_valid_last_REG && %s.s2_evict && !(|%s._s2_pht_hit_T)" % (G, G, G)),
    ("lookup_hit",   "%s.s2_valid_last_REG && !%s.s2_evict && (|%s._s2_pht_hit_T)" % (G, G, G)),
    ("single_skip",  "%s.s2_valid_last_REG && %s.s2_single_update && !(|%s._s2_pht_hit_T) && %s.s2_access_cnt_signal <= 4" % (G, G, G, G)),
    ("s1_wait",      "%s.s1_valid_r && %s.s1_wait" % (G, G)),
    ("cur_req",      "%s.s3_cur_region_valid" % G),
    ("incr_req",     "%s.s3_incr_region_valid" % G),
    ("decr_req",     "%s.s3_decr_region_valid" % G),
    ("incr_held",    "%s.s4_pf_gen_incr_region_valid && !%s._pf_gen_req_arb_io_in_1_ready" % (G, G)),
    ("crosspage",    "@io_pf_gen_req_valid && !@io_pf_gen_req_bits_paddr_valid"),
    ("pf_out",       "@io_pf_gen_req_valid"),
    ("reset_mid",    "@reset && cyc > 100"),
]

PAIRS = [Pair("PatternHistoryTable", X, clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=20000, mode_period=2000, cov_min=5,
              arm=["%s.s3_cur_region_valid" % G, "%s.s3_incr_region_valid" % G, "%s.s3_decr_region_valid" % G,
                   "%s.pht_ram.respReg" % G],
              arm_delay=1)]

HEADER = """自动生成：verif/ut/PatternHistoryTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
PatternHistoryTable 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
