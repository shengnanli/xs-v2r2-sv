#!/usr/bin/env python3
"""生成 SCTable 家族（SCTable / _1 / _2 / _3）的双例化 UT testbench（tb.sv）。

四对 golden <V> vs 重写 <V>_xs 同 tb 并跑（scripts/dual_tb_lib.py，端口表读 G1 golden），逐拍比全部输出。
子模块：golden 侧接 golden SRAMTemplate_68 / WrBypass_33 / MbistPipeSc_N，重写侧接本仓重写件（均已签核）；
两侧共读同一份厂商 SRAM 宏链（sram_array_1p128x24m6s1h0l1b_bp_sc -> array_5 -> array_5_ext.v）。

激励要点（判别力来自哪里）：
  · 读 pc 与更新 pc 从同一个 24 项小池子取（池子里各项的 pc[8:1] 互不相同但只差几位），
    ghist / 折叠历史也从 4 项小池取 —— 同一行反复被读、被连续更新，写旁路（16 项）经常命中；
  · update.mask 各 1/2 概率，tagePreds / takens 随机，oldCtrs 一半取饱和边界（+31 / -32 / ±0 附近），
    一半随机 —— 饱和 ±1 的四条分支都走到；
  · 读写同拍同 bank（冲突清零）自然高频发生；
  · MBIST 测试口与 SRAM 广播控制位平时钉 0（否则 SRAM 一直被测试口占着），mode>=13 的阶段（3/16）全随机。
比较窗口：SRAM 读出保持寄存器与 s1_* 寄存器不复位 —— 等 golden 两个 bank 各完成过一次读（ren）再开比。
覆盖（golden 内部语义信号）：冲突清零、写旁路命中且该路有效、饱和 +31/-32 停住、两个 bank 都被写过。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

VARIANTS = [("SCTable", "s0_", None), ("SCTable_1", "s1_", "io_req_bits_folded_hist_hist_12_folded_hist"),
            ("SCTable_2", "s2_", "io_req_bits_folded_hist_hist_11_folded_hist"),
            ("SCTable_3", "s3_", "io_req_bits_folded_hist_hist_2_folded_hist")]

DECLS = """
logic [49:0] {p}pc_pool [24];
logic [255:0] {p}gh_pool [4];
initial begin
  for (int k = 0; k < 24; k++) {p}pc_pool[k] = {{$urandom, $urandom}} ^ (50'(k) << 1);
  for (int k = 0; k < 4; k++) {p}gh_pool[k] = {{8{{$urandom}}}};
end
function automatic logic [5:0] {p}pick_ctr();
  case ($urandom_range(0, 7))
    0: return 6'h1F; 1: return 6'h20; 2: return 6'h1E; 3: return 6'h21; 4: return 6'h00; 5: return 6'h3F;
    default: return 6'($urandom);
  endcase
endfunction
"""

STIM = """
@io_req_bits_pc = {p}pc_pool[$urandom_range(0, 23)];
@io_update_pc = {p}pc_pool[$urandom_range(0, 23)];
@io_update_oldCtrs_0 = {p}pick_ctr();
@io_update_oldCtrs_1 = {p}pick_ctr();
{hist}
if ({p}mode < 13) begin
  @boreChildrenBd_bore_req = 1'b0; @boreChildrenBd_bore_all = 1'b0;
  @boreChildrenBd_bore_array = 7'h0; @boreChildrenBd_bore_writeen = 1'b0; @boreChildrenBd_bore_readen = 1'b0;
  @sigFromSrams_bore_ram_hold = 1'b0; @sigFromSrams_bore_ram_bypass = 1'b0; @sigFromSrams_bore_ram_bp_clken = 1'b0;
  @sigFromSrams_bore_ram_aux_clk = 1'b0; @sigFromSrams_bore_ram_aux_ckbp = 1'b0; @sigFromSrams_bore_ram_mcp_hold = 1'b0;
  @sigFromSrams_bore_cgen = 1'b0;
  @sigFromSrams_bore_1_ram_hold = 1'b0; @sigFromSrams_bore_1_ram_bypass = 1'b0; @sigFromSrams_bore_1_ram_bp_clken = 1'b0;
  @sigFromSrams_bore_1_ram_aux_clk = 1'b0; @sigFromSrams_bore_1_ram_aux_ckbp = 1'b0; @sigFromSrams_bore_1_ram_mcp_hold = 1'b0;
  @sigFromSrams_bore_1_cgen = 1'b0;
end
"""

pairs = []
for top, p, fh in VARIANTS:
    hist = ""
    if fh:
        hist = ("@%s = {p}gh_pool[$urandom_range(0, 3)][7:0] ^ 8'($urandom_range(0, 1));\n"
                "@io_update_ghist = {p}gh_pool[$urandom_range(0, 3)];" % fh)
    g = p + "u_gold"
    cov = [
        ("conflict_zeroed", "%s.s1_resp_invalid_by_conflict && !@reset" % g),
        ("bypass_hit_valid_br0", "@io_update_mask_0 && %s._wrbypasses_0_io_hit && "
                                 "(%s._wrbypasses_0_io_hit_data_0_valid || %s._wrbypasses_0_io_hit_data_1_valid)" % (g, g, g)),
        ("bypass_hit_valid_br1", "@io_update_mask_1 && %s._wrbypasses_1_io_hit && "
                                 "(%s._wrbypasses_1_io_hit_data_0_valid || %s._wrbypasses_1_io_hit_data_1_valid)" % (g, g, g)),
        ("sat_pos_hold", "%s.update_wdata_0 == 6'h1F && %s.oldCtr == 6'h1F" % (g, g)),
        ("sat_neg_hold", "%s.update_wdata_1 == 6'h20 && %s.oldCtr_1 == 6'h20" % (g, g)),
        ("bank0_write", "%s.table_0.io_w_req_valid && !%s.table_0._resetState" % (g, g)),
        ("bank1_write", "%s.table_1.io_w_req_valid && !%s.table_1._resetState" % (g, g)),
    ]
    pairs.append(Pair(top, p, clocked=True, reset_period=40000,
                      stim=STIM.format(p=p, hist=hist.format(p=p)),
                      decls=DECLS.format(p=p),
                      cov=cov, cov_min=100,
                      arm=["%s.table_0.ren" % g, "%s.table_1.ren" % g], arm_delay=2,
                      mode_period=2000))

txt = render(pairs, header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
