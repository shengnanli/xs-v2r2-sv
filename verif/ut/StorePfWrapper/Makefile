# StorePfWrapper —— Sbuffer 的 store 预取外壳（ENABLE_SPB=false 下只剩一个 Serializer 实例）。
# 无输出端口，tb 用层次探针 + 状态注入逐拍比 serializer 内部死指针（同 verif/ut/Serializer）。
# child Serializer 已签核（PROVEN_DIRECT）：两侧白盒，ref = golden，impl = 重写件。无黑盒。
MODULE = StorePfWrapper

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/Serializer.sv \
           $(RTL_DIR)/memblock/StorePfWrapper.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Serializer.sv \
              $(GOLDEN_RTL)/StorePfWrapper.sv

FM_VARIANTS = StorePfWrapper
FM_REF_DEPS_StorePfWrapper = Serializer.sv
FM_MERGE_DUP = false
# 全部 5 个比较点零扇出（无输出端口），只能靠 vmucp 真比较，见 verif/fm_target_config/StorePfWrapper.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
# tb.sv 手写（无输出端口，无 gen.py）；gencheck 恒真
gencheck:
	@echo "StorePfWrapper: tb.sv 为手写探针 tb，无生成器"
