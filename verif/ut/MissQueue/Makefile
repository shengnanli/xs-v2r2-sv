# MissQueue —— DCache miss 队列（16 个 MSHR + CMOUnit + 入队流水寄存器 + A/E 通道仲裁 + 回填仲裁）
#
# 单文件规范：missqueue_pkg + xs_MissQueue_core + golden 同名 wrapper 都在 rtl/memblock/MissQueue.sv
# （wrapper 的端口表与全部实例连线由 scripts/gen_missq.py 生成）。共享辅助件 rtl/common/xs_TLArbiterLowest.sv。
# 子模块三种（16×MissEntry / CMOUnit / Arbiter16_MainPipeReq）都是本 lane 已签核的可读重写件，
# 放 RTL_GOLDEN_DEPS：不 derive、不改名，golden MissQueue 与派生出的 MissQueue_xs 例化同一份定义
# （UT 两侧对称，只比 MissQueue 本体的胶水）；FM 侧 ref 走 golden 的这三个文件（FM_REF_DEPS），
# impl 走可读件，两侧都完整 elaborate、无黑盒。
MODULE = MissQueue

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_TLArbiterLowest.sv \
           $(RTL_DIR)/memblock/MissQueue.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/MissQueue.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/memblock/Arbiter16_MainPipeReq.sv \
  $(RTL_DIR)/memblock/CMOUnit.sv \
  $(RTL_DIR)/memblock/MissEntry.sv

FM_VARIANTS = MissQueue
FM_REF_DEPS_MissQueue = MissEntry.sv CMOUnit.sv Arbiter16_MainPipeReq.sv

# 逐个比较，不合并重复寄存器（fm_predict 模型严格适用）
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/MissQueue.tcl★ —— 子模块与顶层的对称死寄存器位加强为实比；
# 名字不同的由 fm_pins_pre.tcl（scripts/gen_missq.py 生成）逐项配对。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# initreg：编译期打开机制，运行期 INITREG 选 +vcs+initreg+0 / random / <seed>017。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen.py --check
