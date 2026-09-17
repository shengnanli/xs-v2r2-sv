MODULE = IBuffer

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/IBuffer.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS   = $(GOLDEN_RTL)/IBuffer.sv

# 真叶子：golden IBuffer.sv 里 0 个子模块例化，所以没有 FM_REF_DEPS_*。
FM_VARIANTS = IBuffer

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# ★ 两处都要给 ★ 编译期 +vcs+initreg+random 打开机制（只给运行期会被 VCS 报
# Warning-[VICIU] 静默忽略，那一轮等于没测）；运行期 SIM_ARGS 选取值。
# 本模块的 18 个 perf 打拍寄存器不复位，但**每拍无条件更新**，两拍就收敛 ——
# 所以两轮 initreg 对本模块几乎证明不了复位域（tb 头注释里写明了这一点），
# 真正把复位域钉住的是 mutants.py 的 M5/M6。
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG  ?= +vcs+initreg+random

# tb.sv 由 gen.py 从 G1 golden 端口表生成（端口声明/连线/比对三段）。
# 文件名用 gen.py 而不是 gen_tb.py，是为了被 scripts/test_gen_idempotent.py
# 收进闸内（那道闸只认 verif/ut/*/gen.py）：重跑生成器后产物必须逐字不变，
# 防止有人手工改 tb.sv、下次跑生成器被静默覆盖。
.PHONY: tb mutants
tb:
	python3 gen.py

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
mutants:
	python3 mutants.py
