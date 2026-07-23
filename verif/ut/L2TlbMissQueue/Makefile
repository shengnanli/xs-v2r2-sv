MODULE = L2TlbMissQueue
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l2tlbmissqueue_pkg.sv $(RTL_DIR)/memblock/L2TlbMissQueue.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv $(GOLDEN_RTL)/ram_40x47.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L2TlbMissQueue
# ram_40x47 是 golden 的 40深×47位 厂商 RAM 叶子：其组合读 Memory[R0_addr]（6 位地址
# 寻址 40 深数组，指针可证 ≤39 但 FM 静态无法证明）会抛 FMR_ELAB-147 并在 link 阶段
# 升级为 unsuppressed error，令 golden set_top 失败、整个 SEC 中止。手写核 L2TlbMissQueue.sv
# 现改为实例化同名同端口的 ram_40x47 作存储叶子，故双侧都**不**把 ram_40x47.sv 交给 FM，
# 经 hdlin_unresolved_modules=black_box 成为对称匹配黑盒（RAM 阵列不 elaborate → 无
# ELAB-147；厂商 RAM 叶子方法学，同 array_ext），环形指针/满空/flush 控制逻辑照常比对。
# ram_40x47.sv 仍在 GOLDEN_SRCS 中供 UT 仿真按模块名解析（golden 与 impl 两处例化共用）。
FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv
