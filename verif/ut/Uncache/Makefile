MODULE = Uncache

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（纯逻辑叶子模块，无子模块例化）
RTL_SRCS = $(RTL_DIR)/memblock/uncache_pkg.sv \
           $(RTL_DIR)/memblock/Uncache.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 Uncache（自含、无外部叶子依赖）
GOLDEN_SRCS = $(GOLDEN_RTL)/Uncache.sv

# FM：golden 顶层 Uncache vs 手写同名 wrapper（→ 可读核 + pkg）
WRAPPER_SRCS = $(RTL_DIR)/memblock/Uncache_wrapper.sv
FM_VARIANTS = Uncache

# 纯逻辑叶子，按签名分析应可干净配对；关掉“合并同值重复寄存器”pass，避免把
# 4 份结构相同的 entry/state 寄存器折叠成两侧不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
