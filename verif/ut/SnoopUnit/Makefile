MODULE = SnoopUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_SnoopUnit_core（含 xs_snoopunit_pkg）+ 扁平端口包装 SnoopUnit
RTL_SRCS = $(RTL_DIR)/l2/SnoopUnit.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 + golden FastArbiter_50
# （两侧 elaborate 确定性仲裁逻辑, 非厂商宏, 消除黑盒——impl 与 ref 同读同一子模块）。
WRAPPER_SRCS = $(RTL_DIR)/l2/SnoopUnit_wrapper.sv $(GOLDEN_RTL)/FastArbiter_50.sv
# golden 顶层 + 其唯一子模块 FastArbiter_50（UT 双例化两侧共用同一定义）
GOLDEN_SRCS = $(GOLDEN_RTL)/SnoopUnit.sv $(GOLDEN_RTL)/FastArbiter_50.sv
# UT 变体（impl 顶层改名 SnoopUnit_xs 以与 golden SnoopUnit 双例化）
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 SnoopUnit 顶层；FastArbiter_50 两侧 elaborate 作为共同子模块
FM_VARIANTS = SnoopUnit
FM_REF_DEPS_SnoopUnit = FastArbiter_50.sv

# bufferTimer(256)/REG(16) 为泄漏检测计时器, 仅被 `ifndef SYNTHESIS 断言读取 →
# 两侧对称 cone-dead。fm_pins.tcl 建立 golden 展平名 ↔ impl 2D 数组名的 1:1 双射,
# 配合 verify_matched_unread_compare_points=true 让 FM 实际比较证明等价(class-4 加强证明,
# 非 waiver)。SnoopUnit 须由 main 加入 fm_eq.tcl(line77)/run_signoff_target.sh(line33)
# 的 matched-unread 白名单方可运行本加强(standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden SnoopUnit 含 `ifndef SYNTHESIS 的随机初值与断言（SnoopBuf overflow /
# Snoop task repeated / SnoopBuf Leak）；UT 随机激励会触发，故定义 SYNTHESIS 关掉
# （同时关随机初值注入，使两侧寄存器复位到 0 后同构可比）。
VCS += +define+SYNTHESIS
