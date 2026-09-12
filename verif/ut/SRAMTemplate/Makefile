# 自动生成：scripts/gen_sram_wrappers.py（G1 基线驱动）—— 勿手改
MODULE = SRAMTemplate

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
           $(RTL_DIR)/common/SRAMTemplate.sv \
           $(RTL_DIR)/common/SRAMTemplate_100.sv \
           $(RTL_DIR)/common/SRAMTemplate_116.sv \
           $(RTL_DIR)/common/SRAMTemplate_124.sv \
           $(RTL_DIR)/common/SRAMTemplate_129.sv \
           $(RTL_DIR)/common/SRAMTemplate_143.sv \
           $(RTL_DIR)/common/SRAMTemplate_148.sv \
           $(RTL_DIR)/common/SRAMTemplate_150.sv \
           $(RTL_DIR)/common/SRAMTemplate_153.sv \
           $(RTL_DIR)/common/SRAMTemplate_154.sv \
           $(RTL_DIR)/common/SRAMTemplate_159.sv \
           $(RTL_DIR)/common/SRAMTemplate_16.sv \
           $(RTL_DIR)/common/SRAMTemplate_162.sv \
           $(RTL_DIR)/common/SRAMTemplate_164.sv \
           $(RTL_DIR)/common/SRAMTemplate_165.sv \
           $(RTL_DIR)/common/SRAMTemplate_181.sv \
           $(RTL_DIR)/common/SRAMTemplate_186.sv \
           $(RTL_DIR)/common/SRAMTemplate_187.sv \
           $(RTL_DIR)/common/SRAMTemplate_2.sv \
           $(RTL_DIR)/common/SRAMTemplate_32.sv \
           $(RTL_DIR)/common/SRAMTemplate_36.sv \
           $(RTL_DIR)/common/SRAMTemplate_4.sv \
           $(RTL_DIR)/common/SRAMTemplate_44.sv \
           $(RTL_DIR)/common/SRAMTemplate_45.sv \
           $(RTL_DIR)/common/SRAMTemplate_64.sv \
           $(RTL_DIR)/common/SRAMTemplate_68.sv \
           $(RTL_DIR)/common/SRAMTemplate_76.sv \
           $(RTL_DIR)/common/SRAMTemplate_78.sv \
           $(RTL_DIR)/common/SRAMTemplate_8.sv \
           $(RTL_DIR)/common/SRAMTemplate_84.sv \
           $(RTL_DIR)/common/SRAMTemplate_86.sv \
           $(RTL_DIR)/common/SRAMTemplate_88.sv \
           $(RTL_DIR)/common/SRAMTemplate_92.sv
TB_SRCS = tb.sv

