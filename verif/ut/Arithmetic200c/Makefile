MODULE = Arithmetic200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter_27.sv \
           $(RTL_DIR)/backend/FliDTable.sv \
           $(RTL_DIR)/backend/FliHTable.sv \
           $(RTL_DIR)/backend/FliSTable.sv \
           $(RTL_DIR)/backend/IntBuffer_1.sv \
           $(RTL_DIR)/backend/IntBuffer_2.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter_27.sv \
              $(GOLDEN_RTL)/FliDTable.sv \
              $(GOLDEN_RTL)/FliHTable.sv \
              $(GOLDEN_RTL)/FliSTable.sv \
              $(GOLDEN_RTL)/IntBuffer_1.sv \
              $(GOLDEN_RTL)/IntBuffer_2.sv \
              $(GOLDEN_RTL)/Rec7Table.sv \
              $(GOLDEN_RTL)/Rsqrt7Table.sv
FM_VARIANTS = FastArbiter_27 FliDTable FliHTable FliSTable IntBuffer_1 IntBuffer_2 Rec7Table Rsqrt7Table
PORTLINT_ORDER = fail
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用（加强，不是放宽）。
FM_MERGE_DUP = false
# vmucp 只对 FastArbiter_27 打开（pendingMask[0] 对称死位，依据见 verif/fm_target_config/FastArbiter_27.tcl）；
# 其余 7 个目标没有白名单条目，保持关闭。
fm-FastArbiter_27: FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
include ../../../scripts/ut_common.mk
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
INITREG ?= 0
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
VCS_ARCH_OVERRIDE := linux
