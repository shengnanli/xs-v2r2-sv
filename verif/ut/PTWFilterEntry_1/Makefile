MODULE = PTWFilterEntry_1

# PTWFilterEntry_1（PTWNewFilter 的 store_filter / prefetch_filter：2 lane、8 项、无 hint 的 PTW 请求过滤表）。
# golden 0 child，无黑盒。核与 load 那一张共用（rtl/memblock/PTWFilterEntry.sv 的 xs_PTWFilterEntry_core），
# 本变体的薄 wrapper 在 rtl/memblock/PTWFilterEntry_1.sv（端口表/响应打包由 scripts/gen_ptwnewfilter.py 生成）。
RTL_DIR  = ../../../rtl
# memblock 公共包排最前：tlbnb_pkg（hit_key_t / ptw_hit）住在这里。
RTL_SRCS = $(RTL_DIR)/memblock/memblock_common_pkg.sv \
           $(RTL_DIR)/memblock/PTWFilterEntry.sv \
           $(RTL_DIR)/memblock/PTWFilterEntry_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/PTWFilterEntry_1.sv

FM_VARIANTS = PTWFilterEntry_1
# FM_REF_DEPS_PTWFilterEntry_1：golden 0 child，无依赖（不写空赋值，见 CONVENTIONS）。

# 关掉 merge_duplicated_registers：让 FM 逐个比，fm_predict 的 passing 模型也只在关掉时严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/PTWFilterEntry_1.tcl★ —— 3 位两侧对称死位
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
	python3 ../../../scripts/gen_ptwnewfilter.py --check
