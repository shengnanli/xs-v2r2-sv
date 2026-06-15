MODULE = FTB

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 物理 SRAM 宏模型 + 时钟门控（FTBBank 内层 SplittedSRAMTemplate_2/SRAMTemplate_36 需要）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
            $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/array_1_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核：ftb 类型包 + xs_FTB_core 核
RTL_SRCS = $(RTL_DIR)/frontend/ftb_pkg.sv $(RTL_DIR)/frontend/FTB.sv
# FM 用包装层（golden 同名 FTB，内部例化 xs_FTB_core + golden 子模块）
WRAPPER_SRCS = $(RTL_DIR)/frontend/FTB_wrapper.sv
# UT 双例化：FTB_xs（可读核 + golden 子模块）vs golden FTB
# golden 侧依赖：golden FTB + 其子模块（FTBBank 链 / DelayN*）+ SRAM/Mbist
GOLDEN_SRCS = $(GOLDEN_RTL)/FTB.sv \
              $(GOLDEN_RTL)/FTBBank.sv $(GOLDEN_RTL)/MbistPipeFtb.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv $(GOLDEN_RTL)/SRAMTemplate_36.sv \
              $(GOLDEN_RTL)/DelayNWithValid.sv $(GOLDEN_RTL)/DelayNWithValid_1.sv \
              $(GOLDEN_RTL)/DelayN_1.sv \
              $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FTB
# FM 参考侧只给 golden FTB 本体；子模块（FTBBank / DelayNWithValid* / DelayN_1）两侧
# 均不提供源码 → fm_eq.tcl 的 hdlin_unresolved_modules=black_box 把它们当黑盒。
# 这样只比 FTB 顶层的流水/close/目标解码/update 控制逻辑，子模块作为等价黑盒。
FM_REF_DEPS_FTB =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉（同时关随机初始化 initial）
VCS += +define+SYNTHESIS
