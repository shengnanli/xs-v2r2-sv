MODULE = MSHR

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mshr_pkg.sv \
           $(RTL_DIR)/uncore/MSHR.sv

# MSHR.sv `include 以下 .svh(不直接编译, 仅作为 simv 重编依赖)
RTL_INC = $(RTL_DIR)/uncore/mshr_core.svh $(RTL_DIR)/uncore/mshr_mainpipe.svh \
          $(RTL_DIR)/uncore/mshr_seq.svh $(RTL_DIR)/uncore/mshr_outputs.svh
simv: $(RTL_INC)

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHR.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHR_wrapper.sv
FM_VARIANTS = MSHR

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
