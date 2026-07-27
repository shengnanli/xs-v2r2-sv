MODULE = PrefetchQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= /home/eda/xs-env/G0-canonical/golden-rtl

# 手写可读核 xs_PrefetchQueue_core(自包含 32 深环形 FIFO, 无子模块)。
RTL_SRCS = $(RTL_DIR)/l2/PrefetchQueue.sv
# FM impl 侧: golden 同名扁平端口包装(不进 UT 编译)。
WRAPPER_SRCS = $(RTL_DIR)/l2/PrefetchQueue_wrapper.sv
# golden 顶层(叶子, 无子模块依赖)。
GOLDEN_SRCS = $(GOLDEN_RTL)/PrefetchQueue.sv
# UT 变体: impl 顶层改名 PrefetchQueue_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 signoff-strict; 无子模块无黑盒。golden _GEN_5.._14 性能统计组合线
# 无输出端口消费 → firtool 死码消除, 本核不复刻(逐位等价无观测差异)。
FM_VARIANTS = PrefetchQueue

# 31 对称 matched-unread = valids_0..30_reg: 32 深环形 FIFO 的 valid 位, 仅 valids_31
# 被 empty_probe/full_probe 读(head==tail 时判空/满), 其余 30 位加上被 _GEN_14(死码
# popcount) 唯一消费者 → cone-dead。golden 保留全 32 位, 本核逐位忠实复刻 → ref↔impl
# 同名双射(auto_match_flattened_arrays 按名自动配对)。FM_VERIFY_MATCHED_UNREAD=true
# 让 FM 实际比较这 31 点(非 waiver, 证等价), 得 0 unread clean SUCCEEDED。
# 须 main 把 PrefetchQueue 加入 fm_eq.tcl+run_signoff_target.sh 白名单(已加)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
