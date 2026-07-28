MODULE = ExuBlock_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。
RTL_SRCS = $(RTL_DIR)/backend/exublock_2_pkg.sv \
           $(RTL_DIR)/backend/ExuBlock_2.sv

TB_SRCS = variants_xs.sv tb.sv

# ExeUnit 各变体(功能单元实体)全部作 golden 黑盒;UT 双例化两侧共用同一份定义。
SUB_DEPS = $(GOLDEN_RTL)/ExeUnit_13.sv \
           $(GOLDEN_RTL)/ExeUnit_14.sv \
           $(GOLDEN_RTL)/ExeUnit_15.sv \
           $(GOLDEN_RTL)/ExeUnit_16.sv \
           $(GOLDEN_RTL)/ExeUnit_17.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/ExuBlock_2.sv $(SUB_DEPS)

# FM: ExeUnit 各变体在其**边界**黑盒化(两侧同名 unresolved black box, 经
# hdlin_unresolved_modules=black_box 自动配对)。不给 FM 提供 ExeUnit .sv ——
# 否则 FM 会 elaborate 进 ExeUnit 内部、把更深的向量 FU(Vfma/VialuFix/Vppu...)当
# 黑盒, 而这些 FU 的 io_out_bits_ctrl_pdest[7] 是 undriven 黑盒输出(ExeUnit 自身
# io_in_bits_pdest 只有 7 位[6:0]), 导致 8 个 matched-undriven 比较点无法判定而 fail。
# 在 ExeUnit 边界黑盒即让其输出成为受驱动的黑盒 pin, 两侧同名匹配 => 干净等价。
WRAPPER_SRCS = $(RTL_DIR)/backend/ExuBlock_2_wrapper.sv
FM_VARIANTS = ExuBlock_2

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# ExeUnit 黑盒内例化更深的 golden 叶子(Alu/CSR/Dispatcher/...),用 -y 库目录自动解析。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
