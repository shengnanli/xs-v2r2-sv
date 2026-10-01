MODULE = ArithVecLeaves5

# 族 A：算术/向量运算叶 ×5。
#   Adder_chain_rnd / VIAluDecoder / VIntAdder64b：纯组合叶，无子模块。
#   DivUnit：golden 闭包 = SRT16DividerDataModule + CSA3_2_3956/3960/3962 + RightShifter。
#   FDivSqrt：golden 闭包 = FloatDivider + FloatDividerR64 + fpsqrt_r16(+_block) +
#     fpdiv_r64_block + CSA3to2_20/24 + ShiftLeftPriorityWithLZDResult + lzc +
#     r4_qds{,_cg,_spec,_v2,_v2_spec}。
# 闭包用 grep 递归实例化关系核实（scripts 侧无吸收、不改写）：
# UT 两侧共用同一份 golden 孩子（RTL_GOLDEN_DEPS），FM 侧 ref/impl 同源同闭包
# （FM_REF_DEPS_*，相对 golden-rtl 的文件名列表）。
RTL_DIR  = ../../../rtl
LEAVES = Adder_chain_rnd DivUnit FDivSqrt VIAluDecoder VIntAdder64b
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))

DIVUNIT_DEPS = SRT16DividerDataModule.sv CSA3_2_3956.sv CSA3_2_3960.sv CSA3_2_3962.sv \
               RightShifter.sv
FDIVSQRT_DEPS = FloatDivider.sv FloatDividerR64.sv fpsqrt_r16.sv fpdiv_r64_block.sv \
                fpsqrt_r16_block.sv CSA3to2_20.sv CSA3to2_24.sv \
                ShiftLeftPriorityWithLZDResult.sv lzc.sv r4_qds.sv r4_qds_cg.sv \
                r4_qds_spec.sv r4_qds_v2.sv r4_qds_v2_spec.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(DIVUNIT_DEPS) $(FDIVSQRT_DEPS))

FM_VARIANTS = $(LEAVES)
FM_REF_DEPS_DivUnit  = $(DIVUNIT_DEPS)
FM_REF_DEPS_FDivSqrt = $(FDIVSQRT_DEPS)

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（FDivSqrt 的断言调用未定义的 xs_assert_v2 + 随机初值）；
# 两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值（ut_common 的 INITREG_TAG 会给日志留档）。
# 默认 INITREG=0（常量初值）：DivUnit/FDivSqrt 的输出 payload 寄存器无复位，
# 常量档保证两侧同初态；tb 另有 armed 闸，随机初值档也不会误判。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

# FDivSqrt 唯一 unread 点是 golden 闭包（VectorFloatDividerR64）内两侧同死的
# matched_nc 死位 fp_format_onehot_q_reg[2]，依据与白名单见
# verif/fm_target_config/FDivSqrt.tcl。只作用在 FDivSqrt：vmucp=true 无白名单
# 会被 fm_eq.tcl fail-closed 拒掉，其余 4 个 unread=0 的目标不能开。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter FDivSqrt,$*),true,)
