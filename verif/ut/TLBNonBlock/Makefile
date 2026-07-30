MODULE = TLBNonBlock
RTL_DIR = ../../../rtl
# UT/FM 用与官方 signoff runner 相同的冻结 canonical golden（G0）。仓库内 golden/chisel-rtl
#   是新一版（243 端口、含 DummyDPICWrapper_9 difftest 探针），与本 tb 的 236 端口连接及
#   canonical golden 不一致；tb.u_g 只驱 236 端口子集，故 UT 必须编 canonical golden 才能一致。
GOLDEN_RTL = /home/eda/xs-env/G0-canonical/golden-rtl

# 可读核 xs_TLBNonBlock_core (ptw TLB, Width=3/nRespDups=1) + pkg。
# ---- child 闭包合规 current dead_ref/policy(codex_0092 §2, 为 305 主目标独立配置)----
# 内层存储/PLRU/延迟子模块是**实质逻辑**(非 vendor SRAM 宏), DelayN_7/DelayN_9 非独立
# 305/AUX target, 故不可整体黑盒(assembly-黑盒违契约)。改为**两侧真实 elaborate**
# (golden .sv 同进 ref+impl 侧, golden==golden 对称白盒受验), 与 TLBNonBlock_1/_2 及
# MemExeUnit/VSegmentUnit 的两侧 elaborate 法一致:
#   DelayN_7 / DelayN_9  纯延迟链 leaf(无子模块)
#   TlbStorageWrapper_1  存储/PLRU 包装 → 唯一子 TLBFA_1(全关联 TLB, leaf 无子模块)
# 这些子模块无厂商宏(无 array_ext / ram_ / SRAM 宏), 全 register-based, 可完全 elaborate。
# TLBFA(base) 是**多余**(TLBFA_1 不例化 TLBFA), 不列入。
GOLDEN_SUBS = $(GOLDEN_RTL)/DelayN_7.sv $(GOLDEN_RTL)/DelayN_9.sv \
              $(GOLDEN_RTL)/TlbStorageWrapper_1.sv $(GOLDEN_RTL)/TLBFA_1.sv
RTL_SRCS = $(RTL_DIR)/memblock/tlbnonblock_pkg.sv \
           $(RTL_DIR)/memblock/TLBNonBlock.sv
# WRAPPER_SRCS(仅 FM impl 侧, 不进 UT 编译): 扁平端口包装 + 同一批 golden 子模块(impl 侧同
# elaborate, 两侧层次对称 → hdlin 自动同名配对, 内部逻辑真受验, 非黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBNonBlock_wrapper.sv $(GOLDEN_SUBS)
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/TLBNonBlock.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TLBNonBlock
# FM ref 侧依赖: 顶层 + 4 golden 子模块两侧 elaborate 作为共同定义(非黑盒)。
FM_REF_DEPS_TLBNonBlock = DelayN_7.sv DelayN_9.sv TlbStorageWrapper_1.sv TLBFA_1.sv
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# 新基线 golden(xs-clean) 的 TLBFA_1 含 xs_assert_v2 断言（`ifndef SYNTHESIS），UT/FM 两侧同关掉。
VCS += +define+SYNTHESIS

# UT 编译: 核 + _xs(variants) + golden 子模块 + golden 顶 + tb(不编 golden 同名 wrapper)。
simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) $(RTL_SRCS) $(GOLDEN_SUBS) $(GOLDEN_RTL)/TLBNonBlock.sv $(TB_SRCS) -top tb -o simv
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
