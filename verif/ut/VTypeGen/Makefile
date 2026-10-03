# VTypeGen —— 译码级推测 vtype 生成器（DecodeStage 例化 1 份）
#
# 子模块 VsetModule 没有独立 UT/FM target：本重写把它的 vtype 合法性判定以 vset_pkg
# （rtl/backend/backend_common_pkg.sv，与 VSetRiWi/VSetRvfWvf 共用）的纯函数内联进可读核，
# 没有例化。FM 时 ref 侧 = golden VTypeGen + VsetModule 两侧完整 elaborate（白盒），
# impl 侧 = backend_common_pkg + VTypeGen.sv；无黑盒。
MODULE = VTypeGen

RTL_DIR  = ../../../rtl
# backend_common_pkg.sv 里的 vset_pkg 必须排在使用者之前
RTL_SRCS = $(RTL_DIR)/backend/backend_common_pkg.sv $(RTL_DIR)/backend/VTypeGen.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VTypeGen.sv $(GOLDEN_RTL)/VsetModule.sv

FM_VARIANTS = VTypeGen
FM_REF_DEPS_VTypeGen = VsetModule.sv

# merge_dup=false：加强（逐个比而不是合并后比），同时让 fm_predict 的模型按构造适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段（随机初值）两侧统一关掉。
# 复位域：vtypeArch/vtypeSpec 共 16 位，全部异步复位（复位值 illegal=1）；没有不复位的寄存器，
# 两轮 initreg（+0 / +random）都必须 errors=0，且 tb 在复位拍也比对。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random
