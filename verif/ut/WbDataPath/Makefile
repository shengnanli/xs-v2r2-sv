MODULE = WbDataPath

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核: 类型包 + 核 + difftest 探针黑盒 stub。
RTL_SRCS = $(RTL_DIR)/backend/wbdatapath_pkg.sv \
           $(RTL_DIR)/backend/WbDataPath.sv \
           $(RTL_DIR)/backend/WbDataPath_dpic_stub.sv

# UT 用 _xs 镜像 wrapper, 与 golden 双例化逐拍比对。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 WbDataPath + 其影响输出的真子模块(VldMergeUnit / RealWBCollideChecker /
# RealWBArbiter 及其叶子)。DummyDPICWrapper(纯 sink, difftest 探针)用本地 stub 黑盒。
WB_DEPS = ByteMaskTailGen.sv MaskExtractor.sv UIntToContLow0s.sv UIntToContLow1s.sv \
          VldMgu.sv VldMergeUnit.sv \
          RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv \
          RealWBArbiter_14.sv RealWBArbiter_15.sv RealWBArbiter_20.sv RealWBArbiter_21.sv \
          RealWBArbiter_26.sv \
          RealWBCollideChecker.sv RealWBCollideChecker_1.sv RealWBCollideChecker_2.sv \
          RealWBCollideChecker_3.sv RealWBCollideChecker_4.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/WbDataPath.sv $(addprefix $(GOLDEN_RTL)/,$(WB_DEPS))

# FM: golden 顶层 WbDataPath vs 手写同名 wrapper(→ 可读核)。
# 子模块(VldMergeUnit/RealWBCollideChecker/RealWBArbiter 及叶子)为真逻辑, 两侧读同一份
# golden 文件(共享, 非黑盒)以使 ready 锥可判; DummyDPICWrapper(纯 sink)两侧读同一 stub
# (已在 RTL_SRCS 内供 impl; 经 FM_REF_DEPS 经 GOLDEN 路径? 不——stub 在 rtl, 故下方
# 把 golden 子模块 + stub 同时加到 impl 侧 WRAPPER_SRCS, REF 侧用 FM_REF_DEPS+本地 stub)。
WRAPPER_SRCS = $(RTL_DIR)/backend/WbDataPath_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(WB_DEPS)) \
               $(RTL_DIR)/backend/WbDataPath_dpic_stub.sv
FM_VARIANTS = WbDataPath
# REF 侧读同一批真子模块; DummyDPICWrapper(纯 sink, 仅输入)在 ref 侧自动黑盒无害。
FM_REF_DEPS_WbDataPath = $(WB_DEPS)

include ../../../scripts/ut_common.mk

# golden 子模块有 SYNTHESIS-gated 断言; 关 SYNTHESIS 以与可读核(无断言/随机)对齐。
VCS += +define+SYNTHESIS
