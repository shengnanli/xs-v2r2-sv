MODULE = PTWNewFilter

# PTWNewFilter = MemBlock 的 dtlbRepeater：8 个 dtlb miss 口 → 三张过滤表（load 16 项 / store 8 项 / prefetch 8 项）
# → 3 路轮转仲裁 → L2TLB；L2TLB 响应打一拍后广播给三张表回填，flush 经 DelayN_1 延迟 2 拍。
# golden 直接 child 4 类 5 个：PTWFilterEntry（load_filter）、PTWFilterEntry_1 ×2（store/prefetch）、
# DelayN_1（flush_delay）、RRArbiterInit_12（ptw_arb）。docs/coverage_three_axis.tsv 里都已签核（PTWFilterEntry_1
# 由本 lane 签）。处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒。
# wrapper 端口表/打包/展平、核里三张表与仲裁器的逐口连线由 scripts/gen_ptwnewfilter.py 生成；
# fm_pins_pre.tcl（golden 顶层 + 三张表内部寄存器逐位钉点）同出自该生成器。
RTL_DIR  = ../../../rtl
# memblock 公共包排最前：tlbnb_pkg（hit_key_t / ptw_s1_t / ptw_s2_t）住在这里。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/PTWFilterEntry.sv \
           $(RTL_DIR)/memblock/PTWFilterEntry_1.sv \
           $(RTL_DIR)/common/xs_DelayN_core.sv \
           $(RTL_DIR)/common/DelayN_1.sv \
           $(RTL_DIR)/common/RRArbiterInit.sv \
           $(RTL_DIR)/common/RRArbiterInit_12.sv \
           $(RTL_DIR)/memblock/PTWNewFilter.sv
TB_SRCS  = tb.sv

PNF_CHILDREN = PTWFilterEntry.sv PTWFilterEntry_1.sv DelayN_1.sv RRArbiterInit_12.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/PTWNewFilter.sv $(addprefix $(GOLDEN_RTL)/,$(PNF_CHILDREN))

FM_VARIANTS = PTWNewFilter
FM_REF_DEPS_PTWNewFilter = $(PNF_CHILDREN)

# 关掉 merge_duplicated_registers：golden 有值恒等的多份寄存器（三份 resp.valid 打拍），让 FM 逐个比；
# fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/PTWNewFilter.tcl★ —— 两侧对称死位
# （三张表里的 inflight_counter，只喂性能计数器与断言）。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 断言块两侧统一关掉（与 FM 口径一致）。
# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
#   INITREG=0 / random / <seed>017（第三个真随机档）
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_ptwnewfilter.py --check
