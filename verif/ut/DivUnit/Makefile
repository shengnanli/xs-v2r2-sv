MODULE = DivUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内例化 golden 同名 SRT16DividerDataModule 黑盒）
RTL_SRCS = $(RTL_DIR)/backend/divunit_pkg.sv \
           $(RTL_DIR)/backend/DivUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 迭代除法器黑盒 SRT16DividerDataModule 及其叶子单元
# CSA3_2_*（进位保留加法器）/ RightShifter。UT 双例化两侧共用同一份除法器实现，
# 比对只检验 wrapper 的译码/符号扩展/握手/冲刷(kill_w/kill_r)/输出控制透传。
GOLDEN_SRCS = $(GOLDEN_RTL)/DivUnit.sv \
              $(GOLDEN_RTL)/SRT16DividerDataModule.sv \
              $(GOLDEN_RTL)/CSA3_2_3956.sv $(GOLDEN_RTL)/CSA3_2_3960.sv \
              $(GOLDEN_RTL)/CSA3_2_3962.sv $(GOLDEN_RTL)/RightShifter.sv

# FM：golden 顶层 DivUnit（含除法器黑盒）vs 手写同名 wrapper（→ 可读核 + 黑盒）。
# 除法器及叶子放 WRAPPER_SRCS 让 impl 侧也读入，使两侧黑盒按名配对。
WRAPPER_SRCS = $(RTL_DIR)/backend/DivUnit_wrapper.sv \
               $(GOLDEN_RTL)/SRT16DividerDataModule.sv \
               $(GOLDEN_RTL)/CSA3_2_3956.sv $(GOLDEN_RTL)/CSA3_2_3960.sv \
               $(GOLDEN_RTL)/CSA3_2_3962.sv $(GOLDEN_RTL)/RightShifter.sv
FM_VARIANTS = DivUnit
FM_REF_DEPS_DivUnit = SRT16DividerDataModule.sv CSA3_2_3956.sv CSA3_2_3960.sv CSA3_2_3962.sv RightShifter.sv

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
