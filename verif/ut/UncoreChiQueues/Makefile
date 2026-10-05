MODULE = UncoreChiQueues

# CHI / L2TLB 侧 6 个 chisel Queue 单态化（薄文件 scripts/gen_uncore_queues.py 生成，fail-closed 对照 golden）：
#   Queue16_CHIREQ / Queue16_CHIRSP  TXREQ / TXRSP 的 16 项 flit 缓冲          —— 已签共享核 xs_ChiselQueue_core
#   Queue2_PCrdGranted               pCrdQueue_s3（2 项）                      —— 已签共享核 xs_ChiselQueue_core
#   Queue4_CHISNP                    LCredit2Decoupled 的 4 项缓冲，pipe=true  —— rtl/uncore/xs_ChiselQueuePipe_core.sv
#   Queue78_PCrdGranted              pCrdQueue_s2（78 项）                     —— 已签共享核 xs_ChiselQueue_core
#   Queue40_L2TlbMQBundle            L2TlbMissQueue 的 40 项带 flush 队列       —— 已签 xs_L2TlbMissQueue_core
# 存储 ram_*：前四个深度 16/16/4/2 是 2 的幂，按 codex 0151 D60 两侧同源 inline（RTL_GOLDEN_DEPS + FM_REF_DEPS）。
# ★Queue78_PCrdGranted（ram_78x15，7 位地址/78 深）与 Queue40_L2TlbMQBundle（ram_40x47，6 位地址/40 深）
#   深度非 2 的幂：inline 必触发 FMR_ELAB-147 -> FM-156，只能走 regimeA —— FM 两侧**对称黑盒**：
#   两个 .sv 既不进 FM_REF_DEPS 也不进 RTL_GOLDEN_DEPS（后者进 FM impl 文件集），只进 GOLDEN_SRCS 供 VCS
#   行为仿真（golden 与重写两侧例化同一份定义）。授权：codex 0210 R1（ram_78x15 单条审定，仅 Queue78_PCrdGranted）
#   / R2（ram_40x47 父级扩到 Queue40_L2TlbMQBundle）；登记见 verif/vendor_boundary.tsv、verif/ram_model_parents.tsv、
#   scripts/audit_ram_memory_model.py 的 MANUAL_REVIEW_*。黑盒对象逐条声明在 verif/allow/<target>.json
#   （两侧各恰好 1 个 ram_ext），这两个目标单独走 assembly 模式 + allowlist。
#   ★入表不等于转绿：绿灯只来自各自 clean native FM 结果本身★
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
                  $(GOLDEN_RTL)/ram_2x15.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue16_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/Queue2_PCrdGranted.sv \
              $(GOLDEN_RTL)/Queue78_PCrdGranted.sv \
              $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
              $(GOLDEN_RTL)/ram_78x15.sv \
              $(GOLDEN_RTL)/ram_40x47.sv
# FM_VARIANTS / FM_REF_DEPS 写字面名（fm_predict.py 静态解析本文件）。
FM_VARIANTS = Queue16_CHIREQ Queue16_CHIRSP Queue4_CHISNP Queue2_PCrdGranted Queue78_PCrdGranted Queue40_L2TlbMQBundle
FM_REF_DEPS_Queue16_CHIREQ = ram_16x137.sv
FM_REF_DEPS_Queue16_CHIRSP = ram_16x62.sv
FM_REF_DEPS_Queue4_CHISNP = ram_4x115.sv
FM_REF_DEPS_Queue2_PCrdGranted = ram_2x15.sv
# ram_78x15 / ram_40x47 故意不在 FM_REF_DEPS 里（两侧对称黑盒，见文件头）
FM_REF_DEPS_Queue78_PCrdGranted =
FM_REF_DEPS_Queue40_L2TlbMQBundle =
# 只有这两个目标走 assembly + 逐对象声明（verif/allow/<T>.json：黑盒只许 ram_* 两侧各 1）；其余四个仍 signoff-strict
fm-Queue78_PCrdGranted fm-Queue40_L2TlbMQBundle: FM_MODE = assembly
fm-Queue78_PCrdGranted fm-Queue40_L2TlbMQBundle: FM_ALLOWLIST = 1
# codex 0219 §2：Queue78_PCrdGranted 的 FM 证明输入收窄为它**真实例化**的最小闭包 ——
# 共享核 xs_ChiselQueue_core + Queue78 薄 wrapper；ram_78x15 两侧对称黑盒（不进任何一侧），
# 其余变体用的 ram_16x137/ram_16x62/ram_4x115/ram_2x15 与别的薄文件**不属于** Queue78，
# 原先因同目录共用 RTL_SRCS/RTL_GOLDEN_DEPS 被一并记进 receipt.impl_closure（假依赖）。
# 只是 target-specific 覆盖：另外 5 个目标的 FM 输入不变；VCS UT（simv）仍用全集。
fm-Queue78_PCrdGranted: RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue_core.sv \
                                   $(RTL_DIR)/uncore/Queue78_PCrdGranted.sv
fm-Queue78_PCrdGranted: RTL_GOLDEN_DEPS =
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
