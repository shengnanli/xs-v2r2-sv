MODULE = DataPath

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / body 互联表)。
RTL_SRCS = $(RTL_DIR)/backend/datapath_pkg.sv \
           $(RTL_DIR)/backend/datapath_cfg_pkg.sv \
           $(RTL_DIR)/backend/DataPath.sv

TB_SRCS = variants_xs.sv tb.sv

# 子模块全部作 golden 黑盒;UT 双例化两侧共用同一份 golden 定义。
SUB_DEPS = $(GOLDEN_RTL)/DelayN_1.sv \
           $(GOLDEN_RTL)/DelayReg_10.sv \
           $(GOLDEN_RTL)/DelayReg_8.sv \
           $(GOLDEN_RTL)/DummyDPICWrapper_10.sv \
           $(GOLDEN_RTL)/DummyDPICWrapper_11.sv \
           $(GOLDEN_RTL)/DummyDPICWrapper_9.sv \
           $(GOLDEN_RTL)/FpRFReadArbiter.sv \
           $(GOLDEN_RTL)/FpRFWBCollideChecker.sv \
           $(GOLDEN_RTL)/FpRegFilePart0.sv \
           $(GOLDEN_RTL)/FpRegFilePart1.sv \
           $(GOLDEN_RTL)/FpRegFilePart2.sv \
           $(GOLDEN_RTL)/FpRegFilePart3.sv \
           $(GOLDEN_RTL)/IntRFReadArbiter.sv \
           $(GOLDEN_RTL)/IntRFWBCollideChecker.sv \
           $(GOLDEN_RTL)/IntRegFilePart0.sv \
           $(GOLDEN_RTL)/IntRegFilePart1.sv \
           $(GOLDEN_RTL)/IntRegFilePart2.sv \
           $(GOLDEN_RTL)/IntRegFilePart3.sv \
           $(GOLDEN_RTL)/RegCache.sv \
           $(GOLDEN_RTL)/UIntExtractor_27_000000000000001010100000000.sv \
           $(GOLDEN_RTL)/UIntExtractor_27_000011100000000000001010101.sv \
           $(GOLDEN_RTL)/V0RFReadArbiter.sv \
           $(GOLDEN_RTL)/V0RFWBCollideChecker.sv \
           $(GOLDEN_RTL)/V0RegFilePart0.sv \
           $(GOLDEN_RTL)/V0RegFilePart1.sv \
           $(GOLDEN_RTL)/VfRFReadArbiter.sv \
           $(GOLDEN_RTL)/VfRFWBCollideChecker.sv \
           $(GOLDEN_RTL)/VfRegFilePart0.sv \
           $(GOLDEN_RTL)/VfRegFilePart1.sv \
           $(GOLDEN_RTL)/VfRegFilePart2.sv \
           $(GOLDEN_RTL)/VfRegFilePart3.sv \
           $(GOLDEN_RTL)/VlRFReadArbiter.sv \
           $(GOLDEN_RTL)/VlRFWBCollideChecker.sv \
           $(GOLDEN_RTL)/VlRegFile.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DataPath.sv $(SUB_DEPS)

# FM:impl 侧(包装层→可读核)必须与 ref 侧在「相同层次」黑盒化子模块,否则两侧黑盒
# 暴露的引脚数不一致(ref 侧给了子模块定义会下钻到更深叶子,impl 侧没有则止于例化),
# 产生大量 unmatched BBPin 并污染下游比对。故 WRAPPER_SRCS 也带上同一批子模块 golden
# 定义(其内部更深的叶子 array/arbiter 在两侧都按 hdlin_unresolved_modules black_box
# 处理,一致即可)。
WRAPPER_SRCS = $(RTL_DIR)/backend/DataPath_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = DataPath
FM_REF_DEPS_DataPath = DelayN_1.sv DelayReg_10.sv DelayReg_8.sv DummyDPICWrapper_10.sv DummyDPICWrapper_11.sv DummyDPICWrapper_9.sv FpRFReadArbiter.sv FpRFWBCollideChecker.sv FpRegFilePart0.sv FpRegFilePart1.sv FpRegFilePart2.sv FpRegFilePart3.sv IntRFReadArbiter.sv IntRFWBCollideChecker.sv IntRegFilePart0.sv IntRegFilePart1.sv IntRegFilePart2.sv IntRegFilePart3.sv RegCache.sv UIntExtractor_27_000000000000001010100000000.sv UIntExtractor_27_000011100000000000001010101.sv V0RFReadArbiter.sv V0RFWBCollideChecker.sv V0RegFilePart0.sv V0RegFilePart1.sv VfRFReadArbiter.sv VfRFWBCollideChecker.sv VfRegFilePart0.sv VfRegFilePart1.sv VfRegFilePart2.sv VfRegFilePart3.sv VlRFReadArbiter.sv VlRFWBCollideChecker.sv VlRegFile.sv

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# 各黑盒子模块(RegFile 分片/读口仲裁器/写口冲突检查器/RegCache/difftest 探针)还会
# 例化更深的 golden 叶子(WBArbiter*/RealWBArbiter*/DiffExtArch*RegState 等)。用 -y
# 库目录按文件名自动解析这些传递依赖(.sv 与 difftest 探针 .v),省去手工枚举。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
# golden 黑盒(RegCache 的 RegCacheDataModule 等)内含非综合 SVA 读地址范围断言,不受
# SYNTHESIS 控制;随机激励驱动越界读地址会在两侧(u_g/u_i)对称触发,只是刷屏拖慢仿真,
# 不影响逐拍输出比对。关掉 SVA 触发让仿真干净高速。
VCS += -assert disable
