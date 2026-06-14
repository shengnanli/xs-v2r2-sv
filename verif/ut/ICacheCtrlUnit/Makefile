MODULE = ICacheCtrlUnit
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 参数化核心 + 队列（同一文件内两模块）
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv
# golden 同名包装层（仅 FM 用，不进 UT 编译）：顶层 + Queue 包装
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit_wrapper.sv \
               $(RTL_DIR)/frontend/Queue1_RegMapperInput_3_wrapper.sv
# UT 双例化比对的 golden RTL（顶层 + 其队列子模块）
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheCtrlUnit.sv $(GOLDEN_RTL)/Queue1_RegMapperInput_3.sv
TB_SRCS = variants_xs.sv tb.sv

# FM：队列单独一比，顶层一比（顶层 ref 含队列依赖）
FM_VARIANTS = Queue1_RegMapperInput_3 ICacheCtrlUnit
FM_REF_DEPS_ICacheCtrlUnit = Queue1_RegMapperInput_3.sv

# golden 含 `ifndef SYNTHESIS 的随机初始化；UT 随机激励下定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

include ../../../scripts/ut_common.mk
