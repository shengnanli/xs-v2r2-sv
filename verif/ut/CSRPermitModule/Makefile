MODULE = CSRPermitModule
# CSRPermitModule 本体（golden 286 行，6 个子模块，各 1 例）—— 两侧白盒，无黑盒：
#   XRetPermitModule / MLevelPermitModule / SLevelPermitModule / PrivilegePermitModule /
#   IndirectCSRPermitModule 已签核（docs/coverage_three_axis.tsv PROVEN_DIRECT）；
#   VirtualLevelPermitModule 本 lane 签核（verif/ut/NewcsrLeaves6）。
# ref = golden 6 个子模块；impl = 重写件。
RTL_DIR = ../../../rtl
CHILDREN = XRetPermitModule MLevelPermitModule SLevelPermitModule PrivilegePermitModule \
           VirtualLevelPermitModule IndirectCSRPermitModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) CSRPermitModule))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) CSRPermitModule))
FM_VARIANTS = CSRPermitModule
# golden 闭包逐个写出文件名（fm_predict 的模型不展开变量）
FM_REF_DEPS_CSRPermitModule = XRetPermitModule.sv \
                              MLevelPermitModule.sv \
                              SLevelPermitModule.sv \
                              PrivilegePermitModule.sv \
                              VirtualLevelPermitModule.sv \
                              IndirectCSRPermitModule.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# 纯组合，无寄存器：三档 initreg 只是走流程。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)