# 厂商 SRAM 宏链：golden 同源文件, 两侧同读(FM impl 侧经 RTL_GOLDEN_DEPS)。
# 宏内 array_*_ext 是 vendor 叶子(.v, FM 不读)⇒ 对称未解析黑盒, 见 FM_MODE 说明。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/array.sv \
                  $(GOLDEN_RTL)/array_0.sv \
                  $(GOLDEN_RTL)/array_1.sv \
                  $(GOLDEN_RTL)/array_11.sv \
                  $(GOLDEN_RTL)/array_14.sv \
                  $(GOLDEN_RTL)/array_16.sv \
                  $(GOLDEN_RTL)/array_17.sv \
                  $(GOLDEN_RTL)/array_2.sv \
                  $(GOLDEN_RTL)/array_3.sv \
                  $(GOLDEN_RTL)/array_4.sv \
                  $(GOLDEN_RTL)/array_5.sv \
                  $(GOLDEN_RTL)/array_6.sv \
                  $(GOLDEN_RTL)/array_7.sv \
                  $(GOLDEN_RTL)/array_8.sv \
                  $(GOLDEN_RTL)/array_9.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
                  $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
                  $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
                  $(GOLDEN_RTL)/sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
                  $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate.sv \
              $(GOLDEN_RTL)/SRAMTemplate_100.sv \
              $(GOLDEN_RTL)/SRAMTemplate_116.sv \
              $(GOLDEN_RTL)/SRAMTemplate_124.sv \
              $(GOLDEN_RTL)/SRAMTemplate_129.sv \
              $(GOLDEN_RTL)/SRAMTemplate_143.sv \
              $(GOLDEN_RTL)/SRAMTemplate_148.sv \
              $(GOLDEN_RTL)/SRAMTemplate_150.sv \
              $(GOLDEN_RTL)/SRAMTemplate_153.sv \
              $(GOLDEN_RTL)/SRAMTemplate_154.sv \
              $(GOLDEN_RTL)/SRAMTemplate_159.sv \
              $(GOLDEN_RTL)/SRAMTemplate_16.sv \
              $(GOLDEN_RTL)/SRAMTemplate_162.sv \
              $(GOLDEN_RTL)/SRAMTemplate_164.sv \
              $(GOLDEN_RTL)/SRAMTemplate_165.sv \
              $(GOLDEN_RTL)/SRAMTemplate_181.sv \
              $(GOLDEN_RTL)/SRAMTemplate_186.sv \
              $(GOLDEN_RTL)/SRAMTemplate_187.sv \
              $(GOLDEN_RTL)/SRAMTemplate_2.sv \
              $(GOLDEN_RTL)/SRAMTemplate_32.sv \
              $(GOLDEN_RTL)/SRAMTemplate_36.sv \
              $(GOLDEN_RTL)/SRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv \
              $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv \
              $(GOLDEN_RTL)/SRAMTemplate_68.sv \
              $(GOLDEN_RTL)/SRAMTemplate_76.sv \
              $(GOLDEN_RTL)/SRAMTemplate_78.sv \
              $(GOLDEN_RTL)/SRAMTemplate_8.sv \
              $(GOLDEN_RTL)/SRAMTemplate_84.sv \
              $(GOLDEN_RTL)/SRAMTemplate_86.sv \
              $(GOLDEN_RTL)/SRAMTemplate_88.sv \
              $(GOLDEN_RTL)/SRAMTemplate_92.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/array.sv \
              $(GOLDEN_RTL)/array_0.sv \
              $(GOLDEN_RTL)/array_0_ext.v \
              $(GOLDEN_RTL)/array_1.sv \
              $(GOLDEN_RTL)/array_11.sv \
              $(GOLDEN_RTL)/array_11_ext.v \
              $(GOLDEN_RTL)/array_14.sv \
              $(GOLDEN_RTL)/array_14_ext.v \
              $(GOLDEN_RTL)/array_16.sv \
              $(GOLDEN_RTL)/array_16_ext.v \
              $(GOLDEN_RTL)/array_17.sv \
              $(GOLDEN_RTL)/array_17_ext.v \
              $(GOLDEN_RTL)/array_1_ext.v \
              $(GOLDEN_RTL)/array_2.sv \
              $(GOLDEN_RTL)/array_2_ext.v \
              $(GOLDEN_RTL)/array_3.sv \
              $(GOLDEN_RTL)/array_3_ext.v \
              $(GOLDEN_RTL)/array_4.sv \
              $(GOLDEN_RTL)/array_4_ext.v \
              $(GOLDEN_RTL)/array_5.sv \
              $(GOLDEN_RTL)/array_5_ext.v \
              $(GOLDEN_RTL)/array_6.sv \
              $(GOLDEN_RTL)/array_6_ext.v \
              $(GOLDEN_RTL)/array_7.sv \
              $(GOLDEN_RTL)/array_7_ext.v \
              $(GOLDEN_RTL)/array_8.sv \
              $(GOLDEN_RTL)/array_8_ext.v \
              $(GOLDEN_RTL)/array_9.sv \
              $(GOLDEN_RTL)/array_9_ext.v \
              $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/sram_array_1p128x24m6s1h0l1b_bp_sc.sv \
              $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
              $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
              $(GOLDEN_RTL)/sram_array_1p256x66m66s1h0l1b_icsh_dat.sv \
              $(GOLDEN_RTL)/sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv \
              $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv \
              $(GOLDEN_RTL)/sram_array_1p32x90m45s1h0l1b_bitmap.sv \
              $(GOLDEN_RTL)/sram_array_1p512x16m16s1h0l1b_l2_repl.sv \
              $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
              $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
              $(GOLDEN_RTL)/sram_array_1p512x76m19s1h0l1b_l2_tag.sv \
              $(GOLDEN_RTL)/sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \
              $(GOLDEN_RTL)/sram_array_1p64x114m57s1h0l1b_ptw_l0.sv

