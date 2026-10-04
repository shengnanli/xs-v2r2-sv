MODULE = TLBuffer_13

# TLBuffer_13：L2Top.inner_buffer，4 路 TL-C 五通道缓冲（rocket-chip TLBuffer(BufferParams.default)）。
# impl = rtl/memblock/TLBuffer_13.sv（手写 xs_TLBuffer_13_bank + gen_tlbuffer13.py 生成的 wrapper）
#      + 本仓已签重写队列 Queue2_TLBundle{A_19,B_1,C_1,D_20,E_1}（两侧白盒，ref 读 golden 同名件）。
# ram_* 是 firtool 行为级存储叶子：两侧读同一份 golden 文件（inline，不是黑盒；2 项 / 1 位地址，
# 2^1 == 2，无 FMR_ELAB-147 越界问题）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/TLBuffer_13.sv \
           $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleA_19.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleB_1.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleC_1.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleD_20.sv \
           $(RTL_DIR)/uncore/Queue2_TLBundleE_1.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_2x119.sv \
                  $(GOLDEN_RTL)/ram_2x283.sv \
                  $(GOLDEN_RTL)/ram_2x321.sv \
                  $(GOLDEN_RTL)/ram_2x352.sv \
                  $(GOLDEN_RTL)/ram_sink_2x8.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TLBuffer_13.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleA_19.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleB_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleC_1.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleD_20.sv \
              $(GOLDEN_RTL)/Queue2_TLBundleE_1.sv
FM_REF_DEPS_TLBuffer_13 = Queue2_TLBundleA_19.sv Queue2_TLBundleB_1.sv Queue2_TLBundleC_1.sv Queue2_TLBundleD_20.sv Queue2_TLBundleE_1.sv ram_2x119.sv ram_2x283.sv ram_2x321.sv ram_2x352.sv ram_sink_2x8.sv
FM_VARIANTS = TLBuffer_13

# FM_MERGE_DUP = false：B 通道 ram 里的常量位（W0_data 的 32'hFFFFFFFF / 10'h6 / 1'h0）次态与使能
# 完全相同，merge=true 时 Formality 会把它们合并，且两侧合并结果不对称（上一轮实测：
# ref 704 -> 688、impl 仍 704，36 failing / 64 unmatched）。关掉是加强不是放宽：不黑盒、不跳点，
# 比较点反而更多；同时 fm_predict 模型（寄存器位 + 输出位）在 merge=false 下严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_tlbuffer13.py --check
