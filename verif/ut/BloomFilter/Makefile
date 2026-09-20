MODULE = BloomFilter

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/BloomFilter.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS   = $(GOLDEN_RTL)/BloomFilter.sv

# 真叶子：golden BloomFilter.sv 里 0 个子模块例化，所以没有 FM_REF_DEPS_*。
FM_VARIANTS = BloomFilter

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# ★ 两处都要给 ★ 编译期 +vcs+initreg+random 打开机制（只给运行期会被 VCS 报
# Warning-[VICIU] 静默忽略，那一轮等于没测）；运行期 SIM_ARGS 选取值。
# 本模块**含不复位寄存器**（io_resp_*_bits_res_r），所以 random 与 0 两轮不是
# 走过场：random 轮下两侧上电值独立，tb 的暖机段（见 tb.sv 头注释）必须真的
# 把它们写成一致，否则 random 轮当场报错。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG  ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py
