MODULE = SourceB

RTL_DIR = ../../../rtl
# child FastArbiter_5（4 入 1 出轮转仲裁器）两侧白盒：impl 用本仓重写件
# （rtl/uncore/FastArbiter_5.sv + 核 xs_FastArbiter_core，agent/mshrctl 签核），
# ref 用 golden 同名件（FM_REF_DEPS_SourceB）。
# UT：derive 把重写件改名 FastArbiter_5_xs 并同步改 SourceB_xs 里的例化，于是
# golden SourceB 例化 golden FastArbiter_5（GOLDEN_SRCS 里带上它），SourceB_xs 例化重写件。
RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter_5.sv
TB_SRCS = tb.sv

FM_REF_DEPS_SourceB = FastArbiter_5.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv $(GOLDEN_RTL)/FastArbiter_5.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = SourceB
# 关 merge_dup：fm_predict 的 passing 模型只在它关闭时成立
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
