MODULE = MEFreeList

RTL_DIR = ../../../rtl
# 可读核 + golden 同名 wrapper 都在 MEFreeList.sv 里；快照存储走 SnapshotGenerator.sv 里的
# 家族共核 xs_SnapshotGenerator_core(已独立签核)，它在 RTL_SRCS(会 derive 改名、只进 impl 侧)。
RTL_SRCS = $(RTL_DIR)/backend/MEFreeList.sv \
           $(RTL_DIR)/backend/SnapshotGenerator.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
# golden 顶层 MEFreeList 例化 SnapshotGenerator(base 变体，value 8 位)；
# ref 侧读 golden 的它、impl 侧读重写共核，两侧白盒 elaborate —— 零黑盒。
GOLDEN_SRCS = $(GOLDEN_RTL)/MEFreeList.sv $(GOLDEN_RTL)/SnapshotGenerator.sv
FM_VARIANTS = MEFreeList
FM_REF_DEPS_MEFreeList = SnapshotGenerator.sv

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型严格适用(同 StdFreeListVariants)。
FM_MERGE_DUP = false

# ★matched-unread 加强(vmucp)：本目标必须开★ —— 依据与判据见 verif/fm_target_config/MEFreeList.tcl。
# 一句话：golden 带 530 位只喂 XSError 的 debug 影子寄存器(debugArchHeadPtr 两级 + debugArchRAT
# 32×8 两级)，综合口径下是死位；重写核同名同宽同源复刻，两侧对称配对后由 vmucp 去证。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言与随机初值 initial 块(都在 `ifndef SYNTHESIS 里)；
# FM 两侧都带 -define SYNTHESIS 读入，UT 保持同一口径。两轮 initreg 真有区别：
# redirect 两级打拍 / snpt 第二级 / freeRegCntReg / perf 两级 / 快照槽 payload 都不复位。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen_tb.py --check
