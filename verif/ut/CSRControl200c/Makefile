MODULE = CSRControl200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Iprio0Module.sv \
           $(RTL_DIR)/backend/Iprio0Module_1.sv \
           $(RTL_DIR)/backend/Iprio2Module.sv \
           $(RTL_DIR)/backend/Iprio2Module_1.sv \
           $(RTL_DIR)/backend/Iprio4Module_1.sv \
           $(RTL_DIR)/backend/Iprio6Module_1.sv \
           $(RTL_DIR)/backend/Iprio8Module_1.sv \
           $(RTL_DIR)/backend/Iprio10Module_1.sv \
           $(RTL_DIR)/backend/Iprio12Module_1.sv \
           $(RTL_DIR)/backend/Iprio14Module_1.sv \
           $(RTL_DIR)/backend/MhpmeventModule.sv \
           $(RTL_DIR)/backend/MNretEventModule.sv \
           $(RTL_DIR)/backend/SstcInterruptGen.sv
TB_SRCS = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,Iprio0Module.sv Iprio0Module_1.sv Iprio2Module.sv Iprio2Module_1.sv Iprio4Module_1.sv Iprio6Module_1.sv Iprio8Module_1.sv Iprio10Module_1.sv Iprio12Module_1.sv Iprio14Module_1.sv MhpmeventModule.sv MNretEventModule.sv SstcInterruptGen.sv)
FM_VARIANTS = Iprio0Module Iprio0Module_1 Iprio2Module Iprio2Module_1 Iprio4Module_1 Iprio6Module_1 Iprio8Module_1 Iprio10Module_1 Iprio12Module_1 Iprio14Module_1 MhpmeventModule MNretEventModule SstcInterruptGen
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
