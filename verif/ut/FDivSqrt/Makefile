MODULE = FDivSqrt

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/fdivsqrt_pkg.sv \
           $(RTL_DIR)/backend/FDivSqrt.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 迭代除/开方器 FloatDivider 及其全部叶子（含 sqrt/div block 与 r4_qds 等，
# 两侧 UT 共用同一实现）。
FDIV_DEPS = FloatDivider.sv FloatDividerR64.sv ShiftLeftPriorityWithLZDResult.sv \
            fpdiv_r64_block.sv fpsqrt_r16.sv fpsqrt_r16_block.sv lzc.sv \
            r4_qds.sv r4_qds_cg.sv r4_qds_spec.sv r4_qds_v2.sv r4_qds_v2_spec.sv \
            CSA3to2_20.sv CSA3to2_24.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FDivSqrt.sv $(addprefix $(GOLDEN_RTL)/,$(FDIV_DEPS))

WRAPPER_SRCS = $(RTL_DIR)/backend/FDivSqrt_wrapper.sv $(addprefix $(GOLDEN_RTL)/,$(FDIV_DEPS))
FM_VARIANTS = FDivSqrt
FM_REF_DEPS_FDivSqrt = $(FDIV_DEPS)
# 与定长流水 FU 不同：FDivSqrt 的 golden 把 robIdx 锁存成两份同值副本——一份给 flush
# 比较(outCtrl_r)、一份给输出端(io_out_bits_ctrl_robIdx_r)。可读核合并为单份。需开启
# 合并同值重复寄存器(默认 true)，FM 才能把 golden 两份副本归并到可读核单份；关掉则
# 输出端那份副本无对应、判失配。FloatDivider 黑盒两侧同名共享，merge=true 不影响其内部。
FM_MERGE_DUP = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
