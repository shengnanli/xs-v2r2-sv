# 自动生成：scripts/gen_debugmodule.py —— 勿手改
MODULE = DebugModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + pkg。两大子块 (TLDebugModule / DebugTransportModuleJTAG) 不在此:
#   UT 经 golden_filelist.f 编入真实子块 (两侧共用);
#   FM 两侧都黑盒 (不进 FM_IMPL_SRCS / FM_REF_DEPS)。
RTL_SRCS = $(RTL_DIR)/uncore/debug_pkg.sv \
           $(RTL_DIR)/uncore/DebugModule.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden 顶层 (子块依赖闭包见 golden_filelist.f)。
GOLDEN_SRCS = $(GOLDEN_RTL)/DebugModule.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/DebugModule_wrapper.sv
FM_VARIANTS = DebugModule
# FM: TLDebugModule / DebugTransportModuleJTAG 不提供给任一侧 ⇒
#     hdlin_unresolved_modules=black_box 在 ref/impl 两侧黑盒化,
#     比对聚焦 DebugModule 自身同步寄存器 + DMI/总线连线。
# (FM_REF_DEPS_DebugModule 留空, ref 侧只读 DebugModule.sv)

include ../../../scripts/ut_common.mk

# golden 子块含非综合断言/firtool 随机初始化; UT 关随机化并按 initreg+0 初始化,
# 双时钟域 + 异步跨域队列在两实例间确定性演化。
VCS += +define+SYNTHESIS
VCS += +vcs+initreg+random
VCS += -assert disable
VCS += +libext+.sv+.v
VCS += -f golden_filelist.f
SIM_ARGS += +vcs+initreg+0
