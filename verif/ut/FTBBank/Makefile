MODULE = FTBBank

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 物理 SRAM 宏模型 + 时钟门控（SplittedSRAMTemplate_2 内层 SRAMTemplate_36 需要）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p512x40m10s1h0l1b_bp_ftb.sv \
            $(GOLDEN_RTL)/array_1.sv $(GOLDEN_RTL)/array_1_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核：ftb 类型包 + xs_FTBBank 核
RTL_SRCS     = $(RTL_DIR)/frontend/ftb_pkg.sv $(RTL_DIR)/frontend/FTBBank.sv
# FM 用包装层（golden 同名 FTBBank，内部例化 xs_FTBBank + golden SRAM）
WRAPPER_SRCS = $(RTL_DIR)/frontend/FTBBank_wrapper.sv
# UT golden 侧依赖：golden FTBBank + 其内 MbistPipe/SRAM 链
GOLDEN_SRCS  = $(GOLDEN_RTL)/FTBBank.sv $(GOLDEN_RTL)/MbistPipeFtb.sv \
               $(GOLDEN_RTL)/SplittedSRAMTemplate_2.sv $(GOLDEN_RTL)/SRAMTemplate_36.sv \
               $(MACRO_SIM)
# UT 双例化：FTBBank_xs（可读核+SRAM）vs golden FTBBank
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FTBBank
# FM 参考侧只给 golden FTBBank 本体；内层 SplittedSRAMTemplate_2 与 MbistPipeFtb 两侧
# 均不提供源码 → fm_eq.tcl 的 hdlin_unresolved_modules=black_box 把它们当黑盒。
# 这样 SRAM 巨大的存储阵列与 MBIST 寄存器不进比对，只比 FTBBank 的 tag/命中/替换逻辑。
FM_REF_DEPS_FTBBank =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS
