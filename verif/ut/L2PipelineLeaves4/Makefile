# L2PipelineLeaves4 —— TL2CHICoupledL2 的 4 个 utility.Pipeline 单态化（csr-l2-leaves lane）：
#   Pipeline_2   每 slice 的 PrefetchTrain 打一拍（child Queue1_PrefetchTrain）
#   Pipeline_3   每 slice 的 PrefetchResp 打一拍（child Queue1_PrefetchResp）
#   Pipeline_10  hintPipe2：32 位 hint source 打两拍（child Queue1_UInt32 ×2）
#   Pipeline_11  hintPipe1：32 位 hint source 打一拍（child Queue1_UInt32）
# child 全部已签核（PROVEN_DIRECT，rtl/frontend/Queue1_*.sv + 共享核 xs_ChiselQueue1_core）：
# 按规范两侧白盒 —— ref = golden Pipeline + golden Queue1_*，impl = 重写 Pipeline + 重写 Queue1_*。无黑盒。
MODULE = L2PipelineLeaves4

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchTrain.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchResp.sv \
           $(RTL_DIR)/frontend/Queue1_UInt32.sv \
           $(RTL_DIR)/uncore/Pipeline_2.sv \
           $(RTL_DIR)/uncore/Pipeline_3.sv \
           $(RTL_DIR)/uncore/Pipeline_10.sv \
           $(RTL_DIR)/uncore/Pipeline_11.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Pipeline_2.sv $(GOLDEN_RTL)/Pipeline_3.sv \
              $(GOLDEN_RTL)/Pipeline_10.sv $(GOLDEN_RTL)/Pipeline_11.sv \
              $(GOLDEN_RTL)/Queue1_PrefetchTrain.sv $(GOLDEN_RTL)/Queue1_PrefetchResp.sv \
              $(GOLDEN_RTL)/Queue1_UInt32.sv

# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = Pipeline_2 Pipeline_3 Pipeline_10 Pipeline_11
FM_REF_DEPS_Pipeline_2 = Queue1_PrefetchTrain.sv
FM_REF_DEPS_Pipeline_3 = Queue1_PrefetchResp.sv
FM_REF_DEPS_Pipeline_10 = Queue1_UInt32.sv
FM_REF_DEPS_Pipeline_11 = Queue1_UInt32.sv
# vmucp 只开 Pipeline_2 / Pipeline_3：child 队列 ram 里 deq 侧无读者的对称死存储位（5 / 86 位），
# 与 child 独立签核时同一组点；依据与双射核对见 verif/fm_target_config/<T>.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = \
  $(if $(filter Pipeline_2 Pipeline_3,$*),true,)
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 队列存储寄存器不复位（tb arm 后再比）；valid 位异步复位。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
