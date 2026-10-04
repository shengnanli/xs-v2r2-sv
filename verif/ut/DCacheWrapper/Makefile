# DCacheWrapper：L1 数据缓存 DCache 的 LazyModule 外壳（端口直通 + perf 打两拍），整份由
# scripts/gen_dcachewrapper.py 生成。child DCache 是已签核目标（verif/ut/DCache），两侧白盒：ref 读 golden
# DCache 及其子树，impl 读本仓 rtl/memblock/DCache.sv 及其子树重写件 —— 子树文件表与 DCache 的 UT/FM 完全相同
# （本文件由 verif/ut/DCache/Makefile 照抄，只改顶层名 / 多一个顶层文件 / initreg 配置多两层作用域）。
# UT 里两侧子模块同一份（重写件），比的是 DCache 本层胶水 + 外壳；tb 由 gen.py 从 DCache tb 机械改写。
# 黑盒：verif/allow/DCacheWrapper.json = DCache.json 换根（厂商叶子 array_7_ext/array_8_ext + 被消空的 StorePipe）。
# 〔以下为 verif/ut/DCache/Makefile 原注释〕DCache —— L1 数据缓存顶层（DCacheImp）：22 类子模块 + 本层胶水（D/B 通道分发、PLRU 替换、回应打拍、
# 错误上报、预取统计、性能事件）。
#
# 单文件规范：dcache_pkg + xs_DCache_core + golden 同名 wrapper 都在 rtl/memblock/DCache.sv
# （wrapper 的端口表与全部例化连线、本目录的 fm_pins_pre.tcl / tb.sv 生成区由 scripts/gen_dcache.py 生成）。
# 子模块处置（两侧白盒）：子模块全部是已签核（PROVEN_*）的重写件或两侧同源的 golden 件（PROVEN_IN_CONE），
# 放 RTL_GOLDEN_DEPS：UT 两侧（golden DCache 与派生出的 DCache_xs）例化同一份定义，只比本层胶水；
# FM 侧 ref 走 golden 闭包（FM_REF_DEPS_DCache，字面文件名），impl 走重写件。
# StorePipe ×2 / FDPrefetcherMonitor：golden 本配置下 0 输出 0 寄存器，两侧照 golden 例化，不产生比较点。
# 黑盒：只有厂商 SRAM 叶子 array_7_ext（BankedDataArray 内 32 个）/ array_8_ext（DuplicatedTagArray 内 8 个），
# 不进 FM 源（unresolved = 黑盒），逐个声明在 verif/allow/DCache.json；仿真用 golden 的行为模型。
MODULE = DCacheWrapper

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/DCacheWrapper.sv $(RTL_DIR)/memblock/DCache.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# 两侧同源的 golden 件（厂商宏外壳、时钟门控、未重写的 PROVEN_IN_CONE 叶子）
SHARED_GOLDEN = sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv array_7.sv MbistClockGateCell.sv ClockGate.sv \
                sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv array_8.sv \
                Arbiter8_MainPipeReq.sv ProbeEntry.sv WritebackEntry.sv WritebackEntry_15.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/frontend/ICacheCtrlUnit.sv \
  $(RTL_DIR)/memblock/Queue1_RegMapperInput_6.sv \
  $(RTL_DIR)/common/PipelineConnect.sv \
  $(RTL_DIR)/uncore/NewPipelineConnectPipe_27.sv \
  $(RTL_DIR)/memblock/CtrlUnit.sv \
  $(RTL_DIR)/common/xs_SRAMTemplate_core.sv \
  $(RTL_DIR)/common/SRAMTemplate_84.sv \
  $(RTL_DIR)/common/SRAMTemplate_86.sv \
  $(RTL_DIR)/common/SRAMTemplate_88.sv \
  $(RTL_DIR)/common/SRAMTemplate_92.sv \
  $(RTL_DIR)/common/SRAMTemplate_100.sv \
  $(RTL_DIR)/common/SRAMTemplate_116.sv \
  $(RTL_DIR)/memblock/DataSRAMBank.sv \
  $(RTL_DIR)/memblock/DataSRAMBank_1.sv \
  $(RTL_DIR)/memblock/DataSRAMBank_2.sv \
  $(RTL_DIR)/memblock/DataSRAMBank_4.sv \
  $(RTL_DIR)/dft/xs_mbist_pipe_core.sv \
  $(RTL_DIR)/dft/MbistPipeDCacheData.sv \
  $(RTL_DIR)/memblock/BankedDataArray.sv \
  $(RTL_DIR)/memblock/L1CohMetaArray.sv \
  $(RTL_DIR)/memblock/xs_l1_meta_array_core.sv \
  $(RTL_DIR)/memblock/L1ErrorMetaArray.sv \
  $(RTL_DIR)/memblock/L1PrefetchSourceArray.sv \
  $(RTL_DIR)/memblock/L1FlagMetaArray.sv \
  $(RTL_DIR)/memblock/TagSRAMBank.sv \
  $(RTL_DIR)/memblock/TagArray.sv \
  $(RTL_DIR)/dft/MbistPipeDcacheTag.sv \
  $(RTL_DIR)/memblock/DuplicatedTagArray.sv \
  $(RTL_DIR)/memblock/BloomFilter.sv \
  $(RTL_DIR)/memblock/CounterFilter.sv \
  $(RTL_DIR)/memblock/LoadPipe.sv \
  $(RTL_DIR)/memblock/StorePipe.sv \
  $(RTL_DIR)/memblock/MainPipe.sv \
  $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
  $(RTL_DIR)/memblock/Arbiter4_MainPipeReq.sv \
  $(RTL_DIR)/memblock/AMOALU.sv \
  $(RTL_DIR)/common/xs_TLArbiterLowest.sv \
  $(RTL_DIR)/memblock/MissQueue.sv \
  $(RTL_DIR)/memblock/Arbiter16_MainPipeReq.sv \
  $(RTL_DIR)/memblock/CMOUnit.sv \
  $(RTL_DIR)/memblock/MissEntry.sv \
  $(RTL_DIR)/memblock/ProbeQueue.sv \
  $(RTL_DIR)/memblock/WritebackQueue.sv \
  $(RTL_DIR)/memblock/Arbiter1_TagWriteReq.sv \
  $(RTL_DIR)/memblock/Arbiter1_L1BankedDataWriteReq.sv \
  $(RTL_DIR)/memblock/Arbiter1_L1BankedDataWriteReqCtrl.sv \
  $(RTL_DIR)/memblock/TreeArbiter.sv \
  $(RTL_DIR)/memblock/MissReadyGen.sv \
  $(RTL_DIR)/memblock/PrefetcherMonitor.sv \
  $(RTL_DIR)/memblock/FDPrefetcherMonitor.sv \
  $(addprefix $(GOLDEN_RTL)/,$(filter-out ClockGate.sv,$(SHARED_GOLDEN))) $(XSSV_HOME)/rtl/common/ClockGate.sv

