#!/usr/bin/env python3
"""生成 ITTage 的双例化 UT testbench（tb.sv）。

golden ITTage（+ golden ITTageTable×5 / RegionWays / LFSR）vs 重写 ITTage_xs（+ 已签重写子模块），
scripts/dual_tb_lib.py，端口表读 G1 golden，逐拍比全部输出（透传、S3 jalr_target、meta、s1_ready、MBIST）。

激励要点：
  · 预测 PC / 更新 PC 从 16 项小池子取；ghist 与 4 份折叠历史在大部分阶段同时为 0（两者天然一致，
    更新时写进表的项在预测时能被同样的 PC 查中 —— provider/alt 命中、区域表命中都靠它），其余阶段全随机；
  · 更新 75% 是"真正的间接跳转"（tailSlot 有效非共享、isJalr、非 ret、跳、cfi 位置 = tailSlot），
    full_target 从 8 项小池子取（一半与 PC 同区域 -> usePCRegion，一半不同 -> 写 RegionWays）；
  · meta 全随机（provider/alt/allocate 的有效位与表号、ctr、目标；表号 5..7 的非法值也会出现）；
  · ★前 3000 拍只做"不触发表更新"的 update（tailSlot 无效），且 meta 的各有效位全 1、providerCtr=0、cfi 有效 ——
    把 updateMeta_* / update_cfi_idx 这些按各自有效位才锁存的无复位寄存器先灌成确定值，再进入自由激励★；
  · MBIST 口与 SRAM 广播控制位平时钉 0。复位只打上电那一次（表项 SRAM 无复位，中途复位不会让两侧重新对齐）。
比较窗口：S3 目标 / meta 寄存器不复位 —— 等 golden 四份 s2_fire 都见过（且过了上面的灌值阶段）再开比。
覆盖（golden 内部语义信号）：provider 命中 / alt 命中 / 用 alt 目标 / base 目标 / 区域表命中 / 分配 / 写 RegionWays /
  reset_u（tick 满）/ 更新 provider / 更新 alt。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

DECLS = """
logic [49:0] t_pc_pool [16];
logic [49:0] t_tg_pool [8];
initial begin
  for (int k = 0; k < 16; k++) t_pc_pool[k] = {$urandom, $urandom} & ~50'h1;
  for (int k = 0; k < 8; k++) t_tg_pool[k] = (k < 4) ? {t_pc_pool[k][49:20], 20'($urandom) & ~20'h1} : ({$urandom, $urandom} & ~50'h1);
end
"""
g = "t_u_gold"
FH = ["hist_14", "hist_13", "hist_12", "hist_10", "hist_6", "hist_4", "hist_3", "hist_2"]
zero_fh = "\n".join("  @%s = '0;" % n for _, _, n in golden_ports("ITTage") if "_folded_hist" in n)
STIM = """
@io_in_bits_s0_pc_0 = t_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_1 = t_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_2 = t_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_3 = t_pc_pool[$urandom_range(0, 15)];
@io_update_bits_pc = t_pc_pool[$urandom_range(0, 15)];
@io_update_bits_full_target = t_tg_pool[$urandom_range(0, 7)];
@io_update_valid = ($urandom_range(0, 1) == 0);
if (t_mode < 12) begin
  @io_update_bits_ghist = '0;
%s
end
if ($urandom_range(0, 3) != 0) begin
  @io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
  @io_update_bits_ftb_entry_isJalr = 1'b1;
  @io_update_bits_ftb_entry_isRet = 1'b0;
  @io_update_bits_ftb_entry_tailSlot_sharing = 1'b0;
  @io_update_bits_jmp_taken = 1'b1;
  @io_update_bits_cfi_idx_valid = 1'b1;
  @io_update_bits_cfi_idx_bits = @io_update_bits_ftb_entry_tailSlot_offset;
  @io_update_bits_ftb_entry_strong_bias_1 = 1'b0;
end
if ($urandom_range(0, 1)) @io_update_bits_meta[163:114] = t_tg_pool[$urandom_range(0, 7)];
if ($urandom_range(0, 1)) @io_update_bits_meta[113:64] = t_tg_pool[$urandom_range(0, 7)];
if (cyc < 3000) begin
  @io_update_valid = 1'b1;
  @io_update_bits_ftb_entry_tailSlot_valid = 1'b0;
  @io_update_bits_meta[181] = 1'b1; @io_update_bits_meta[177] = 1'b1; @io_update_bits_meta[167] = 1'b1;
  @io_update_bits_meta[171:170] = 2'b0; @io_update_bits_cfi_idx_valid = 1'b1;
end
if (t_mode >= 10 && t_mode <= 13) @io_update_bits_meta[167] = 1'b0;
if (t_mode < 14) begin
@boreChildrenBd_bore_req = 1'b0; @boreChildrenBd_bore_all = 1'b0;
@boreChildrenBd_bore_1_req = 1'b0; @boreChildrenBd_bore_1_all = 1'b0;
@boreChildrenBd_bore_2_req = 1'b0; @boreChildrenBd_bore_2_all = 1'b0;
@boreChildrenBd_bore_3_req = 1'b0; @boreChildrenBd_bore_3_all = 1'b0;
@boreChildrenBd_bore_4_req = 1'b0; @boreChildrenBd_bore_4_all = 1'b0;
%s
end
""" % (zero_fh, "\n".join("@sigFromSrams_bore%s_%s = 1'b0;" % (s, f) for s in ["", "_1", "_2", "_3", "_4", "_5", "_6", "_7"]
                         for f in ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk", "ram_aux_ckbp", "ram_mcp_hold", "cgen"]))

tv = lambda k: "%s._tables_%d_io_resp_valid" % (g, k)
pair = Pair("ITTage", "t_", clocked=True, reset_period=40000, stim=STIM, decls=DECLS, mode_period=2000,
            arm=["@io_s2_fire_0", "@io_s2_fire_1", "@io_s2_fire_2", "@io_s2_fire_3", "cyc > 3000"], arm_delay=2,
            cov=[("provider_hit", "@io_s2_fire_3 && %s.selectedInfo_hasOne" % g),
                 ("alt_hit", "@io_s2_fire_3 && %s.selectedInfo_hasTwo" % g),
                 ("use_alt_target", "@io_s2_fire_3 && %s.selectedInfo_hasTwo && %s.providerNull" % (g, g)),
                 ("region_hit", "@io_s2_fire_3 && (%s._rTable_io_resp_hit_0 || %s._rTable_io_resp_hit_4)" % (g, g)),
                 ("allocate", "%s._rTable_io_write_valid_T_1 || %s.updateAlloc_2 || %s.updateAlloc_3 || %s.updateAlloc_4" % (g, g, g, g)),
                 ("rtable_write", "%s.rTable.io_write_valid" % g),
                 ("reset_u", "%s.updateResetU_probe" % g),
                 ("update_provider", "%s._GEN_3" % g),
                 ("update_alt", "%s._GEN_3 && %s._GEN_2" % (g, g))],
            cov_min=10,
            # 结构常量 / 200k 拍内不可能翻的位（不是跑出来再填）：last_stage_meta 只有低 182 位是 ITTageMeta，
            # 高 334 位恒 0；meta[176] = altProvider 表号最高位，alt 是次长命中表、表号至多 3，恒 0；pred_cycle（meta 低 64 位）是自由计数器，复位时清零，UT 平均每 4 万拍复位一次，2^16 拍以上的位（bit16 起）不保证翻。
            exempt=["io_out_last_stage_meta[%d]" % b for b in [176] + list(range(16, 64)) + list(range(182, 516))])
txt = render([pair], header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
