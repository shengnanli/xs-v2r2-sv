MODULE = FauFTB

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 参数化核（不含 golden 同名模块）：UT 编译 + FM impl 都用。
#   - FauFTB.sv      : xs_FauFTB_core
#   - FauFTBWay.sv   : xs_FauFTBWay（FM impl 侧 FauFTBWay 子模块的核；UT 中不被例化）
RTL_SRCS = $(RTL_DIR)/frontend/ftb_pkg.sv \
           $(RTL_DIR)/frontend/FauFTBWay.sv \
           $(RTL_DIR)/frontend/FauFTB.sv

# golden 同名包装层，仅 FM 用（FM impl = RTL_SRCS + WRAPPER_SRCS）：
#   - FauFTBWay_wrapper.sv : 模块 FauFTBWay（核 xs_FauFTBWay）
#   - FauFTB_wrapper.sv    : 模块 FauFTB   （核 xs_FauFTB_core，例化上面的 FauFTBWay）
WRAPPER_SRCS = $(RTL_DIR)/frontend/FauFTBWay_wrapper.sv \
               $(RTL_DIR)/frontend/FauFTB_wrapper.sv

# UT 双例化比对：golden FauFTB（含其子模块 golden FauFTBWay）。
#   tb 例化 golden FauFTB 与 FauFTB_xs；后者核例化 golden FauFTBWay（来自此处）。
GOLDEN_SRCS = $(GOLDEN_RTL)/FauFTB.sv $(GOLDEN_RTL)/FauFTBWay.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FauFTB
FM_REF_DEPS_FauFTB = FauFTBWay.sv

include ../../../scripts/ut_common.mk

# golden FauFTB.sv 含运行时 fallThrough 断言（`ifndef SYNTHESIS`），随机激励会误触发
# $fatal。UT 仅做输出端口逐拍比对，与断言无关 → 编译时定义 SYNTHESIS 屏蔽断言块
# （同时关闭 firtool 的随机初始化 initial，使两侧均从复位态出发，正合比对所需）。
VCS += +define+SYNTHESIS
