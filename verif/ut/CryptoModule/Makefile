# CryptoModule —— Bku 下的标量密码子块：HashModule / BlockCipherModule 二选一（funcReg[4]）。
# child 两个都已签核（PROVEN_DIRECT）：两侧白盒，ref = golden，impl = 重写件。无黑盒。
# UT（gen.py）：双例化逐拍比 + 哈希分支独立参考模型（Zknh/Zksh 定义式）。
MODULE = CryptoModule

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/HashModule.sv \
           $(RTL_DIR)/backend/BlockCipherModule.sv \
           $(RTL_DIR)/backend/CryptoModule.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/HashModule.sv \
              $(GOLDEN_RTL)/BlockCipherModule.sv \
              $(GOLDEN_RTL)/CryptoModule.sv

FM_VARIANTS = CryptoModule
FM_REF_DEPS_CryptoModule = HashModule.sv BlockCipherModule.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false

# funcReg 9 位只读 bit4，其余 8 位两侧同为死位（依据与期望数见 verif/fm_target_config/CryptoModule.tcl）；
# 两侧寄存器同名同位置，FM 直接配对；开 vmucp 让 FM 实际比较这些点。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器无复位（照抄 golden）：tb 在第一次 regEnable 之后才开始比（arm）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
