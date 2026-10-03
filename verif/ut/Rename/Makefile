MODULE = Rename

RTL_DIR = ../../../rtl
# 单文件规范：package rename_pkg + xs_Rename_core + golden 同名 wrapper 都在 Rename.sv 里
# (wrapper 由本目录 gen_rename.py 生成)。子模块全部是本仓已重写并签核的件，白盒例化：
#   CompressUnit(压缩判定)、MEFreeList(整数)、StdFreeList/_1/_2/_3(fp/vec/v0/vl)、
#   SnapshotGenerator.sv(FreeList 家族共用的快照存储核)。
RTL_SRCS = $(RTL_DIR)/backend/stdfreelist_pkg.sv \
           $(RTL_DIR)/backend/Rename.sv \
           $(RTL_DIR)/backend/CompressUnit.sv \
           $(RTL_DIR)/backend/MEFreeList.sv \
           $(RTL_DIR)/backend/StdFreeList.sv \
           $(RTL_DIR)/backend/StdFreeList_1.sv \
           $(RTL_DIR)/backend/StdFreeList_2.sv \
           $(RTL_DIR)/backend/StdFreeList_3.sv \
           $(RTL_DIR)/backend/SnapshotGenerator.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# golden 顶层 Rename 的直接 child 5 个 + FreeList 各自的 SnapshotGenerator 变体 3 个。
RENAME_CHILDREN = CompressUnit.sv MEFreeList.sv StdFreeList.sv StdFreeList_1.sv \
                  StdFreeList_2.sv StdFreeList_3.sv \
                  SnapshotGenerator.sv SnapshotGenerator_11.sv SnapshotGenerator_12.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Rename.sv $(addprefix $(GOLDEN_RTL)/,$(RENAME_CHILDREN))

FM_VARIANTS = Rename
FM_REF_DEPS_Rename = $(RENAME_CHILDREN)

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/Rename.tcl★ —— intFreeList(MEFreeList)里那 530 位
# debug 影子寄存器在整证里同样是两侧对称的死位，钉点脚本 fm_pins.tcl 按叶名配对
# (与 verif/ut/MEFreeList/fm_pins.tcl 同一套规则)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 XSError/assert 与随机初值 initial 块(都在 `ifndef SYNTHESIS 里)；FM 两侧同口径。
# 两轮 initreg 真有区别：perf 两级流水 / intFreePhyReg_REG / debugRedirect_* / FreeList 内
# 的 redirect 打拍与快照槽 payload 都不复位；tb 用暖机窗口(useSnpt=0)让快照槽先写满。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen_rename.py --check
