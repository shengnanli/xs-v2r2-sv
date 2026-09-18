MODULE = StdFreeList

RTL_DIR = ../../../rtl
# impl 侧的 SnapshotGenerator 从 golden 原件改指重写件（2026-09-17）
# 原先两侧读的是**同一份** $(GOLDEN_RTL)/SnapshotGenerator.sv —— 那属于 golden 逻辑复用：
# 这一块在本 target 的证明里等于没证（两侧逐字节相同，FM 当然等价）。
# SnapshotGenerator 今天已独立签核（FM SUCCEEDED / passing 82 / failing 0 /
# unmatched 0(0) / unread 0 / 零黑盒），前提满足，改指过来。
# ★注意这里能改一行，是因为它在 RTL_SRCS（会走 derive 改名 _xs、只进 impl 侧）★
# 不是 RTL_GOLDEN_DEPS —— 后者的语义是"不 derive 不改名、UT 两侧共用同一定义"
# （ut_common.mk:36），给厂商 SRAM 宏那类文件用的。MulUnit 就踩在这个区别上：
# 它的乘法叶子在 RTL_GOLDEN_DEPS 里，改指必须换变量而不是换路径。
RTL_SRCS = $(RTL_DIR)/backend/StdFreeList.sv \
           $(RTL_DIR)/backend/SnapshotGenerator.sv
TB_SRCS = tb.sv

FM_REF_DEPS_StdFreeList = SnapshotGenerator.sv
FM_MERGE_DUP = true
GOLDEN_SRCS = $(GOLDEN_RTL)/StdFreeList.sv \
              $(GOLDEN_RTL)/SnapshotGenerator.sv
FM_VARIANTS = StdFreeList

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
