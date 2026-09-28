MODULE = IntRegFilePart

# IntRegFilePart0..3：整数物理寄存器堆的 4 个 16 位数据切片。G1 golden 四个文件逐行相同、
# 只差模块名（scripts/gen_intregfile.py 生成时逐行核对）。共用核 xs_IntRegFilePart_core +
# 四个生成的薄 wrapper。golden 里 0 个子模块例化（自包含叶子），没有 FM_REF_DEPS_*，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_IntRegFilePart_core.sv \
           $(RTL_DIR)/backend/IntRegFilePart0.sv \
           $(RTL_DIR)/backend/IntRegFilePart1.sv \
           $(RTL_DIR)/backend/IntRegFilePart2.sv \
           $(RTL_DIR)/backend/IntRegFilePart3.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/IntRegFilePart0.sv $(GOLDEN_RTL)/IntRegFilePart1.sv \
              $(GOLDEN_RTL)/IntRegFilePart2.sv $(GOLDEN_RTL)/IntRegFilePart3.sv

FM_VARIANTS = IntRegFilePart0 IntRegFilePart1 IntRegFilePart2 IntRegFilePart3

# 关掉 merge_duplicated_registers：只有关掉时 fm_predict 的 passing 模型才严格适用（加强不是放宽）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 同址写断言调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0          两实例初值相同（全 0）-> tb 加 +cmp_all，连"从没写过的行"也比
#   INITREG=random     种子取自 +ntb_random_seed（seed 1 退化成全 1，见 CONVENTIONS）
#   INITREG=<seed>017  真随机第三档
# 不复位寄存器在后两档两侧初值不同，tb 只比写过的行（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)

.PHONY: gencheck mutants
gencheck:
	python3 ../../../scripts/gen_intregfile.py --check

# 判别力负测：变异只发生在 scratchpad 副本里，不进库。见 mutants.py 头部。
mutants:
	python3 mutants.py
