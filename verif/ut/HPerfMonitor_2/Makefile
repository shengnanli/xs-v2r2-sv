MODULE = HPerfMonitor_2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# HPerfMonitor_2 (HPM 事件路由 + 例化 8×HPerfCounter_13)。子模块 HPerfCounter_13
# 两侧白盒 elaborate(非黑盒)。可读转写 + eventSelTable 改名。
#
# UT 双例化: golden HPerfMonitor_2/HPerfCounter_13 (GOLDEN_SRCS) vs 可读核的 _xs 变体
# (variants_xs.sv, 自包含 HPerfMonitor_2_xs + HPerfCounter_13_xs)。为避免与 golden 同名
# 模块在 UT 编译期撞名, 可读核 golden-名版本 newcsr_hperfmon.sv 只进 FM impl 侧
# (WRAPPER_SRCS), 不进 UT 编译(RTL_SRCS 留空)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_hperfmon.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/HPerfMonitor_2.sv $(GOLDEN_RTL)/HPerfCounter_13.sv
TB_SRCS      = variants_xs.sv tb.sv

# HPerfCounter_13 是 golden 侧的依赖(ref)+ WRAPPER_SRCS 的 newcsr_hperfmon.sv 含
# impl 侧同名转写。两侧共同 elaborate 该子模块(非黑盒)。
FM_REF_DEPS_HPerfMonitor_2 = HPerfCounter_13.sv

FM_VARIANTS = HPerfMonitor_2

# 64 对称 matched-unread DFF = 8×HPerfCounter_13 内的 event_op_2_reg 高 2 位([3][4],
# 5 位寄存器但只读 [0:2] 做算子选择, [3:4] cone-dead) × 4 = 32, 外加各 counter 输出级
# staging 寄存器的死高位。两侧完美同名双射(ref==impl 逐位), 值恒相等。设 vmucp=true 让
# FM 实际比较这些点(class-4 加强证明, 非 waiver)证等价。须 main 把 HPerfMonitor_2 加入
# fm_eq.tcl(L77) + run_signoff_target.sh(L34) 的 matched-unread 白名单方可运行(standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
