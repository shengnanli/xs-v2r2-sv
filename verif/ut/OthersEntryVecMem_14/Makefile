# OthersEntryVecMem_14 UT/FM 入口（OthersEntry* 家族：VlduVstu 的 simp）
# 重写件只有两个：三族共享的参数化单条目核 + 本变体薄文件。
# 核体是 xs_iq_entries_core.sv 里的 xs_iq_entry —— 与 Entries* 家族**同一份**，
# 不复制（CONVENTIONS「变体家族：核体绝不复制」）。
# 自动生成：verif/ut/OthersEntryVecMem_14/gen.py
#   （共享库 verif/ut/OthersEntry_common/othersentry_gen.py）
# 勿手改
MODULE = OthersEntryVecMem_14

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/OthersEntryVecMem_14.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/OthersEntryVecMem_14.sv

FM_VARIANTS = OthersEntryVecMem_14
FM_REF_DEPS_OthersEntryVecMem_14 = 

# ---------------------------------------------------------------------------
# FM 证明配置 —— 与 Entries* 家族同因同配，两项都是**加强**不是放宽
# ---------------------------------------------------------------------------
# FM_MERGE_DUP=false：golden 把条目负载展平成上百个逐字段寄存器，其中本变体
#   用不到的字段整组是常数；merge_duplicated_registers=true 时 FM 在 golden 侧
#   把这些同值寄存器合并掉，而可读核把同一份负载存在一根向量里、按位不合并，
#   于是两侧点数对不上。置 false 后两侧都逐个保留 —— 要求逐个比而不是合并后比。
FM_MERGE_DUP = false
# ★vmucp=true（加强，不是放宽）★：本变体首跑仅剩 15 个 matched_nc unread
#   （srcLoadDependency 的 bit[1]，两侧同为死位、ref 15 <-> impl 15 严格双射、
#    由本目录 fm_pins_pre.tcl 钉上）。依据与预登记数字见
#   verif/ut/OthersEntry_common/othersentry_gen.py 的 VMUCP 表。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS

# ---------------------------------------------------------------------------
# 复位域：条目寄存器（entryReg_*）在 golden 里**不复位**，只有 validReg 带复位
# （实测 OthersEntryVecMem_14.sv 的 `if (reset)` 只钉这一个）。可读核照抄。
#
# 不开 initreg 时 golden 侧未初始化的寄存器是 X，被 tb 的 $isunknown 跳过 ——
# 「照抄复位域」这件事根本没被验过。所以编译期 +vcs+initreg+random 打开能力，
# 运行期用 +vcs+initreg+<0|random> 选初值，两种初值都要过。
# ★ 编译期写 +vcs+initreg+0 是错的：VCS 报 OBSL_OPT_E，那是运行期选项。★
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0: simv
	./simv +vcs+initreg+0 +ntb_random_seed=$(SEED) +ncycles=$(NCYCLES) -l sim_ir0_$(SEED).log
	@grep -q "TEST PASSED" sim_ir0_$(SEED).log && echo "=== UT PASSED ($(MODULE) initreg=0 seed=$(SEED)) ===" || { echo "=== UT FAILED ($(MODULE) initreg=0 seed=$(SEED)) ==="; exit 1; }

# 变异靶子：往可读核里注入若干个**真实形态**的 bug，要求本 UT 每一个都抓得住。
.PHONY: mutants
mutants:
	python3 ../OthersEntry_common/mutants.py $(MODULE) $(MUTANT_ARGS)
