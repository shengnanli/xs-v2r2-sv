# L1Prefetcher —— MemBlock 的 L1 硬件预取器顶层（本层只有接线 + 二选一 + 出口门控）。
# 5 个子模块（TrainFilter / TrainFilter_1 / StrideMetaArray / StreamBitVectorArray /
# MutiLevelPrefetchFilter，及后者的 4 个 RRArbiterInit_*）全部已独立签核，两侧白盒：
# ref 读 golden，impl 读本仓重写件。无黑盒。
# 子模块单独签核时用的钉点由 scripts/gen_l1prefetcher_pins.py 机械搬到父级层次下
# （fm_pins_pre.tcl ← StreamBitVectorArray，fm_pins.tcl ← MutiLevelPrefetchFilter）。
MODULE = L1Prefetcher

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TrainFilter_core.sv \
           $(RTL_DIR)/memblock/TrainFilter.sv \
           $(RTL_DIR)/memblock/TrainFilter_1.sv \
           $(RTL_DIR)/memblock/StrideMetaArray.sv \
           $(RTL_DIR)/common/xs_PlruReplacer.sv \
           $(RTL_DIR)/memblock/StreamBitVectorArray.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_6.sv \
           $(RTL_DIR)/common/RRArbiterInit_7.sv \
           $(RTL_DIR)/common/RRArbiterInit_8.sv \
           $(RTL_DIR)/common/RRArbiterInit_9.sv \
           $(RTL_DIR)/memblock/MutiLevelPrefetchFilter.sv \
           $(RTL_DIR)/memblock/L1Prefetcher.sv
TB_SRCS = tb.sv

L1PF_CHILDREN = TrainFilter.sv TrainFilter_1.sv StrideMetaArray.sv StreamBitVectorArray.sv \
                MutiLevelPrefetchFilter.sv RRArbiterInit_6.sv RRArbiterInit_7.sv \
                RRArbiterInit_8.sv RRArbiterInit_9.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L1Prefetcher.sv $(addprefix $(GOLDEN_RTL)/,$(L1PF_CHILDREN))

FM_VARIANTS = L1Prefetcher
FM_REF_DEPS_L1Prefetcher = $(L1PF_CHILDREN)
FM_MERGE_DUP = false
# 子模块死位 + 父级新增死位共 1011 位，按 vmucp standing rule 加强，见 verif/fm_target_config/L1Prefetcher.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_l1prefetcher_pins.py --check
