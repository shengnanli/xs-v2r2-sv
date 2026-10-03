# DCache —— L1 数据缓存顶层（DCacheImp）：22 类子模块 + 本层胶水（D/B 通道分发、PLRU 替换、回应打拍、
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
MODULE = DCache

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/DCache.sv
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
  $(addprefix $(GOLDEN_RTL)/,$(SHARED_GOLDEN))

# UT 的 golden 侧：本体 + 厂商宏的行为模型（FM 不读 *_ext.v，它们在 FM 里是黑盒）
GOLDEN_SRCS = $(GOLDEN_RTL)/DCache.sv $(GOLDEN_RTL)/array_7_ext.v $(GOLDEN_RTL)/array_8_ext.v

FM_VARIANTS = DCache
FM_REF_DEPS_DCache = \
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

# merge_duplicated_registers 用工具默认（true，与 BankedDataArray / DuplicatedTagArray 子模块签核时一致）。
# 为什么不关：共享核 xs_SRAMTemplate_core 在 holdRead 关闭时 rdata_last_REG 与 respReg 同方程，
# 子模块签核时靠 merge 把它们合成一个点；关掉 merge 后每个 SRAM 多出一个 impl 独有的死寄存器
# （2026-10-02 diagnostic 实测：bankedDataArray 32 + tagArray 8 个 impl-only unread），strict/assembly 口径不收。
# 代价：fm_predict 的 passing 模型从精确等式退成「带上界的弱结论」（见 docs/fm_predictions/DCache.json）。

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
	@$(if $(INITREG_SEED),printf 'defaultvalue 0\ninstance tb.u_gold random $(INITREG_SEED)\ninstance tb.u_impl.u_core random $(INITREG_SEED)\n' > $(INITREG_CFG),:)

gencheck:
	python3 ../../../scripts/gen_dcache.py --check
