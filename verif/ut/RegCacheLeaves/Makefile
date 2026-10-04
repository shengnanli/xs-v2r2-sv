# RegCacheLeaves —— RegCache 的六个子模块（三个家族 × 两个变体）：
#   RegCacheDataModule{,_1}（数据存储体）、RegCacheAgeTimer{,_1}（年龄计时与比较矩阵）、
#   RegCacheAgeDetector{,_1}（按年龄矩阵挑替换项）。每个家族一个参数化核 + 薄 wrapper。
# 全部是自足叶子：无子模块、无黑盒。
MODULE = RegCacheLeaves

RTL_DIR  = ../../../rtl
RC_TOPS  = RegCacheDataModule RegCacheDataModule_1 RegCacheAgeTimer RegCacheAgeTimer_1 \
           RegCacheAgeDetector RegCacheAgeDetector_1
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(RC_TOPS)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(RC_TOPS)))

FM_VARIANTS = RegCacheDataModule RegCacheDataModule_1 RegCacheAgeTimer RegCacheAgeTimer_1 \
              RegCacheAgeDetector RegCacheAgeDetector_1
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# DataModule 的 mem 不复位：tb 的 arm 等每项都写过一遍才开比；其余寄存器全部异步复位。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
