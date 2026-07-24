MODULE = WbDataPath

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核: 类型包 + 核。
RTL_SRCS = $(RTL_DIR)/backend/wbdatapath_pkg.sv \
           $(RTL_DIR)/backend/WbDataPath.sv

# UT 用 _xs 镜像 wrapper, 与 golden 双例化逐拍比对。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 WbDataPath + 其影响输出的真子模块(VldMergeUnit / RealWBCollideChecker /
# RealWBArbiter 及其叶子)。DummyDPICWrapper(纯 sink, difftest 探针)在 UT 用本地空体
# stub(gen_wbdatapath.py 由 golden 模块头生成)供两个 DUT 共同链接。
WB_DEPS = ByteMaskTailGen.sv MaskExtractor.sv UIntToContLow0s.sv UIntToContLow1s.sv \
          VldMgu.sv VldMergeUnit.sv \
          RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv \
          RealWBArbiter_14.sv RealWBArbiter_15.sv RealWBArbiter_20.sv RealWBArbiter_21.sv \
          RealWBArbiter_26.sv \
          RealWBCollideChecker.sv RealWBCollideChecker_1.sv RealWBCollideChecker_2.sv \
          RealWBCollideChecker_3.sv RealWBCollideChecker_4.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/WbDataPath.sv $(addprefix $(GOLDEN_RTL)/,$(WB_DEPS)) \
              $(RTL_DIR)/backend/WbDataPath_dpic_stub.sv

# FM: golden 顶层 WbDataPath vs 手写同名 wrapper(→ 可读核)。
# 子模块(VldMergeUnit/RealWBCollideChecker/RealWBArbiter 及叶子)为真逻辑, 两侧读同一份
# golden 文件(共享, 非黑盒)以使 ready 锥可判。DummyDPICWrapper(纯 sink, 仅输入)FM
# 两侧都**不读 stub** → hdlin_unresolved_modules=black_box 对称黑盒, 26 实例引脚按名
# 配对(verification_verify_matched_unread_bbox_inputs=true 实证两侧探针输入恒等)。
WRAPPER_SRCS = $(RTL_DIR)/backend/WbDataPath_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(WB_DEPS))
FM_VARIANTS = WbDataPath
FM_REF_DEPS_WbDataPath = $(WB_DEPS)

include ../../../scripts/ut_common.mk

# golden 子模块有 SYNTHESIS-gated 断言; 关 SYNTHESIS 以与可读核(无断言/随机)对齐。
VCS += +define+SYNTHESIS
