MODULE = DataPathArb

# DataPath 的 10 个读口/写口仲裁装配壳（5 × *RFWBCollideChecker + 5 × *RFReadArbiter）。
# 本层只有 WBArbiter 例化与常量 ready；WBArbiter 家族 13 变体全部 PROVEN_DIRECT
# （docs/coverage_three_axis.tsv），UT/FM 两侧白盒：ref 用 golden 同名件，impl 用本仓重写件
# （rtl/backend/WBArbiter*.sv + 共享核 xs_WBArbiter_core / xs_PriorityArbSelect）。无黑盒。
RTL_DIR  = ../../../rtl
WBARB    = WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_3 WBArbiter_30 WBArbiter_33 \
           WBArbiter_38 WBArbiter_52 WBArbiter_55 WBArbiter_58 WBArbiter_64 \
           WBArbiter_65 WBArbiter_66
SHELLS   = IntRFWBCollideChecker FpRFWBCollideChecker VfRFWBCollideChecker \
           V0RFWBCollideChecker VlRFWBCollideChecker \
           IntRFReadArbiter FpRFReadArbiter VfRFReadArbiter V0RFReadArbiter VlRFReadArbiter
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(WBARB) $(SHELLS)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(WBARB) $(SHELLS)))

FM_VARIANTS = IntRFWBCollideChecker \
              FpRFWBCollideChecker \
              VfRFWBCollideChecker \
              V0RFWBCollideChecker \
              VlRFWBCollideChecker \
              IntRFReadArbiter \
              FpRFReadArbiter \
              VfRFReadArbiter \
              V0RFReadArbiter \
              VlRFReadArbiter
FM_REF_DEPS_IntRFWBCollideChecker = WBArbiter.sv WBArbiter_1.sv WBArbiter_2.sv WBArbiter_3.sv
FM_REF_DEPS_FpRFWBCollideChecker  = WBArbiter_2.sv WBArbiter_3.sv
FM_REF_DEPS_VfRFWBCollideChecker  = WBArbiter_2.sv WBArbiter_3.sv
FM_REF_DEPS_V0RFWBCollideChecker  = WBArbiter_2.sv WBArbiter_3.sv
FM_REF_DEPS_VlRFWBCollideChecker  = WBArbiter_3.sv
FM_REF_DEPS_IntRFReadArbiter      = WBArbiter_30.sv WBArbiter_33.sv WBArbiter_38.sv
FM_REF_DEPS_FpRFReadArbiter       = WBArbiter_30.sv WBArbiter_38.sv
FM_REF_DEPS_VfRFReadArbiter       = WBArbiter_52.sv WBArbiter_55.sv WBArbiter_58.sv
FM_REF_DEPS_V0RFReadArbiter       = WBArbiter_64.sv WBArbiter_65.sv WBArbiter_66.sv
FM_REF_DEPS_VlRFReadArbiter       = WBArbiter_64.sv WBArbiter_65.sv WBArbiter_66.sv

# 关掉 merge_duplicated_registers：只为让 fm_predict 的 passing 模型严格适用（加强不是放宽）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_datapath_arb.py --check

# 10 个目标全部含 N=1 WBArbiter（对称死的反饥饿状态，见 fm_pins.tcl）：先配对、再开 vmucp 让 FM 真去比。
# 白名单与依据：verif/fm_target_config/<top>.tcl。
fm-IntRFWBCollideChecker fm-FpRFWBCollideChecker fm-VfRFWBCollideChecker \
fm-V0RFWBCollideChecker fm-VlRFWBCollideChecker \
fm-IntRFReadArbiter fm-FpRFReadArbiter fm-VfRFReadArbiter \
fm-V0RFReadArbiter fm-VlRFReadArbiter: \
    FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
