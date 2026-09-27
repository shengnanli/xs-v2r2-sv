MODULE = StdFreeListVariants

RTL_DIR = ../../../rtl
# 核体在 StdFreeList.sv 里(家族共用的参数化核 xs_StdFreeList_core，全仓只此一份)，
# 三个变体文件各自只有一个设参数 + 端口展平的 wrapper(gen_variants.py 生成)。
# 快照存储走 SnapshotGenerator.sv 里的家族共核 xs_SnapshotGenerator_core(已独立签核)，
# 它在 RTL_SRCS(会 derive 改名、只进 impl 侧)，不是 RTL_GOLDEN_DEPS。
RTL_SRCS = $(RTL_DIR)/backend/StdFreeList.sv \
           $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/StdFreeList_1.sv \
           $(RTL_DIR)/backend/StdFreeList_2.sv \
           $(RTL_DIR)/backend/StdFreeList_3.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/StdFreeList_1.sv $(GOLDEN_RTL)/StdFreeList_2.sv \
              $(GOLDEN_RTL)/StdFreeList_3.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_11.sv $(GOLDEN_RTL)/SnapshotGenerator_12.sv

# 每个变体在 golden 里例化一个 SnapshotGenerator 变体(指针宽不同)：
#   StdFreeList_1 → SnapshotGenerator_11(value 7 位)；_2/_3 → SnapshotGenerator_12(value 5 位)。
# ref 侧读 golden 的该变体文件、impl 侧读重写共核，两侧白盒 elaborate —— 零黑盒。
FM_VARIANTS = StdFreeList_1 StdFreeList_2 StdFreeList_3
FM_REF_DEPS_StdFreeList_1 = SnapshotGenerator_11.sv
FM_REF_DEPS_StdFreeList_2 = SnapshotGenerator_12.sv
FM_REF_DEPS_StdFreeList_3 = SnapshotGenerator_12.sv

# 关掉 merge_duplicated_registers：让 fm_predict 的 passing 模型(寄存器位+输出位)严格适用，
# 跑前登记 / 跑后逐位对账(见 docs/fm_predictions/StdFreeList_{1,2,3}.json)。
FM_MERGE_DUP = false

# ★只对 StdFreeList_1 开 matched-unread 加强(vmucp)★ —— 依据与判据见
# verif/fm_target_config/StdFreeList_1.tcl。一句话：SIZE=81 的四分位边界 20/40/60 都是 4 的倍数，
# freeRegCntReg[1:0] 两侧同为死位(首跑 evidence/e9987342c6f9：passing 890 + unread 2(2) → PARTIAL)。
# _2/_3 没有 unread 点，对它们开 vmucp 会是空转(passing 不增)，所以按 target 分开：
# 递归展开的变量在 fm-% 配方里求值，$* 就是当前 target 名。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter StdFreeList_1,$*),true,)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言与随机初值 initial 块(都在 `ifndef SYNTHESIS 里)；
# FM 两侧都带 -define SYNTHESIS 读入，UT 保持同一口径。
# 两轮 initreg 在这里是真有区别的：redirect 两级打拍 / snpt 第二级 / freeRegCntReg /
# perf 两级 / 快照槽 payload 都不复位(golden 同)。tb 用暖机窗口保证快照槽在被读前写过。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# tb 与三个 wrapper 由生成器产出；这道检查防"手改产物后被下一次生成静默覆盖"。
.PHONY: gencheck
gencheck:
	python3 gen_variants.py --check
