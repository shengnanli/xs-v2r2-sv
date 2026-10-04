MODULE = UncoreChiQueues

# CHI / L2TLB 侧 6 个 chisel Queue 单态化（薄文件 scripts/gen_uncore_queues.py 生成，fail-closed 对照 golden）：
#   Queue16_CHIREQ / Queue16_CHIRSP  TXREQ / TXRSP 的 16 项 flit 缓冲          —— 已签共享核 xs_ChiselQueue_core
#   Queue2_PCrdGranted               pCrdQueue_s3（2 项）                      —— 已签共享核 xs_ChiselQueue_core
#   Queue4_CHISNP                    LCredit2Decoupled 的 4 项缓冲，pipe=true  —— rtl/uncore/xs_ChiselQueuePipe_core.sv
#   Queue78_PCrdGranted              pCrdQueue_s2（78 项）                     —— 已签共享核 xs_ChiselQueue_core
#   Queue40_L2TlbMQBundle            L2TlbMissQueue 的 40 项带 flush 队列       —— 已签 xs_L2TlbMissQueue_core
# 存储 ram_*：前四个深度 16/16/4/2 是 2 的幂，按 codex 0151 D60 两侧同源 inline（RTL_GOLDEN_DEPS + FM_REF_DEPS）。
# ★Queue78_PCrdGranted（ram_78x15，7 位地址/78 深）与 Queue40_L2TlbMQBundle（ram_40x47，6 位地址/40 深）
#   深度非 2 的幂：inline 必触发 FMR_ELAB-147，FM 只能两侧对称黑盒，而 ram_78x15 不在 vendor_boundary.tsv、
#   ram_40x47 的已审定父级不含 Queue40_L2TlbMQBundle（codex 0209：逐父级扩展、不自动传递）——
#   两者须 codex 新裁定，裁定前**不进 FM_VARIANTS**，只做 UT（VCS 读 golden ram 文件，两侧同源）。★
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
           $(RTL_DIR)/uncore/xs_ChiselQueuePipe_core.sv \
           $(RTL_DIR)/memblock/L2TlbMissQueue.sv \
           $(RTL_DIR)/uncore/Queue16_CHIREQ.sv \
           $(RTL_DIR)/uncore/Queue16_CHIRSP.sv \
           $(RTL_DIR)/uncore/Queue4_CHISNP.sv \
           $(RTL_DIR)/uncore/Queue2_PCrdGranted.sv \
           $(RTL_DIR)/uncore/Queue78_PCrdGranted.sv \
           $(RTL_DIR)/memblock/Queue40_L2TlbMQBundle.sv
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/ram_16x137.sv \
                  $(GOLDEN_RTL)/ram_16x62.sv \
                  $(GOLDEN_RTL)/ram_4x115.sv \
                  $(GOLDEN_RTL)/ram_2x15.sv \
                  $(GOLDEN_RTL)/ram_78x15.sv \
                  $(GOLDEN_RTL)/ram_40x47.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue16_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/Queue2_PCrdGranted.sv \
              $(GOLDEN_RTL)/Queue78_PCrdGranted.sv \
              $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv
# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = Queue16_CHIREQ Queue16_CHIRSP Queue4_CHISNP Queue2_PCrdGranted
FM_REF_DEPS_Queue16_CHIREQ = ram_16x137.sv
FM_REF_DEPS_Queue16_CHIRSP = ram_16x62.sv
FM_REF_DEPS_Queue4_CHISNP = ram_4x115.sv
FM_REF_DEPS_Queue2_PCrdGranted = ram_2x15.sv
# 不合并重复寄存器：比较点 = 寄存器位 + 输出位，fm_predict 模型精确适用；常量段 ram 位
# 在 merge=true 下两侧合并不对称（TLBuffer_13 Makefile 实测），关掉是加强不是放宽。
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
# 三档：INITREG=0（全 0）/ random（seed 1 退化为全 1）/ <seed>017（与 ntb 种子无关的真随机）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check
