MODULE = VSetRiWvf

# VSetRiWvf（vset 写 vl 寄存器堆形态，组合 FU）。tb 由 scripts/gen_exeunits_ut.py 生成。
# golden 例化 VsetModule；重写件把它写成 vset_pkg 的纯函数、不例化（与 VSetRiWi / VSetRvfWvf 同），
# 所以 VsetModule 只在 ref 侧（FM_REF_DEPS）出现，impl 侧无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/backend_common_pkg.sv $(RTL_DIR)/backend/VSetRiWvf.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/VSetRiWvf.sv $(GOLDEN_RTL)/VsetModule.sv

FM_VARIANTS = VSetRiWvf
FM_REF_DEPS_VSetRiWvf = VsetModule.sv
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（编译期开机制，运行期选值）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
