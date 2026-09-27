# Trace —— 跟踪三级流水；两个目标：Trace（父）与 TraceBuffer（唯一子模块，同一 lane 重写）
#
# TraceBuffer 是 Trace 的唯一子模块，本 lane 一并重写：UT 里随 Trace_xs 一起派生成
# TraceBuffer_xs 与 golden TraceBuffer（在 golden Trace 内）对比；FM 侧 ref 走 golden
# TraceBuffer.sv（FM_REF_DEPS），impl 走可读件，两侧完整 elaborate、无黑盒。
MODULE = Trace

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/TraceBuffer.sv \
           $(RTL_DIR)/backend/Trace.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/TraceBuffer.sv $(GOLDEN_RTL)/Trace.sv

FM_VARIANTS = Trace TraceBuffer
FM_REF_DEPS_Trace = TraceBuffer.sv
FM_REF_DEPS_TraceBuffer =

PORTLINT_ORDER = fail

# 关掉 FM 的重复寄存器合并：让 passing 预测模型（Σ寄存器位 + 输出位）严格适用，
# 跑前登记、跑后逐点对账（scripts/fm_predict.py）。两侧的重复寄存器都按 golden 保留。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 段两侧统一用 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# 两档 initreg。无复位寄存器：TraceBuffer 的 traceEntries×8 与 deqPtrPre、Trace 的 s3 打拍
# 寄存器。deqPtrPre/s3 在复位撤销后 1~2 拍写定；traceEntries 只在 deqPtrPre+i 落在
# [deqPtr, enqPtr) 内才被读出，而该区间的项必然已写过。tb 从第 4 拍起比对。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
