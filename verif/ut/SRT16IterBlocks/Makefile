MODULE = SRT16IterBlocks

# SRT radix-16 整数除法迭代块：SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6}。
# 子模块全部两侧白盒：ref 用 golden 同名件，impl 用本仓已签核重写件（下列 CHILDREN）。
RTL_DIR  = ../../../rtl
TARGETS  = SelBlock_v4 SpecBlock_v4 IterBlock_v4 IterBlock_v4_4 IterBlock_v4_6
CHILDREN = CSA3_2_3988 CSA3_2_3992 CSA3_2_3987 CSA3_2_4017 CSA3_2_4111 CSA3_2_4173 \
           SignDec Conversion Conversion_8 Conversion_12
# CSA3_2.sv 是 CSA3_2_* 家族的共用核文件（xs_CSA3_2_core），不是 golden 模块。
RTL_SRCS = $(RTL_DIR)/backend/CSA3_2.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# 系统级车道：golden 父级 SRT16Divint{,_4,_6}（含 golden SRT4qdsCons），以及把其中
# IterBlock 子树换成重写件（_xs）的副本 ut_gen/subst_*.sv（仅改模块名与一处例化名）。
PARENTS     = SRT16Divint SRT16Divint_4 SRT16Divint_6
SUBST_SRCS  = $(addprefix ut_gen/subst_,$(addsuffix .sv,$(PARENTS)))
TB_SRCS     = div_lane.sv $(SUBST_SRCS) tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(TARGETS) $(CHILDREN) $(PARENTS) SRT4qdsCons))

FM_VARIANTS = $(TARGETS)
FM_REF_DEPS_SelBlock_v4    = CSA3_2_3988.sv SignDec.sv
FM_REF_DEPS_SpecBlock_v4   = CSA3_2_3992.sv SignDec.sv
ITER_COMMON_DEPS           = SelBlock_v4.sv SpecBlock_v4.sv CSA3_2_3988.sv CSA3_2_3992.sv SignDec.sv CSA3_2_4017.sv
FM_REF_DEPS_IterBlock_v4   = $(ITER_COMMON_DEPS) CSA3_2_3987.sv Conversion.sv
FM_REF_DEPS_IterBlock_v4_4 = $(ITER_COMMON_DEPS) CSA3_2_4111.sv Conversion_8.sv
FM_REF_DEPS_IterBlock_v4_6 = $(ITER_COMMON_DEPS) CSA3_2_4173.sv Conversion_12.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 父级替换副本：模块名 X -> X_subst，IterBlock 例化名 -> 重写件的 _xs 派生名。
# fail-closed：两处替换各须恰好命中 1 次，否则删掉产物并报错。
ut_gen/subst_%.sv: $(GOLDEN_RTL)/%.sv
	@mkdir -p ut_gen
	@iter=$$(grep -oE '^  IterBlock_v4(_4|_6)? ' $< | tr -d ' '); \
	  n=$$(grep -cE '^  IterBlock_v4(_4|_6)? ' $<); m=$$(grep -cE '^module $*\(' $<); \
	  [ "$$n" = 1 ] && [ "$$m" = 1 ] || { echo "subst $*: 例化命中 $$n / 模块头命中 $$m（须各 1）"; exit 1; }; \
	  sed -E -e 's/^module $*\(/module $*_subst(/' -e "s/^  $$iter /  $${iter}_xs /" $< > $@.tmp && \
	  [ $$(grep -cE "^  $${iter}_xs " $@.tmp) = 1 ] && mv $@.tmp $@ || { rm -f $@.tmp; exit 1; }

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
