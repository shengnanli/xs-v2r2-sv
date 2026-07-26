MODULE = McycleModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitives (newcsr_counter.sv): xs_ucounter(cycle/instret) /
# xs_mcounter(Mcycle/Minstret) / xs_rwlatch(Htimedelta/Stimecmp/VStimecmp) /
# xs_time(timeModule)。golden 多为 clock-only 无 reset; timecmp reset=all-ones。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_counter.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/cycleModule_wrapper.sv \
               $(RTL_DIR)/backend/McycleModule_wrapper.sv \
               $(RTL_DIR)/backend/MinstretModule_wrapper.sv \
               $(RTL_DIR)/backend/StimecmpModule_wrapper.sv \
               $(RTL_DIR)/backend/HtimedeltaModule_wrapper.sv \
               $(RTL_DIR)/backend/timeModule_wrapper.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/cycleModule.sv $(GOLDEN_RTL)/McycleModule.sv \
               $(GOLDEN_RTL)/MinstretModule.sv $(GOLDEN_RTL)/StimecmpModule.sv \
               $(GOLDEN_RTL)/HtimedeltaModule.sv $(GOLDEN_RTL)/timeModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 6 形态各代表; 全读, 无死寄存器 -> 干净 SUCCEEDED。无黑盒/dont_verify/allow。
# 同 primitive 证 instretModule(ucounter)/VStimecmpModule(rwlatch all-ones)。
FM_VARIANTS = cycleModule McycleModule MinstretModule StimecmpModule HtimedeltaModule timeModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
