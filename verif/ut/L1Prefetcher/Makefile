MODULE = L1Prefetcher
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 xs_L1Prefetcher_core = 纯组合装配 glue(训练门控/req 二选一/输出门控)。
# 5 子预取器 + MutiLevelPrefetchFilter 内嵌 4 RRArbiterInit 两侧同源 elaborate
# (纯逻辑非黑盒), impl 侧随核一起编。
DEPS = $(GOLDEN_RTL)/TrainFilter.sv $(GOLDEN_RTL)/TrainFilter_1.sv \
       $(GOLDEN_RTL)/StrideMetaArray.sv $(GOLDEN_RTL)/StreamBitVectorArray.sv \
       $(GOLDEN_RTL)/MutiLevelPrefetchFilter.sv \
       $(GOLDEN_RTL)/RRArbiterInit_4.sv $(GOLDEN_RTL)/RRArbiterInit_5.sv \
       $(GOLDEN_RTL)/RRArbiterInit_6.sv $(GOLDEN_RTL)/RRArbiterInit_7.sv
RTL_SRCS = $(RTL_DIR)/memblock/L1Prefetcher.sv $(DEPS)
WRAPPER_SRCS = $(RTL_DIR)/memblock/L1Prefetcher_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L1Prefetcher.sv $(DEPS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = L1Prefetcher
# 9 子模块两侧 elaborate(ref 侧作依赖): golden==golden 对称白盒, 非黑盒复用。
FM_REF_DEPS_L1Prefetcher = TrainFilter.sv TrainFilter_1.sv StrideMetaArray.sv \
       StreamBitVectorArray.sv MutiLevelPrefetchFilter.sv \
       RRArbiterInit_4.sv RRArbiterInit_5.sv RRArbiterInit_6.sv RRArbiterInit_7.sv

# 889 对称 matched-unread(fresh elaborate 1011)全部在 5 个两侧同源 elaborate 的 golden
# 子预取器内部(pf_queue_filter/stream_bit_vec_array/stream_train_filter/stride_meta_array/
# stride_train_filter 的 cone-dead perf/probe 寄存器), 我方 glue 核 u_core 内 0 unread。
# 子模块两侧 byte-identical golden → ref↔impl 同名双射完美对称。
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM 实际比较这些点(非 waiver)→
# 7664→9055passing/0unread(60 constant-reg Not-Compared 良性)clean SUCCEEDED
# (evidence fm_vmucp_SUCCEEDED.log)。须 main 加 L1Prefetcher 入 vmucp 白名单(同 Prefetcher
# standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + 9 子模块 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_DIR)/memblock/L1Prefetcher.sv $(DEPS) $(GOLDEN_RTL)/L1Prefetcher.sv $(TB_SRCS) -top tb -o simv
