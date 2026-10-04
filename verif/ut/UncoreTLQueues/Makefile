MODULE = UncoreTLQueues

# 21 个 TileLink 通道 Queue2_TLBundle* 单态化（rocket-chip TLBuffer 的 A/B/C/D/E 各通道 2 项缓冲）：
# 已签共享核 rtl/common/xs_ChiselQueue_core.sv + 薄文件（scripts/gen_uncore_queues.py 生成，fail-closed 对照 golden）。
# 存储是 golden 的 ram_2xW / ram_sink_2xW 行为级叶子：全部深度 2 = 2^1（2 的幂），按 codex 0151 D60 两侧同源
# inline elaborate（同时进 RTL_GOLDEN_DEPS 与 FM_REF_DEPS_<T>），无黑盒、无需扩 vendor_boundary.tsv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_6.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_7.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_8.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_10.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_12.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_14.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_15.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_19.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_31.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleB.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleB_1.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleC.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleC_1.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_7.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_8.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_11.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_13.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_15.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_20.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleE.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleE_1.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x76.sv \
                  $(GOLDEN_RTL)/ram_2x79.sv \
                  $(GOLDEN_RTL)/ram_2x80.sv \
                  $(GOLDEN_RTL)/ram_2x116.sv \
                  $(GOLDEN_RTL)/ram_2x117.sv \
                  $(GOLDEN_RTL)/ram_2x119.sv \
                  $(GOLDEN_RTL)/ram_2x133.sv \
                  $(GOLDEN_RTL)/ram_2x136.sv \
                  $(GOLDEN_RTL)/ram_2x137.sv \
                  $(GOLDEN_RTL)/ram_2x281.sv \
                  $(GOLDEN_RTL)/ram_2x283.sv \
                  $(GOLDEN_RTL)/ram_2x284.sv \
                  $(GOLDEN_RTL)/ram_2x309.sv \
                  $(GOLDEN_RTL)/ram_2x321.sv \
                  $(GOLDEN_RTL)/ram_2x352.sv \
                  $(GOLDEN_RTL)/ram_2x356.sv \
                  $(GOLDEN_RTL)/ram_2x359.sv \
                  $(GOLDEN_RTL)/ram_2x373.sv \
                  $(GOLDEN_RTL)/ram_2x406.sv \
                  $(GOLDEN_RTL)/ram_sink_2x8.sv \
                  $(GOLDEN_RTL)/ram_sink_2x10.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue2_TLBundleA_6.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_7.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_8.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_14.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_15.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_31.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_8.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_15.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv
# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = Queue2_TLBundleA_6 Queue2_TLBundleA_7 Queue2_TLBundleA_8 Queue2_TLBundleA_10 Queue2_TLBundleA_12 Queue2_TLBundleA_14 Queue2_TLBundleA_15 Queue2_TLBundleA_19 Queue2_TLBundleA_31 Queue2_TLBundleB Queue2_TLBundleB_1 Queue2_TLBundleC Queue2_TLBundleC_1 Queue2_TLBundleD_7 Queue2_TLBundleD_8 Queue2_TLBundleD_11 Queue2_TLBundleD_13 Queue2_TLBundleD_15 Queue2_TLBundleD_20 Queue2_TLBundleE Queue2_TLBundleE_1
FM_REF_DEPS_Queue2_TLBundleA_6 = ram_2x356.sv
FM_REF_DEPS_Queue2_TLBundleA_7 = ram_2x406.sv
FM_REF_DEPS_Queue2_TLBundleA_8 = ram_2x359.sv
FM_REF_DEPS_Queue2_TLBundleA_10 = ram_2x117.sv
FM_REF_DEPS_Queue2_TLBundleA_12 = ram_2x133.sv
FM_REF_DEPS_Queue2_TLBundleA_14 = ram_2x136.sv
FM_REF_DEPS_Queue2_TLBundleA_15 = ram_2x116.sv
FM_REF_DEPS_Queue2_TLBundleA_19 = ram_2x119.sv
FM_REF_DEPS_Queue2_TLBundleA_31 = ram_2x137.sv
FM_REF_DEPS_Queue2_TLBundleB = ram_2x309.sv
FM_REF_DEPS_Queue2_TLBundleB_1 = ram_2x352.sv
FM_REF_DEPS_Queue2_TLBundleC = ram_2x373.sv
FM_REF_DEPS_Queue2_TLBundleC_1 = ram_2x321.sv
FM_REF_DEPS_Queue2_TLBundleD_7 = ram_2x281.sv
FM_REF_DEPS_Queue2_TLBundleD_8 = ram_2x284.sv
FM_REF_DEPS_Queue2_TLBundleD_11 = ram_2x80.sv
FM_REF_DEPS_Queue2_TLBundleD_13 = ram_2x76.sv
FM_REF_DEPS_Queue2_TLBundleD_15 = ram_2x79.sv
FM_REF_DEPS_Queue2_TLBundleD_20 = ram_2x283.sv
FM_REF_DEPS_Queue2_TLBundleE = ram_sink_2x10.sv
FM_REF_DEPS_Queue2_TLBundleE_1 = ram_sink_2x8.sv
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用；常量段 ram 位
# 在 merge=true 下两侧合并不对称（TLBuffer_13 Makefile 实测同一批 ram 位），关掉是加强不是放宽。
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