# UT 的 golden 侧：本体 + 厂商宏的行为模型（FM 不读 *_ext.v，它们在 FM 里是黑盒）
GOLDEN_SRCS = $(GOLDEN_RTL)/DCacheWrapper.sv $(GOLDEN_RTL)/DCache.sv $(GOLDEN_RTL)/array_7_ext.v $(GOLDEN_RTL)/array_8_ext.v

FM_VARIANTS = DCacheWrapper
FM_REF_DEPS_DCacheWrapper = DCache.sv \
  AMOALU.sv Arbiter16_MainPipeReq.sv Arbiter1_L1BankedDataWriteReqCtrl.sv Arbiter1_L1BankedDataWriteReq.sv \
  Arbiter1_TagWriteReq.sv Arbiter4_MainPipeReq.sv Arbiter8_MainPipeReq.sv array_7.sv array_8.sv \
  BankedDataArray.sv BloomFilter.sv ClockGate.sv CMOUnit.sv CounterFilter.sv CtrlUnit.sv \
  DataSRAMBank_1.sv DataSRAMBank_2.sv DataSRAMBank_4.sv DataSRAMBank.sv DuplicatedTagArray.sv \
  FDPrefetcherMonitor.sv L1CohMetaArray.sv L1ErrorMetaArray.sv L1FlagMetaArray.sv L1PrefetchSourceArray.sv \
  LoadPipe.sv MainPipe.sv MbistClockGateCell.sv MbistPipeDCacheData.sv MbistPipeDcacheTag.sv MissEntry.sv \
  MissQueue.sv MissReadyGen.sv NewPipelineConnectPipe_27.sv PrefetcherMonitor.sv ProbeEntry.sv ProbeQueue.sv \
  Queue1_RegMapperInput_6.sv sram_array_1p256x72m72s1h0l1b_dcsh_dat.sv sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
  SRAMTemplate_100.sv SRAMTemplate_116.sv SRAMTemplate_84.sv SRAMTemplate_86.sv SRAMTemplate_88.sv \
  SRAMTemplate_92.sv StorePipe.sv TagArray.sv TagSRAMBank.sv TreeArbiter.sv WritebackEntry_15.sv \
  WritebackEntry.sv WritebackQueue.sv
