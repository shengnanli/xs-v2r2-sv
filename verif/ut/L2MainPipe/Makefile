MODULE = MainPipe_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/MainPipe_1.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/MainPipe_1_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe_1.sv \
              $(GOLDEN_RTL)/CustomL1Hint.sv \
              $(GOLDEN_RTL)/Queue16_HintQueueEntry.sv \
              $(GOLDEN_RTL)/Queue4_HintQueueEntry.sv \
              $(GOLDEN_RTL)/ram_16x11.sv \
              $(GOLDEN_RTL)/ram_4x11.sv \
              $(GOLDEN_RTL)/Arbiter3_TaskWithData.sv \
              $(GOLDEN_RTL)/Arbiter3_CHIREQ.sv \
              $(GOLDEN_RTL)/Arbiter3_TaskBundle.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref = golden MainPipe_1; CustomL1Hint 两侧黑盒(不进 deps/impl);
#     Arbiter3_* 内联进核 → 必须进 ref deps 让 FM 展平 golden 端的仲裁器。
FM_VARIANTS = MainPipe_1
FM_REF_DEPS_MainPipe_1 = Arbiter3_TaskWithData.sv Arbiter3_CHIREQ.sv Arbiter3_TaskBundle.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
