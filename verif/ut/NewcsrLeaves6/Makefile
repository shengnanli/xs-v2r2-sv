MODULE = NewcsrLeaves6
RTL_DIR = ../../../rtl
# NewCSR 的 6 个 0 子模块叶（newcsr-close lane）：5 个 CSR 寄存器叶 + CSRPermitModule 的虚拟化权限叶。
LEAVES = VSstatusModule VSiselectModule VstartModule VStimecmpModule VtypeModule VirtualLevelPermitModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
# 6 个叶在 golden 里都是自包含（0 个子模块例化），无 FM_REF_DEPS_*。
# FM_VARIANTS 必须写字面名：fm_predict.py / fm_passing_model.py 静态解析本文件，不展开变量。
FM_VARIANTS = VSstatusModule VSiselectModule VstartModule VStimecmpModule VtypeModule \
              VirtualLevelPermitModule
FM_MERGE_DUP = false
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块只有随机初值 initial 与 VSstatus 的两条 FS/VS 断言；
# +define+SYNTHESIS 与 FM 读入口径一致。全部寄存器都是异步复位，tb 先复位再比，
# 所以三档 initreg（0 / random / <seed>017）都可用。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)
