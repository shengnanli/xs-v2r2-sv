MODULE = PTWRepeaterNB
RTL_DIR = ../../../rtl
# UT/FM 用冻结 canonical golden(G0)。
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 + pkg。唯一子模块 DelayN_1(sfence/csr 变更 2 拍延迟 → flush)两侧同源 elaborate
#   (纯逻辑 2 级移位链, 非黑盒), impl 侧随核一起编。
RTL_SRCS = $(RTL_DIR)/memblock/ptwrepeaternb_pkg.sv \
           $(RTL_DIR)/memblock/PTWRepeaterNB.sv \
           $(GOLDEN_RTL)/DelayN_1.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/PTWRepeaterNB_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PTWRepeaterNB.sv $(GOLDEN_RTL)/DelayN_1.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = PTWRepeaterNB
# DelayN_1 两侧 elaborate(ref 侧作依赖): golden==golden 对称白盒, 非黑盒复用。
FM_REF_DEPS_PTWRepeaterNB = DelayN_1.sv

include ../../../scripts/ut_common.mk

# golden 的 ENABLE_INITIAL_REG_ 随机初值块用 SYNTHESIS 关掉(两侧复位到 0 同构可比)。
VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + DelayN_1 + golden 顶 + tb(不编 golden 同名 wrapper 避免重名)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(GOLDEN_RTL)/PTWRepeaterNB.sv $(TB_SRCS) -top tb -o simv
