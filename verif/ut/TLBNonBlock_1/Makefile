MODULE = TLBNonBlock_1
RTL_DIR = ../../../rtl
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 xs_TLBNonBlock_1_core (store TLB, Width=2/nRespDups=1) + pkg。
# ---- child 闭包合规重做(codex_0079)----
# 内层存储/PLRU/延迟子模块是**实质逻辑**(非 vendor SRAM 宏), 无独立 305/AUX PASS,
# 故不可整体黑盒。改为**两侧真实 elaborate**(golden .sv 同进 ref+impl 侧, golden==golden
# 对称白盒受验), 与 MemExeUnit/VSegmentUnit 的两侧 elaborate 法一致:
#   DelayN_7 / DelayN_9  纯延迟链 leaf(无子模块)
#   TlbStorageWrapper_2  存储/PLRU 包装 → 唯一子 TLBFA_2(全关联 TLB, leaf 无子模块)
# 这些子模块无厂商宏(无 array_ext / ram_ / SRAM 宏), 全 register-based, 可完全 elaborate。
# 原黑盒清单里的 TLBFA(base) 是**多余**(TLBFA_2 不例化 TLBFA), 删除。
GOLDEN_SUBS = $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_9.sv \
              $(GOLDEN_RTL)/TlbStorageWrapper_2.sv $(GOLDEN_RTL)/TLBFA_2.sv
RTL_SRCS = $(RTL_DIR)/memblock/tlbnonblock1_pkg.sv \
           $(RTL_DIR)/memblock/TLBNonBlock_1.sv
# WRAPPER_SRCS(仅 FM impl 侧, 不进 UT 编译): 扁平端口包装 + 同一批 golden 子模块(impl 侧同
# elaborate, 两侧层次对称 → hdlin 自动同名配对, 内部逻辑真受验, 非黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBNonBlock_1_wrapper.sv $(GOLDEN_SUBS)
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock_1.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TLBNonBlock_1
# FM ref 侧依赖: 顶层 + 4 golden 子模块两侧 elaborate 作为共同定义(非黑盒)。
FM_REF_DEPS_TLBNonBlock_1 = DelayN_7.sv DelayN_9.sv TlbStorageWrapper_2.sv TLBFA_2.sv
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden TLBFA_2 含 xs_assert_v2 断言(`ifndef SYNTHESIS), UT/FM 两侧同关掉。
VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + golden 子模块 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(GOLDEN_SUBS) $(GOLDEN_RTL)/TLBNonBlock_1.sv $(TB_SRCS) -top tb -o simv
