MODULE = PTWNewFilter
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核(顶层 glue: ptwResp/last_REG/hint 寄存 bank + resp/hint/rob 路由)。三组过滤器
# (PTWFilterEntry / PTWFilterEntry_1 ×2) + 仲裁器(RRArbiterInit_10) + DelayN_1(flush)
# 两侧同源 elaborate(纯逻辑非黑盒), impl 侧随核一起编。
DEPS = $(GOLDEN_RTL)/PTWFilterEntry.sv $(GOLDEN_RTL)/PTWFilterEntry_1.sv \
       $(GOLDEN_RTL)/RRArbiterInit_10.sv $(GOLDEN_RTL)/DelayN_1.sv
RTL_SRCS = $(RTL_DIR)/memblock/PTWNewFilter.sv $(DEPS)
WRAPPER_SRCS = $(RTL_DIR)/memblock/PTWNewFilter_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PTWNewFilter.sv $(DEPS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = PTWNewFilter
# 4 子模块两侧 elaborate(ref 侧作依赖): golden==golden 对称白盒, 非黑盒复用。
FM_REF_DEPS_PTWNewFilter = PTWFilterEntry.sv PTWFilterEntry_1.sv RRArbiterInit_10.sv DelayN_1.sv

# 10 对称 matched-unread = 三组 golden 过滤器内 inflight_counter_reg[*](load ×4/store ×3/
# prefetch ×3): 该计数器仅被 golden inflight_counter_probe(_probe 无输出端口)读 → cone-dead。
# 三组过滤器两侧同源 elaborate(byte-identical golden), 故 ref↔impl 同名双射完美对称。
# FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM 实际比较这 10 点(非 waiver, 证等价)
# → 2012→2024passing/0unread clean SUCCEEDED(evidence fm_vmucp_SUCCEEDED.log)。
# 须 main 把 PTWNewFilter 加入 fm_eq.tcl+run_signoff_target.sh vmucp 白名单(同 Prefetcher/
# PrefetchQueue standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + 4 子模块 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_DIR)/memblock/PTWNewFilter.sv $(DEPS) $(GOLDEN_RTL)/PTWNewFilter.sv $(TB_SRCS) -top tb -o simv
