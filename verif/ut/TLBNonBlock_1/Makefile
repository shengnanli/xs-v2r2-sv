MODULE = TLBNonBlock_1
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 xs_TLBNonBlock_1_core (store TLB, Width=2/nRespDups=1) + pkg。
# 内层存储/PLRU/延迟用 golden 黑盒(UT 与 golden 共用同一份): DelayN_7/9 + TlbStorageWrapper_2
# (+ 其内层 TLBFA_2)。FM 侧两侧同名 unresolved 黑盒(hdlin_unresolved_modules=black_box)。
RTL_SRCS = $(RTL_DIR)/memblock/tlbnonblock1_pkg.sv \
           $(RTL_DIR)/memblock/TLBNonBlock_1.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBNonBlock_1_wrapper.sv
BLACKBOX = $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_9.sv \
           $(GOLDEN_RTL)/TlbStorageWrapper_2.sv $(GOLDEN_RTL)/TLBFA_2.sv $(GOLDEN_RTL)/TLBFA.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock_1.sv $(BLACKBOX)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TLBNonBlock_1
# 黑盒两侧同名对称(不给任一侧源码), 同 base TLBNonBlock 法。
FM_REF_DEPS_TLBNonBlock_1 =
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden TLBFA_2 含 xs_assert_v2 断言(`ifndef SYNTHESIS), UT 关掉。
VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + 黑盒 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(BLACKBOX) $(GOLDEN_RTL)/TLBNonBlock_1.sv $(TB_SRCS) -top tb -o simv
