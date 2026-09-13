# 自动生成：scripts/gen_zj_ut.py 的配套 Makefile（零判断批 G0->G1 迁移）
MODULE = ITTageTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ITTageTable.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 结构性修复（agent/diag-structural，2026-09-13）
#
# 症状：native FM FAILED，passing=192 / failing=20(报告上限) / unmatched=9948。
# 根因：impl 侧只给了 rtl/frontend/ITTageTable.sv，wrapper 例化的
#       FoldedSRAMTemplate_22 / WrBypass_41 在 impl 侧无定义 → 被
#       hdlin_unresolved_modules=black_box 当黑盒；ref 侧却把整条 SRAM 链
#       (FoldedSRAMTemplate_22 → SplittedSRAMTemplate_25 → SRAMTemplate_76 →
#        sram_array_1p128x76m1s1h0l1b_bp_ittage → array_6 → array_6_ext
#        的 reg [75:0] ram[127:0] = 9728 位) 完整 elaborate。**两侧建模不对称**。
# 修法：两侧同源 elaborate（RTL_GOLDEN_DEPS）。MBIST 流水（MbistPipeIttage）本
#       文件已重写成 xs_MbistPipeIttage_core，故**不**放进 impl 侧依赖——它由
#       impl 自己的可读核承担，是本目标真正在证的东西之一。
# ---------------------------------------------------------------------------
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ClockGate.sv \
                  $(GOLDEN_RTL)/FoldedSRAMTemplate_22.sv \
                  $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv \
                  $(GOLDEN_RTL)/MbistClockGateCell.sv \
                  $(GOLDEN_RTL)/SRAMTemplate_76.sv \
                  $(GOLDEN_RTL)/SplittedSRAMTemplate_25.sv \
                  $(GOLDEN_RTL)/WrBypass_41.sv \
                  $(GOLDEN_RTL)/array_6.sv \
                  $(GOLDEN_RTL)/array_6_ext.v \
                  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

# golden 双例化：golden 顶 + 只属于 golden 侧的 MBIST 流水（其余子模块闭包见
# RTL_GOLDEN_DEPS，两侧共用同一份定义）。
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTageTable.sv \
              $(GOLDEN_RTL)/MbistPipeIttage.sv

FM_VARIANTS = ITTageTable
FM_REF_DEPS_ITTageTable = ClockGate.sv FoldedSRAMTemplate_22.sv IndexableCAMTemplate_41.sv MbistClockGateCell.sv MbistPipeIttage.sv SRAMTemplate_76.sv SplittedSRAMTemplate_25.sv WrBypass_41.sv array_6.sv array_6_ext.v data_mem_0_4x2.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
