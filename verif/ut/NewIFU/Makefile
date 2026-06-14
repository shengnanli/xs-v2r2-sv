MODULE = NewIFU

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写核 + 其例化的子模块定义（UT 编译 + FM impl 都用）：
#   - NewIFU.sv      : xs_NewIFU_core（顶层取指单元核心）
#   - RVCExpander.sv : RVCExpander（手写可读核，供 NewIFU 与 RVCExpander 两个 FM 变体用）
#   - 其余子模块（PreDecode/PredChecker/FrontendTrigger/F3Predecoder）直接用 golden 网表：
#     两侧（ref/impl）使用同一 golden 子模块，FM 逐层比对即抵消，只需验证 NewIFU 本体逻辑。
RTL_SRCS = $(RTL_DIR)/frontend/RVCExpander.sv \
           $(GOLDEN_RTL)/PreDecode.sv \
           $(GOLDEN_RTL)/PredChecker.sv \
           $(GOLDEN_RTL)/FrontendTrigger.sv \
           $(GOLDEN_RTL)/F3Predecoder.sv \
           $(RTL_DIR)/frontend/NewIFU.sv

# golden 同名包装层（模块 NewIFU，核 xs_NewIFU_core），仅 FM 用。
WRAPPER_SRCS = $(RTL_DIR)/frontend/NewIFU_wrapper.sv

# UT 双例化比对：golden NewIFU + 其全部 golden 子模块。
#   tb 例化 golden NewIFU（u_g）与 NewIFU_xs（u_i，核例化上面 RTL_SRCS 中的子模块）。
#   golden NewIFU 例化的 RVCExpander 解析到 RTL_SRCS 中手写 RVCExpander（与 golden 等价）。
GOLDEN_SRCS = $(GOLDEN_RTL)/NewIFU.sv \
              $(GOLDEN_RTL)/PreDecode.sv \
              $(GOLDEN_RTL)/PredChecker.sv \
              $(GOLDEN_RTL)/FrontendTrigger.sv \
              $(GOLDEN_RTL)/F3Predecoder.sv
TB_SRCS = variants_xs.sv tb.sv

# 两个 FM 变体分别验证：
#   NewIFU      : 顶层取指单元（ref 带全部 golden 子模块，含 golden RVCExpander）
#   RVCExpander : 手写可读 RVCExpander vs golden RVCExpander（纯组合）
FM_VARIANTS = NewIFU RVCExpander
FM_REF_DEPS_NewIFU = PreDecode.sv PredChecker.sv FrontendTrigger.sv F3Predecoder.sv RVCExpander.sv
FM_REF_DEPS_RVCExpander =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化 / 运行期断言（$fatal）；UT 随机激励下定义
# SYNTHESIS 屏蔽断言块，并关闭 firtool 随机初始化，使两侧均从复位态出发。
# 注意 ut_common.mk 用 VCS := 简单赋值，故此 append 必须放在 include 之后。
VCS += +define+SYNTHESIS
