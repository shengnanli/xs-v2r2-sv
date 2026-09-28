# DCacheLeaves —— DCache 的 7 个小 child（单入仲裁器×3、TreeArbiter、MissReadyGen、
# PrefetcherMonitor、FDPrefetcherMonitor），一个 tb 里各自双例化逐拍比对（gen.py 生成）。
# 全部是自足叶子：无子模块、无黑盒。
#   TreeArbiter 复用共享核 xs_FixedPriorityArbiter_core（核未改）。
#   FDPrefetcherMonitor 的 golden 在本配置下 0 输出 0 寄存器（firtool 全删），FM 无比较点，
#   不列入 FM_VARIANTS；端口契约另跑：make portlint-fdp。
MODULE = DCacheLeaves

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/memblock/Arbiter1_TagWriteReq.sv \
           $(RTL_DIR)/memblock/Arbiter1_L1BankedDataWriteReq.sv \
           $(RTL_DIR)/memblock/Arbiter1_L1BankedDataWriteReqCtrl.sv \
           $(RTL_DIR)/memblock/TreeArbiter.sv \
           $(RTL_DIR)/memblock/MissReadyGen.sv \
           $(RTL_DIR)/memblock/PrefetcherMonitor.sv \
           $(RTL_DIR)/memblock/FDPrefetcherMonitor.sv
TB_SRCS  = tb.sv

LEAVES = Arbiter1_TagWriteReq Arbiter1_L1BankedDataWriteReq Arbiter1_L1BankedDataWriteReqCtrl \
         TreeArbiter MissReadyGen PrefetcherMonitor FDPrefetcherMonitor
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))

FM_VARIANTS = Arbiter1_TagWriteReq Arbiter1_L1BankedDataWriteReq Arbiter1_L1BankedDataWriteReqCtrl \
              TreeArbiter MissReadyGen PrefetcherMonitor

# 关 merge_dup：fm_predict 模型严格适用（加强不是放宽）。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck portlint-fdp
gencheck:
	python3 gen.py --check

portlint-fdp:
	python3 $(XSSV_HOME)/scripts/port_contract_lint.py --order fail \
	  --impl-src $(abspath $(RTL_DIR)/memblock/FDPrefetcherMonitor.sv) FDPrefetcherMonitor
