# CtrlUnit —— DCache 伪错误注入控制器（TileLink 寄存器外设）+ 它的 A 通道队列 Queue1_RegMapperInput_6。
# CtrlUnit 的 child：Queue1_RegMapperInput_6（本 lane 重写，同目录签核）、
#   NewPipelineConnectPipe_27 ×2（docs/coverage_three_axis.tsv = PROVEN_DIRECT）。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件；无黑盒。
MODULE = CtrlUnit

RTL_DIR  = ../../../rtl
# xs_Queue1_RegMapperInput 核体在 ICacheCtrlUnit.sv 里（单文件规范：核跟着首个使用者走）；
# NewPipelineConnectPipe_27 的核体在 rtl/common/PipelineConnect.sv。
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
           $(RTL_DIR)/memblock/Queue1_RegMapperInput_6.sv \
           $(RTL_DIR)/common/PipelineConnect.sv \
           $(RTL_DIR)/uncore/NewPipelineConnectPipe_27.sv \
           $(RTL_DIR)/memblock/CtrlUnit.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CtrlUnit.sv \
              $(GOLDEN_RTL)/Queue1_RegMapperInput_6.sv \
              $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv

FM_VARIANTS = CtrlUnit
FM_REF_DEPS_CtrlUnit = Queue1_RegMapperInput_6.sv NewPipelineConnectPipe_27.sv

FM_MERGE_DUP = false
PORTLINT_ORDER = fail

# vmucp（加强不是放宽）：Connect0（tag 通道）通道 1..7 的 455 位 payload 寄存器两侧对称死位，
# 由 fm_pins_pre.tcl（scripts/gen_ctrlunit_pins.py 生成）钉成 matched 后真比较。
# 依据与六条证据见 verif/fm_target_config/CtrlUnit.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_ctrlunit_pins.py --check
