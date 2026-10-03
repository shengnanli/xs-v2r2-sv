MODULE = PTWFilterEntry

# PTWFilterEntry（PTWNewFilter.load_filter：dtlb_ld → L2TLB 的 PTW 请求过滤表，16 项 4 lane）。golden 0 child。
# 无黑盒。wrapper 的端口表与 PTW 响应打包由 scripts/gen_mmuleaf.py 生成。
RTL_DIR  = ../../../rtl
# memblock 公共包排最前：tlbnb_pkg（hit_key_t / ptw_hit）住在这里。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/PTWFilterEntry.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PTWFilterEntry.sv

FM_VARIANTS = PTWFilterEntry
FM_REF_DEPS_PTWFilterEntry =

# 关掉 merge_duplicated_registers：让 FM 逐个比，fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/PTWFilterEntry.tcl★ —— 4 位两侧对称死位
# （inflight_counter，只喂性能计数器与断言），FM 按名配上。
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
	python3 ../../../scripts/gen_mmuleaf.py --check
