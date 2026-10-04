MODULE = LinkMonitor

# LinkMonitor：L2 的 CHI 链路层（coupledL2 LinkLayer.scala class LinkMonitor）。
# impl = rtl/uncore/LinkMonitor.sv（手写核 xs_LinkMonitor_core + golden 同名顶层）
#      + 6 个已签重写 child（两侧白盒，ref 读 golden 同名件）：
#        Decoupled2LCredit{,_1,_2}（TX）、LCredit2Decoupled（rxsnp，含 Queue4_CHISNP）、
#        LCredit2Decoupled_1（rxrsp，本 lane）、LCredit2Decoupled_2（rxdat）。
# ram_4x115 是 firtool 行为级存储叶子：两侧读同一份 golden 文件（4 项 / 2 位地址，2^2 == 4）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LinkMonitor.sv \
           $(RTL_DIR)/uncore/Decoupled2LCredit.sv \
           $(RTL_DIR)/uncore/Decoupled2LCredit_1.sv \
           $(RTL_DIR)/uncore/Decoupled2LCredit_2.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled_1.sv \
           $(RTL_DIR)/uncore/LCredit2Decoupled_2.sv \
           $(RTL_DIR)/uncore/xs_ChiselQueuePipe_core.sv \
           $(RTL_DIR)/uncore/Queue4_CHISNP.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_4x115.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LinkMonitor.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv
FM_REF_DEPS_LinkMonitor = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv
FM_VARIANTS = LinkMonitor
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用。golden 里本就有同次态的
# 寄存器对（tx.linkactivereq / txsactive；syscoreq / RegNext(true)），两侧逐个保留、逐个配对。
FM_MERGE_DUP = false
# vmucp：3 个 64 位性能计数器 dontTouch 但无扇出，预期是两侧对称的 matched-unread 点（192 位）。
# 第一跑先关（量出 unread 集合与 passing 基线），第二跑再开，见 docs/lanes/l2-link_prereg.md §4。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
