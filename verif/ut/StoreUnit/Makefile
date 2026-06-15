MODULE = StoreUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内例化 golden 同名 MemTrigger_3 黑盒）
RTL_SRCS = $(RTL_DIR)/memblock/storeunit_pkg.sv \
           $(RTL_DIR)/memblock/StoreUnit.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 叶子子模块 MemTrigger_3（UT 双例化两侧共用同一份 trigger 实现，
# 比对只检验顶层流水/仲裁/异常/uncache/写回是否等价）。
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreUnit.sv $(GOLDEN_RTL)/MemTrigger_3.sv

# FM：golden 顶层 StoreUnit（含 MemTrigger_3 黑盒）vs 手写同名 wrapper（→ 可读核 + 黑盒）。
# MemTrigger_3 放 WRAPPER_SRCS 让 impl 侧也读入，使 trigger 点两侧配对（否则失配）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/StoreUnit_wrapper.sv $(GOLDEN_RTL)/MemTrigger_3.sv
FM_VARIANTS = StoreUnit
FM_REF_DEPS_StoreUnit = MemTrigger_3.sv

# 关闭 FM 的“合并同值重复寄存器”pass：本核刻意保留 golden 的 5 份同值
# TLB-hit 打拍副本与逐 bit trigger 寄存器、并与 golden 同名，靠按名配对即可干净比对；
# 若开启合并，反而会把 trigger 高位（黑盒同源驱动）与 isCbo 等折叠成两侧不对称，导致失配。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
