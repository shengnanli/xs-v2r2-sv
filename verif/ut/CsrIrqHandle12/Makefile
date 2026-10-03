# CsrIrqHandle12 —— NewCSR 下 12 个中断/状态/处理类叶（csr-irq-handle lane）：
#   按中断号逐位的视图族  SieModule SipModule VSieModule VSipModule
#   虚拟中断寄存器        MvipModule HvipModule MvienModule HvienModule
#   状态/陷入             MStatusModule TrapHandleModule
#   PMP/PMA 跨条目规则    PMPEntryHandleModule PMAEntryHandleModule
# 全部是自足叶子：golden 0 个子模块例化，无黑盒，无 FM_REF_DEPS_*。
MODULE = CsrIrqHandle12

RTL_DIR = ../../../rtl
LEAVES  = SieModule SipModule VSieModule VSipModule \
          MvipModule HvipModule MvienModule HvienModule \
          MStatusModule TrapHandleModule \
          PMPEntryHandleModule PMAEntryHandleModule
# 包与共享核排在前面（包必须先于 import 它的模块被编译）。
RTL_SRCS = $(RTL_DIR)/backend/csr_irq_pkg.sv \
           $(RTL_DIR)/backend/xs_CsrVien_core.sv \
           $(RTL_DIR)/backend/xs_PmEntryHandle_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))

# FM_VARIANTS 必须写字面名：fm_predict.py / fm_passing_model.py 静态解析本文件，不展开变量。
FM_VARIANTS = SieModule SipModule VSieModule VSipModule \
              MvipModule HvipModule MvienModule HvienModule \
              MStatusModule TrapHandleModule \
              PMPEntryHandleModule PMAEntryHandleModule
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# +define+SYNTHESIS 关掉 golden 的 `ifndef SYNTHESIS 块（寄存器随机初值 initial 与
# MStatusModule 的两条 FS/VS Off 断言——随机激励必然触发它们，与等价性无关），
# 与 FM 读入口径一致；初值统一交给 +vcs+initreg。
# 12 个模块的全部寄存器都带异步复位，上电 8 拍复位后两侧同态，三档 initreg 都可用。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
