MODULE = CsrEpcTvecLeaves7
RTL_DIR = ../../../rtl
EPC_LEAVES  = MepcModule SepcModule VSepcModule MnepcModule
TVEC_LEAVES = MtvecModule StvecModule VStvecModule
LEAVES = $(EPC_LEAVES) $(TVEC_LEAVES)
# 共享核（无 wrapper，参数 IS_TVEC 区分 epc/tvec 两亚族）+ 7 个薄 wrapper
RTL_SRCS = $(RTL_DIR)/backend/xs_CsrEpcTvec_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
# 7 个叶在 golden 里都是自包含（0 个子模块例化），无 FM_REF_DEPS_*。
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# golden 这 7 个模块的 `ifndef SYNTHESIS 块里没有断言，只有寄存器随机初值
# initial 块；+define+SYNTHESIS 把它关掉，与 FM 读入口径一致，初值统一交给
# +vcs+initreg 机制（编译期只开机制，取值在运行期选）。
# 本族全部寄存器都有异步复位（epc 63 位 / tvec mode+addr 各一），双例化对
# 上电初值不敏感；运行期仍按规范用常量档 +vcs+initreg+0。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
