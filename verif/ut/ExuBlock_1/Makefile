MODULE = ExuBlock_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exublock_1_pkg.sv \
           $(RTL_DIR)/backend/ExuBlock_1.sv

TB_SRCS = variants_xs.sv tb.sv

# ExeUnit 各变体(功能单元实体)全部作 golden 黑盒;UT 双例化两侧共用同一份定义。
SUB_DEPS = $(GOLDEN_RTL)/ExeUnit_10.sv \
           $(GOLDEN_RTL)/ExeUnit_8.sv \
           $(GOLDEN_RTL)/ExeUnit_9.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExuBlock_1.sv $(SUB_DEPS)

# FM:impl 侧(wrapper→可读核)与 ref 侧在相同层次黑盒化 ExeUnit。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExuBlock_1_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = ExuBlock_1
FM_REF_DEPS_ExuBlock_1 = ExeUnit_10.sv ExeUnit_8.sv ExeUnit_9.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# ExeUnit 黑盒内例化更深的 golden 叶子(Alu/CSR/Dispatcher/...),用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
