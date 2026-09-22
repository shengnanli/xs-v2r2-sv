MODULE = LLPTW

RTL_DIR = ../../../rtl
# 单文件规范：私有包 + 核 + golden 同名 wrapper 全在 LLPTW.sv；PTE 判定函数在 mmu 公共包；
# 三个 RRArbiterInit_1 与 bitmap_arb（RRArbiterInit_4）用 rtl/common 的重写薄文件
# （核在 RRArbiterInit.sv 里的 xs_RRArbiterInit_core，全家族共一份）。
RTL_SRCS = $(RTL_DIR)/mmu/mmu_common_pkg.sv \
           $(RTL_DIR)/mmu/LLPTW.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_1.sv \
           $(RTL_DIR)/common/RRArbiterInit_4.sv
TB_SRCS = tb.sv

# ---------------------------------------------------------------------------
# 边界：
#   · RRArbiterInit_1 / RRArbiterInit_4：本仓重写件（各自是 306 里的独立 target，见
#     verif/ut/RRArbiterInitVariants），impl 侧用重写版、ref 侧用 golden 版，两侧白盒对称。
#     端口/参数已对位（golden 变体无 io_in_*_ready，重写薄文件同样不引出）。
#   · Arbiter2_LLPTW_Anon（hptw_req_arb）：golden 独有的 2 入 Chisel Arbiter，本仓无重写件，
#     两侧同源读同一份 golden（同 verif/ut/PtwCache/Makefile 对 SRAM 族的取法），不黑盒——
#     黑盒边界为空，proof_mode 走 signoff-strict。
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LLPTW.sv \
              $(GOLDEN_RTL)/RRArbiterInit_1.sv \
              $(GOLDEN_RTL)/RRArbiterInit_4.sv \
              $(RTL_GOLDEN_DEPS)

FM_VARIANTS = LLPTW
FM_REF_DEPS_LLPTW = RRArbiterInit_1.sv RRArbiterInit_4.sv Arbiter2_LLPTW_Anon.sv
# 关掉重复寄存器合并：让 passing 与 fm_predict.py 的模型逐位可对账。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的 XSError/assert 段（`ifndef SYNTHESIS）随机激励下会触发 $fatal，统一关掉。
# ★双例化 UT 的两档 initreg 是 +0 与 +1，不用 +random★（random 按实例各摇各的初值；
# 本模块 addr/hpaddr/way_info_r/mem_refill_id/perf 打拍/enq_ptr_reg 等不复位）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
