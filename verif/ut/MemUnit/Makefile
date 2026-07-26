MODULE = MemUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_MemUnit_core（含 xs_memunit_pkg）+ 扁平端口包装 MemUnit
RTL_SRCS = $(RTL_DIR)/l2/MemUnit.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 + golden FastArbiter_50/52
# （两侧 elaborate 确定性仲裁逻辑, 非厂商宏, 消除黑盒——impl 与 ref 同读同一子模块）。
WRAPPER_SRCS = $(RTL_DIR)/l2/MemUnit_wrapper.sv $(GOLDEN_RTL)/FastArbiter_50.sv $(GOLDEN_RTL)/FastArbiter_52.sv
# golden 顶层 + 其两个子模块 FastArbiter_50/52（UT 双例化两侧共用同一定义）
GOLDEN_SRCS = $(GOLDEN_RTL)/MemUnit.sv $(GOLDEN_RTL)/FastArbiter_50.sv $(GOLDEN_RTL)/FastArbiter_52.sv
# UT 变体（impl 顶层改名 MemUnit_xs 以与 golden MemUnit 双例化）
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 MemUnit 顶层；FastArbiter_50/52 两侧 elaborate 作为共同子模块
FM_VARIANTS = MemUnit
FM_REF_DEPS_MemUnit = FastArbiter_50.sv FastArbiter_52.sv

# bufferTimer(256)/REG(16) 为泄漏检测计时器, 仅被 `ifndef SYNTHESIS 断言读取 →
# 两侧对称 cone-dead。fm_pins.tcl 建立 golden 展平名 ↔ impl 2D 数组名的 1:1 双射,
# 配合 verify_matched_unread_compare_points=true 让 FM 实际比较证明等价(class-4 加强证明,
# 非 waiver)。MemUnit 须由 main 加入 fm_eq.tcl/run_signoff_target.sh 的 matched-unread
# 白名单方可运行本加强(standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden MemUnit 含 `ifndef SYNTHESIS 的随机初值与断言（MemBuf overflow /
# Mem task repeated / MemBuf Leak）；UT 随机激励会触发，故定义 SYNTHESIS 关掉
# （同时关随机初值注入，使两侧寄存器复位到 0 后同构可比）。
VCS += +define+SYNTHESIS
