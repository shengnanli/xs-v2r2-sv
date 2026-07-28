MODULE = DataPath

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口表 / body 互联表)。
RTL_SRCS = $(RTL_DIR)/backend/datapath_pkg.sv \
           $(RTL_DIR)/backend/datapath_cfg_pkg.sv \
           $(RTL_DIR)/backend/DataPath.sv

TB_SRCS = variants_xs.sv tb.sv

# 子模块两侧共用同一份 golden 定义(UT 双例化 + FM 两侧对称白盒 elaborate)。
# RegCache 内部叶子(RegCacheDataModule/AgeTimer/AgeDetector ×2)与各 RFReadArbiter/
# RFWBCollideChecker 内部 WBArbiter* 叶子**显式两侧 elaborate**(不再靠 hdlin_unresolved
# 黑盒):否则 golden DataPath 侧 RegCache 被 merge_duplicated_registers 二次 uniquify 成
# RegCache_2_2、impl 侧只 RegCache_2 → unresolved_blackbox_ref/impl=93/87 非对称拓扑,
# assembly validator(unresolved_bb 观察集须==allow policy 投影)判 PARTIAL。两侧同源
# golden 叶子对称受验后,唯一残留黑盒 = 3 个 DiffExtArch*RegState DPI sink(.v, SYNTHESIS
# 下体被裁全输入引脚 → empty_blackbox,见 allow/DataPath.json)。
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
           $(GOLDEN_RTL)/RegCacheDataModule.sv \
           $(GOLDEN_RTL)/RegCacheDataModule_1.sv \
           $(GOLDEN_RTL)/RegCacheAgeTimer.sv \
           $(GOLDEN_RTL)/RegCacheAgeTimer_1.sv \
           $(GOLDEN_RTL)/RegCacheAgeDetector.sv \
           $(GOLDEN_RTL)/RegCacheAgeDetector_1.sv \
           $(GOLDEN_RTL)/WBArbiter.sv \
           $(GOLDEN_RTL)/WBArbiter_1.sv \
           $(GOLDEN_RTL)/WBArbiter_2.sv \
           $(GOLDEN_RTL)/WBArbiter_3.sv \
           $(GOLDEN_RTL)/WBArbiter_30.sv \
           $(GOLDEN_RTL)/WBArbiter_33.sv \
           $(GOLDEN_RTL)/WBArbiter_38.sv \
           $(GOLDEN_RTL)/WBArbiter_52.sv \
           $(GOLDEN_RTL)/WBArbiter_55.sv \
           $(GOLDEN_RTL)/WBArbiter_58.sv \
           $(GOLDEN_RTL)/WBArbiter_64.sv \
           $(GOLDEN_RTL)/WBArbiter_65.sv \
           $(GOLDEN_RTL)/WBArbiter_66.sv \
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

# FM:impl 侧(包装层→可读核)与 ref 侧共用同一批 golden 子模块定义(SUB_DEPS),两侧
# 在相同层次对称 elaborate 到叶子(RegFile 分片/RFReadArbiter/RFWBCollideChecker/RegCache
# + 其内部 WBArbiter*/RegCacheDataModule/AgeTimer/AgeDetector 叶子)。两侧同源 golden ⇒
# 叶子内部逐位恒等,只增 passing、不产非对称 unresolved。唯一黑盒 = 3 DPI sink。
WRAPPER_SRCS = $(RTL_DIR)/backend/DataPath_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = DataPath
FM_REF_DEPS_DataPath = DelayN_1.sv DelayReg_10.sv DelayReg_8.sv DummyDPICWrapper_10.sv DummyDPICWrapper_11.sv DummyDPICWrapper_9.sv FpRFReadArbiter.sv FpRFWBCollideChecker.sv FpRegFilePart0.sv FpRegFilePart1.sv FpRegFilePart2.sv FpRegFilePart3.sv IntRFReadArbiter.sv IntRFWBCollideChecker.sv IntRegFilePart0.sv IntRegFilePart1.sv IntRegFilePart2.sv IntRegFilePart3.sv RegCache.sv RegCacheDataModule.sv RegCacheDataModule_1.sv RegCacheAgeTimer.sv RegCacheAgeTimer_1.sv RegCacheAgeDetector.sv RegCacheAgeDetector_1.sv WBArbiter.sv WBArbiter_1.sv WBArbiter_2.sv WBArbiter_3.sv WBArbiter_30.sv WBArbiter_33.sv WBArbiter_38.sv WBArbiter_52.sv WBArbiter_55.sv WBArbiter_58.sv WBArbiter_64.sv WBArbiter_65.sv WBArbiter_66.sv UIntExtractor_27_000000000000001010100000000.sv UIntExtractor_27_000011100000000000001010101.sv V0RFReadArbiter.sv V0RFWBCollideChecker.sv V0RegFilePart0.sv V0RegFilePart1.sv VfRFReadArbiter.sv VfRFWBCollideChecker.sv VfRegFilePart0.sv VfRegFilePart1.sv VfRegFilePart2.sv VfRegFilePart3.sv VlRFReadArbiter.sv VlRFWBCollideChecker.sv VlRegFile.sv

# (FM 审计 2026-07)曾试 FM_MERGE_DUP=false(Bku 同法)修 difftest delayer 的
# DFF vs DFF0X 类失配 —— 实测**不可行**:golden DataPath 顶层有约 26 份
# s1_flush_next_* 使能变体扇出副本与 regfile 写口扇出副本,关合并后它们无法与
# 手写核的单份寄存器配对(287 bit unmatched → vfRegFilePart1/3 全 mem 失配传染),
# 比开合并更糟。保持默认合并;delayer 类失配另行定性(见 fm_work AUDIT_NOTES)。

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉以免触发,并关随机化。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# WBArbiter*/RegCacheDataModule 等更深叶子已在 SUB_DEPS 显式列出;-y 库目录再兜底解析
# difftest 探针 .v(DiffExtArch*RegState)与任何遗漏传递依赖(与显式文件重名时 VCS 优先
# 显式定义,不冲突)。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
# golden 黑盒(RegCache 的 RegCacheDataModule 等)内含非综合 SVA 读地址范围断言,不受
# SYNTHESIS 控制;随机激励驱动越界读地址会在两侧(u_g/u_i)对称触发,只是刷屏拖慢仿真,
# 不影响逐拍输出比对。关掉 SVA 触发让仿真干净高速。
VCS += -assert disable
