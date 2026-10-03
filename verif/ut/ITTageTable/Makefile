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
                  $(GOLDEN_RTL)/data_mem_0_4x2.sv \
                  $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

# golden 双例化：golden 顶 + 只属于 golden 侧的 MBIST 流水（其余子模块闭包见
# RTL_GOLDEN_DEPS，两侧共用同一份定义）。
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTageTable.sv \
              $(GOLDEN_RTL)/array_6_ext.v \
              $(GOLDEN_RTL)/MbistPipeIttage.sv

# vmucp（verification_verify_matched_unread_compare_points）——**加强**证明，不是 waiver：
# 要求 FM 真去比对 matched-unread 的点，而不是当 Not-Compared 放过。
# 依据（2026-09-14 本 worker 实测，非继承）：strict 首跑 native SUCCEEDED /
# passing 见 evidence / failing 0 / unmatched 0，只剩 unread 卡住；unread 点在
# fm_pins.tcl 钉完后**全部**是 matched_nc，ref 侧唯一点数 == impl 侧唯一点数、
# 非 matched_nc 项为 0，即严格双射。内容是 MBIST 地址死位（addrReg[7:0] 整条写
# 地址 + addrRdReg[7]，SRAMTemplate 侧无读者/RW0_addr 只有 7 位）与厂商 SRAM 宏
# array_6_ext 的 reg_RW0_ren（非 RANDOMIZE_GARBAGE_ASSIGN 视图下无读者），两侧同
# 为死位。逐行依据见本目录 fm_pins.tcl。白名单见 verif/fm_target_config/<top>.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = ITTageTable
# 关 merge_duplicated_registers：逐个比，fm_predict 的 passing 模型严格适用（2026-10-03 agent/bpu-tables）。
FM_MERGE_DUP = false
FM_REF_DEPS_ITTageTable = ClockGate.sv FoldedSRAMTemplate_22.sv IndexableCAMTemplate_41.sv MbistClockGateCell.sv MbistPipeIttage.sv SRAMTemplate_76.sv SplittedSRAMTemplate_25.sv WrBypass_41.sv array_6.sv data_mem_0_4x2.sv sram_array_1p128x76m1s1h0l1b_bp_ittage.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
# ★initreg 三档（2026-10-03 agent/bpu-tables 补）★：INITREG=0 / random / <seed>017；后两档用 initreg 配置文件，
# 其余状态随机、厂商 SRAM 行为模型（array_6_ext）存储钉 0（表项 SRAM 无复位，两实例读"从没写过"的条目随机值不同 ——
# tb 先写后读契约，同 verif/ut/ITTage）。厂商叶子 .v 只给 VCS，FM 两侧黑盒（verif/vendor_boundary.tsv）。
INITREG ?= 0
SRAM_LEAVES = array_6_ext
ifeq ($(INITREG),0)
SIM_ARGS += +vcs+initreg+0
else
SIM_ARGS += +vcs+initreg+config+$(UT_GEN_DIR)/initreg_$(INITREG).cfg
endif
$(UT_GEN_DIR)/initreg_%.cfg: Makefile
	@mkdir -p $(UT_GEN_DIR)
	@{ if [ "$*" = random ]; then echo "defaultvalue random"; else echo "defaultvalue random $*"; fi; \
	   for m in $(SRAM_LEAVES); do echo "module $$m 0"; done; } > $@
run: $(if $(filter-out 0,$(INITREG)),$(UT_GEN_DIR)/initreg_$(INITREG).cfg)
