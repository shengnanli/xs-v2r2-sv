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
# DelayNWithValid/_1 + DelayN_1（纯逻辑延迟线, 非vendor）两侧 elaborate；
# FTBBank 是独立绿目标(depends_on)→黑盒。
FM_LOGIC_ELAB = $(GOLDEN_RTL)/DelayNWithValid.sv $(GOLDEN_RTL)/DelayNWithValid_1.sv \
                $(GOLDEN_RTL)/DelayN_1.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/FTB_wrapper.sv $(FM_LOGIC_ELAB)
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
# DelayN* 纯逻辑两侧 elaborate；FTBBank 独立绿目标 depends_on → 黑盒。
FM_REF_DEPS_FTB = DelayNWithValid.sv DelayNWithValid_1.sv DelayN_1.sv

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉（同时关随机初始化 initial）
VCS += +define+SYNTHESIS
