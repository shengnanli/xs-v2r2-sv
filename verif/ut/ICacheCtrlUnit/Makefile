MODULE = ICacheCtrlUnit

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
           $(RTL_DIR)/frontend/Queue1_RegMapperInput_3.sv
TB_SRCS = tb.sv

FM_REF_DEPS_ICacheCtrlUnit = Queue1_RegMapperInput_3.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheCtrlUnit.sv \
              $(GOLDEN_RTL)/Queue1_RegMapperInput_3.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = Queue1_RegMapperInput_3 ICacheCtrlUnit

include ../../../scripts/ut_common.mk