FM_MODE = assembly

# 逐个比较，不合并重复寄存器（MainPipe / MissQueue / ProbeQueue / LoadPipe 等子模块都在 merge_dup=false 下签核；
# 2026-10-03 diagnostic 实测 merge_dup=true 时 FM 在 golden 侧合并 r_miss/r_replay、mainPipe s1_req 等重复寄存器，
# impl 侧合不上 → unmatched 50 / failing 49）。曾经的代价（共享核 xs_SRAMTemplate_core 的 rdata_last_REG 在 40 个 SRAM
# 里各成一个 impl 独有死位）已由 codex 0206 D1 在共享核里消除（holdRead 关时不生成），见 docs/lanes/sramcore-d1d2d3_prereg.md。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/DCache.tcl★ —— 子模块内的对称死寄存器位（各子模块签核时
# 已经由 vmucp 真比较过的那批）在本层继续真比较；名字不同的由 fm_pins_pre.tcl 逐项配对。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# 初值档 INITREG（编译期打开机制，运行期选档）：
#   0        +vcs+initreg+0：全设计 0，复位后全比；
#   glue     子模块 0、两侧 DCache 本层随机（种子 = SEED）；
#   glue017  同上，种子 = <SEED>017（不经 ntb 种子，seed 1 也是真随机）。
#   为什么不是全设计 +vcs+initreg+random：子模块两侧同码、各摇各的初值（SRAM 阵列内容也在内），
#   比出来的只是初值噪声（L2TLB lane 实测，CONVENTIONS「双例化 UT」），与本层重写无关。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
INITREG_CFG = $(UT_GEN_DIR)/initreg_$(INITREG)_$(SEED).cfg
ifeq ($(INITREG),0)
SIM_ARGS += +vcs+initreg+0
else ifeq ($(INITREG),glue)
SIM_ARGS += +vcs+initreg+config+$(INITREG_CFG) +glue_random
INITREG_SEED = $(SEED)
else ifeq ($(INITREG),glue017)
SIM_ARGS += +vcs+initreg+config+$(INITREG_CFG) +glue_random
INITREG_SEED = $(SEED)017
else
$(error INITREG 只认 0 / glue / glue017)
endif

run: initreg_cfg
.PHONY: initreg_cfg gencheck
initreg_cfg:
	@mkdir -p $(UT_GEN_DIR)
	@$(if $(INITREG_SEED),printf 'defaultvalue 0\ninstance tb.u_gold random $(INITREG_SEED)\ninstance tb.u_gold.dcache random $(INITREG_SEED)\ninstance tb.u_impl random $(INITREG_SEED)\ninstance tb.u_impl.dcache.u_core random $(INITREG_SEED)\n' > $(INITREG_CFG),:)

gencheck:
	python3 ../../../scripts/gen_dcachewrapper.py --check
	python3 gen.py --check