FM_REF_DEPS_SRAMTemplate = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_100 = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_116 = sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_8.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_124 = sram_array_1p32x90m45s1h0l1b_bitmap.sv array_9.sv
FM_REF_DEPS_SRAMTemplate_129 = sram_array_1p64x114m57s1h0l1b_ptw_l0.sv array_11.sv
FM_REF_DEPS_SRAMTemplate_143 = sram_array_1p64x114m57s1h0l1b_ptw_l0.sv array_11.sv
FM_REF_DEPS_SRAMTemplate_148 = sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv
FM_REF_DEPS_SRAMTemplate_150 = sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv
FM_REF_DEPS_SRAMTemplate_153 = sram_array_1p512x16m16s1h0l1b_l2_repl.sv array_16.sv
FM_REF_DEPS_SRAMTemplate_154 = sram_array_1p512x8m1s1h0l1b_l2_orgb.sv array_17.sv
FM_REF_DEPS_SRAMTemplate_159 = sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv
FM_REF_DEPS_SRAMTemplate_16 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_162 = sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv
FM_REF_DEPS_SRAMTemplate_164 = sram_array_1p512x16m16s1h0l1b_l2_repl.sv array_16.sv
FM_REF_DEPS_SRAMTemplate_165 = sram_array_1p512x8m1s1h0l1b_l2_orgb.sv array_17.sv
FM_REF_DEPS_SRAMTemplate_181 = sram_array_1p512x76m19s1h0l1b_l2_tag.sv array_14.sv
FM_REF_DEPS_SRAMTemplate_186 = sram_array_1p512x16m16s1h0l1b_l2_repl.sv array_16.sv
FM_REF_DEPS_SRAMTemplate_187 = sram_array_1p512x8m1s1h0l1b_l2_orgb.sv array_17.sv
FM_REF_DEPS_SRAMTemplate_2 = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_32 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_36 = sram_array_1p512x40m10s1h0l1b_bp_ftb.sv array_1.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_4 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_44 = sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv array_2.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_45 = sram_array_1p512x24m12s1h0l1b_bp_tage.sv array_3.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_64 = sram_array_1p256x8m2s1h0l1b_bp_tage_bt.sv array_4.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_68 = sram_array_1p128x24m6s1h0l1b_bp_sc.sv array_5.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_76 = sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_78 = sram_array_1p128x76m1s1h0l1b_bp_ittage.sv array_6.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_8 = sram_array_1p256x66m66s1h0l1b_icsh_dat.sv array_0.sv
FM_REF_DEPS_SRAMTemplate_84 = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_86 = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_88 = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv
FM_REF_DEPS_SRAMTemplate_92 = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv

# FM_MODE=assembly: 唯一抽象边界 = 厂商 SRAM 宏叶子 array_*_ext(.v 行为模型,
# 两侧同一文件, FM 不读 ⇒ 对称未解析黑盒)。老战役 reviewer 裁定: vendor 宏
# 无条件可黑盒。allowlist 为对称未匹配点配额(非对称一律 PARTIAL, 见 fm_verdict)。
FM_MODE = assembly
FM_ALLOWLIST ?= 8
FM_VARIANTS = SRAMTemplate SRAMTemplate_100 SRAMTemplate_116 SRAMTemplate_124 SRAMTemplate_129 SRAMTemplate_143 SRAMTemplate_148 SRAMTemplate_150 SRAMTemplate_153 SRAMTemplate_154 SRAMTemplate_159 SRAMTemplate_16 SRAMTemplate_162 SRAMTemplate_164 SRAMTemplate_165 SRAMTemplate_181 SRAMTemplate_186 SRAMTemplate_187 SRAMTemplate_2 SRAMTemplate_32 SRAMTemplate_36 SRAMTemplate_4 SRAMTemplate_44 SRAMTemplate_45 SRAMTemplate_64 SRAMTemplate_68 SRAMTemplate_76 SRAMTemplate_78 SRAMTemplate_8 SRAMTemplate_84 SRAMTemplate_86 SRAMTemplate_88 SRAMTemplate_92

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
