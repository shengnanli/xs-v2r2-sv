#!/usr/bin/env python3
"""生成 Tage_SC 的双例化 UT testbench（tb.sv）。

golden Tage_SC（+ golden 子模块）vs 重写 Tage_SC_xs（+ 已签重写子模块），scripts/dual_tb_lib.py，端口表读 G1 golden，
逐拍比全部输出（透传、S2/S3 方向、sc_disagree、meta、s1_ready、perf、MBIST）。

激励要点：
  · 预测 PC / 更新 PC 从 16 项小池子取；ghist 与全部折叠历史在大部分阶段同时为 0（两者天然一致，
    更新写进 TageTable / SCTable 的项在预测时能被同样的 PC 查中），其余阶段全随机；
  · 更新 75% 让两个槽都是有效条件分支（brSlot 有效、tailSlot 有效且共享、非 strong_bias），
    taken / mispred 随机；meta 全随机，但 provider/altUsed/allocates/SC 计数器偏向能触发各更新路径的取值；
  · ★前 3000 拍只做"不更新任何表"的 update（两个槽都无效），但 meta 的 provider.valid 与槽有效位全 1 ——
    把只在各自使能下锁存的 updateMeta_* 无复位寄存器先灌成确定值★（需要 brSlot/tailSlot 有效才锁存的那几个，
    在这段里让 strong_bias=1：槽有效但 updateValids=0，不触发表更新）；
  · tage_enable / sc_enable 按阶段开关；MBIST 口与 SRAM 广播控制位平时钉 0，mode>=14 阶段全随机；
  · 复位每 ~40000 拍一次（中途复位后各表 SRAM 复位扫描期间 req_ready 拉低，s1_ready 才会翻；复位前两侧状态相同）。
比较窗口：S2/S3 寄存器不复位 —— 等 golden 四份 s1_fire / s2_fire 都见过且过了灌值阶段再开比；
  ★perf 输出用到的 S2 寄存器（s2_provideds 等）同样只在 s1_fire 时写、无复位，比较窗口晚于它们的首次写入★。
覆盖（golden 内部语义信号）：provider 命中 / 用 alt / useAltOnNa 计数器更新 / 分配 / tick 涨满 reset_u /
  SC 推翻 TAGE / SC 更新 / 阈值调整 / 基础表更新。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

PORTS = golden_ports("Tage_SC")
zero_fh = "\n".join("  @%s = '0;" % n for _, _, n in PORTS if "_folded_hist" in n)
mbist_off = "\n".join("  @%s = '0;" % n for d, _, n in PORTS
                      if d == "input" and (n.endswith("_req") or n.endswith("_all") or n.startswith("sigFromSrams")))

DECLS = """
logic [49:0] g_pc_pool [16];
initial for (int k = 0; k < 16; k++) g_pc_pool[k] = {$urandom, $urandom} & ~50'h1;
"""
STIM = """
@io_in_bits_s0_pc_0 = g_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_1 = g_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_2 = g_pc_pool[$urandom_range(0, 15)];
@io_in_bits_s0_pc_3 = g_pc_pool[$urandom_range(0, 15)];
@io_update_bits_pc = g_pc_pool[$urandom_range(0, 15)];
@io_update_valid = ($urandom_range(0, 1) == 0);
@io_ctrl_tage_enable = (g_mode != 5);
@io_ctrl_sc_enable = (g_mode != 6);
if (g_mode < 12) begin
  @io_in_bits_ghist = '0;
  @io_update_bits_ghist = '0;
%s
end
if ($urandom_range(0, 3) != 0) begin
  @io_update_bits_ftb_entry_brSlots_0_valid = 1'b1;
  @io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
  @io_update_bits_ftb_entry_tailSlot_sharing = 1'b1;
  @io_update_bits_ftb_entry_strong_bias_0 = 1'b0;
  @io_update_bits_ftb_entry_strong_bias_1 = 1'b0;
  if ($urandom_range(0, 1)) @io_update_bits_br_taken_mask_0 = 1'b0;
end
// meta 偏置：provider 有效、ctr 落在不自信区 3/4 的概率提高；allocates 有时全 0（分配失败，tick 涨）
if ($urandom_range(0, 1)) @io_update_bits_meta[133:131] = 3'($urandom_range(3, 4));
if ($urandom_range(0, 1)) @io_update_bits_meta[137:135] = 3'($urandom_range(3, 4));
if (g_mode >= 9 && g_mode <= 11) @io_update_bits_meta[123:116] = 8'h0;
if (cyc < 3000) begin
  @io_update_valid = 1'b1;
  @io_update_bits_ftb_entry_brSlots_0_valid = 1'b1;
  @io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
  @io_update_bits_ftb_entry_tailSlot_sharing = 1'b1;
  @io_update_bits_ftb_entry_strong_bias_0 = 1'b1;
  @io_update_bits_ftb_entry_strong_bias_1 = 1'b1;
  @io_update_bits_meta[140] = 1'b1; @io_update_bits_meta[143] = 1'b1;
end
if (g_mode < 14) begin
%s
end
""" % (zero_fh, mbist_off)

g = "g_u_gold"
arm = ["@io_s1_fire_%d" % d for d in range(4)] + ["@io_s2_fire_%d" % d for d in range(4)] + ["cyc > 3000"]
pair = Pair("Tage_SC", "g_", clocked=True, reset_period=40000, stim=STIM, decls=DECLS, mode_period=2000,
            arm=arm, arm_delay=3,
            cov=[("provider_hit", "@io_s1_fire_1 && %s.provided" % g),
                 ("alt_used_unconf", "@io_s1_fire_1 && %s.provided && %s.s1_altUsed_0" % (g, g)),
                 ("use_alt_ctr_update", "%s.updateValids_0 && %s.updateMeta_r_providers_0_valid && "
                                        "%s.updateProviderWeak && %s.updateAltDiffers" % (g, g, g, g)),
                 ("allocate", "%s.needToAllocate && (|%s.updateMeta_allocates_0_r)" % (g, g)),
                 ("tick_reset_u", "%s.updateResetU_0_probe || %s.updateResetU_1_probe" % (g, g)),
                 ("sc_override", "@io_s2_fire_3 && %s.s2_provideds_0 && %s._GEN_81" % (g, g)),
                 ("sc_update", "%s.scUpdateMask_0_3 || %s.scUpdateMask_1_3" % (g, g)),
                 ("bt_update", "%s._baseupdate_0_T_probe || %s._baseupdate_1_T_probe" % (g, g))],
            cov_min=10,
            # 结构常量（不是跑出来再填）：last_stage_meta 只有低 144 位是 TageMeta；pred_cycle（meta[65:2]）
            # 是自由计数的 64 位计数器、复位清零，UT 平均每 4 万拍复位一次，bit16 起不保证翻；perf 每路只有低 2 位有效；
            # provider 表号 2 位、allocates 4 位全是变量，不豁免。
            exempt=(["io_out_last_stage_meta[%d]" % b for b in list(range(2 + 16, 66)) + list(range(144, 516))]
                    + ["io_perf_%d_value[%d]" % (p, b) for p in range(3) for b in range(2, 6)]))
txt = render([pair], header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
