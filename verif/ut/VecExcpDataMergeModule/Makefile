MODULE = VecExcpDataMergeModule

# 向量访存异常的 vd 数据拼接器。三个 child（GetE8OffsetInVreg / NfMappedElemIdx / DelayN_13）
# 在 docs/coverage_three_axis.tsv 第 3 列均为 PROVEN_DIRECT ⇒ 两侧白盒：ref 用 golden 同名件，
# impl 用本仓重写件。无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_13.sv \
           $(RTL_DIR)/backend/GetE8OffsetInVreg.sv \
           $(RTL_DIR)/backend/NfMappedElemIdx.sv \
           $(RTL_DIR)/backend/VecExcpDataMergeModule.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN_13.sv \
              $(GOLDEN_RTL)/GetE8OffsetInVreg.sv \
              $(GOLDEN_RTL)/NfMappedElemIdx.sv \
              $(GOLDEN_RTL)/VecExcpDataMergeModule.sv
FM_VARIANTS = VecExcpDataMergeModule
FM_REF_DEPS_VecExcpDataMergeModule = DelayN_13.sv GetE8OffsetInVreg.sv NfMappedElemIdx.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
# 不复位寄存器（regMaps / mergedVd / sWaitRab_*）由 tb 开头的固定暖机序列全部写一遍后才开始比。
INITREG ?= 0
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
