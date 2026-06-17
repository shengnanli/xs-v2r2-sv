MODULE = BypassNetwork

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / body 互联表)。
RTL_SRCS = $(RTL_DIR)/backend/bypassnetwork_pkg.sv \
           $(RTL_DIR)/backend/BypassNetwork.sv

TB_SRCS = variants_xs.sv tb.sv

# ImmExtractor(立即数扩展)各变体作黑盒;UT 双例化两侧共用同一份 golden 定义。
IMM_DEPS = ImmExtractor.sv ImmExtractor_2.sv ImmExtractor_12.sv \
           ImmExtractor_37.sv ImmExtractor_57.sv

# UIntExtractor 仅 golden 顶层用(把 exuSources one-hot 散布到 27 位全局空间);
# 可读核已把这一步还原成「按序号索引」,故不实例化。仅供 golden 侧(u_g / FM ref)。
UINT_DEPS = UIntExtractor_27_000000000000001010100000000.sv \
            UIntExtractor_27_000011100000000000001010101.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/BypassNetwork.sv \
              $(addprefix $(GOLDEN_RTL)/,$(IMM_DEPS) $(UINT_DEPS))

# FM:golden 顶层 BypassNetwork vs 手写同名 wrapper(→ 可读核)。ImmExtractor 两侧共享;
# UIntExtractor 仅 ref(golden)侧依赖。
WRAPPER_SRCS = $(RTL_DIR)/backend/BypassNetwork_wrapper.sv $(addprefix $(GOLDEN_RTL)/,$(IMM_DEPS))
FM_VARIANTS = BypassNetwork
FM_REF_DEPS_BypassNetwork = $(IMM_DEPS) $(UINT_DEPS)

include ../../../scripts/ut_common.mk

# golden 内可能含非综合断言;UT 关掉以免随机激励触发 $fatal,并关随机化。
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/backend 下的 .svh(端口表 / body 互联表)
VCS += +incdir+$(RTL_DIR)/backend
