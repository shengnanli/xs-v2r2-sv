# BlockCipherModule —— 标量密码扩展的分组密码块（AES / SM4 单轮部件，两拍）。叶子：无子模块、无黑盒。
# UT（gen.py）：双例化逐拍比 + 查表参考模型逐条判 golden + FIPS-197 / GB/T 32907 标准测试向量。
MODULE = BlockCipherModule

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/BlockCipherModule.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

GOLDEN_SRCS = $(GOLDEN_RTL)/BlockCipherModule.sv

FM_VARIANTS = BlockCipherModule
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# SYNTHESIS 关掉 golden 的随机初始化。重写件里 S 盒分解的仿真自检在 ifndef SYNTHESIS 下（这里不编），
# 同样的核对由 tb 直接调包函数做（见 gen.py 的 SBOX-SELFCHECK）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
