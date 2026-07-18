MODULE = TLBNonBlock
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
# 可读核 + pkg；内层存储/PLRU 用 golden 黑盒（UT 与 golden 共用同一份）
RTL_SRCS = $(RTL_DIR)/memblock/tlbnonblock_pkg.sv \
           $(RTL_DIR)/memblock/tlbstoragewrapper_pkg.sv \
           $(RTL_DIR)/memblock/tlbfa_pkg.sv \
           $(RTL_DIR)/memblock/TLBNonBlock.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBNonBlock_wrapper.sv
# 黑盒子模块（两侧共用）：DelayN_7/9 + TlbStorageWrapper_1 + 其内层 TLBFA_1
BLACKBOX = $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_9.sv \
           $(GOLDEN_RTL)/TlbStorageWrapper_1.sv $(GOLDEN_RTL)/TLBFA_1.sv $(GOLDEN_RTL)/TLBFA.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock.sv $(BLACKBOX)
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = TLBNonBlock
# FM 审计 2026-07：deps 若只给 ref 侧会白盒展开（impl 侧 unresolved 黑盒），两侧层次
# 不对称 → 数千 unmatched 传染。改为两侧同黑盒（hdlin_unresolved_modules=black_box
# 自动配对同名实例），与 IMSIC/SNXbar 的黑盒 FM 法一致。UT 仍用 BLACKBOX 文件仿真。
FM_REF_DEPS_TLBNonBlock =
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# 新基线 golden(xs-clean) 的 TLBFA_1 含 xs_assert_v2 断言（`ifndef SYNTHESIS），UT 关掉。
VCS += +define+SYNTHESIS

# UT 编译：核 + _xs(variants) + 黑盒 + golden 顶 + tb（不编 golden 同名 wrapper，避免重名）
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(BLACKBOX) $(GOLDEN_RTL)/TLBNonBlock.sv $(TB_SRCS) -top tb -o simv
