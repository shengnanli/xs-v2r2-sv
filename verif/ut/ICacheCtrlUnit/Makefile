MODULE = ICacheCtrlUnit

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/ICacheCtrlUnit.sv
TB_SRCS = tb.sv

# G1 里 ICacheCtrlUnit.out_back_q 的类型是 Queue1_RegMapperInput_5（G0 叫 _3；
# G1 的 _3 是 MemMisc/TLPMA 的另一个队列）。该子模块自己的 UT/FM 在
# verif/ut/Queue1_RegMapperInput_5/，本目录只证 ICacheCtrlUnit 本体。
FM_REF_DEPS_ICacheCtrlUnit = Queue1_RegMapperInput_5.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/ICacheCtrlUnit.sv \
              $(GOLDEN_RTL)/Queue1_RegMapperInput_5.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = ICacheCtrlUnit

include ../../../scripts/ut_common.mk
