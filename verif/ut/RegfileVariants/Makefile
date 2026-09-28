MODULE = RegfileVariants

# DataPath 的 11 个物理寄存器堆变体，同一个参数化核 xs_Regfile_core：
#   VlRegFile / V0RegFilePart0..1 / VfRegFilePart0..3 / FpRegFilePart0..3
# （IntRegFilePart0..3 归 intrf lane，不在这里。）叶子模块，无子模块、无黑盒。
RTL_DIR  = ../../../rtl
VARIANTS = VlRegFile V0RegFilePart0 V0RegFilePart1 \
           VfRegFilePart0 VfRegFilePart1 VfRegFilePart2 VfRegFilePart3 \
           FpRegFilePart0 FpRegFilePart1 FpRegFilePart2 FpRegFilePart3
RTL_SRCS = $(RTL_DIR)/backend/xs_Regfile_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))

FM_VARIANTS = VlRegFile \
              V0RegFilePart0 \
              V0RegFilePart1 \
              VfRegFilePart0 \
              VfRegFilePart1 \
              VfRegFilePart2 \
              VfRegFilePart3 \
              FpRegFilePart0 \
              FpRegFilePart1 \
              FpRegFilePart2 \
              FpRegFilePart3
# 同一写口在各行的 hit/wdata 是逐行独立的组合逻辑，没有重复寄存器；关掉 merge_dup 只为
# 让 fm_predict 的 passing 模型严格适用（加强不是放宽）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 同址多写断言调用未定义的 xs_assert_v2，与 FM 口径一致定义 SYNTHESIS
# （tb 故意制造同址多写来打 Mux1H 的按位或语义）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_datapath_rf.py --check
