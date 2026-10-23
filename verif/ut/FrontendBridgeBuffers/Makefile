MODULE = FrontendBridgeBuffers

# MemBlock.FrontendBridge 的三个 TileLink 两级缓冲（ICacheBuffer / InstrUncacheBuffer / ICacheCtrlBuffer）。
# 每个 = A、D 两通道各两个首尾相接的 Queue2_TLBundle*；子模块两侧白盒：
#   ref 侧 golden Queue2_* + ram_2xN；impl 侧已签核的重写件（rtl/uncore/Queue2_*.sv + 共享核
#   rtl/common/xs_ChiselQueue_core.sv，evidence/1fda02fae0f1）；ram_2xN 是 golden 行为级叶子，
#   两侧同源 inline（与 verif/ut/UncoreTLQueues 同一处置，codex 0151 D60）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_8.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_7.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_12.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_13.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_10.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_11.sv \
           $(RTL_DIR)/memblock/ICacheBuffer.sv \
           $(RTL_DIR)/memblock/InstrUncacheBuffer.sv \
           $(RTL_DIR)/memblock/ICacheCtrlBuffer.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x359.sv \
                  $(GOLDEN_RTL)/ram_2x281.sv \
                  $(GOLDEN_RTL)/ram_2x133.sv \
                  $(GOLDEN_RTL)/ram_2x76.sv \
                  $(GOLDEN_RTL)/ram_2x117.sv \
                  $(GOLDEN_RTL)/ram_2x80.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue2_TLBundleA_8.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_7.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_12.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_10.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_11.sv \
              $(GOLDEN_RTL)/ICacheBuffer.sv \
              $(GOLDEN_RTL)/InstrUncacheBuffer.sv \
              $(GOLDEN_RTL)/ICacheCtrlBuffer.sv
# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = ICacheBuffer InstrUncacheBuffer ICacheCtrlBuffer
FM_REF_DEPS_ICacheBuffer = Queue2_TLBundleA_8.sv Queue2_TLBundleD_7.sv ram_2x359.sv ram_2x281.sv
FM_REF_DEPS_InstrUncacheBuffer = Queue2_TLBundleA_12.sv Queue2_TLBundleD_13.sv ram_2x133.sv ram_2x76.sv
FM_REF_DEPS_ICacheCtrlBuffer = Queue2_TLBundleA_10.sv Queue2_TLBundleD_11.sv ram_2x117.sv ram_2x80.sv
# ★FM impl 侧逐 variant 只读自己那一份 ram（2026-10-20，agent/rr-mcnarrow；cb251a56a 同法）★：UT 两侧仍共用上面整张
# RTL_GOLDEN_DEPS；FM 的 impl 闭包若带上全家族的 ram，证书复核按 codex 0222 判 green_child_impl_golden_mc_not_shared。
# 每个 variant 的 impl 侧 golden 依赖 = 它 FM_REF_DEPS 里的 ram（同一份，两侧共读）。
fm-ICacheBuffer: RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x359.sv $(GOLDEN_RTL)/ram_2x281.sv
fm-InstrUncacheBuffer: RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x133.sv $(GOLDEN_RTL)/ram_2x76.sv
fm-ICacheCtrlBuffer: RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x117.sv $(GOLDEN_RTL)/ram_2x80.sv
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用（与 UncoreTLQueues 同）。
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

# 对称死位（各级 Queue2 里写入却无人读的 ram 字段位，两侧同路径 matched_nc）开 vmucp 让 FM 真去比；
# 依据与六条判据见 verif/fm_target_config/<T>.tcl。
fm-ICacheBuffer: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
fm-InstrUncacheBuffer: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
fm-ICacheCtrlBuffer: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
