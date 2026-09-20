MODULE = WBArbiterVariants

RTL_DIR  = ../../../rtl
VARIANTS = WBArbiter WBArbiter_1 WBArbiter_2 WBArbiter_3 WBArbiter_30 WBArbiter_33 \
           WBArbiter_38 WBArbiter_52 WBArbiter_55 WBArbiter_58 WBArbiter_64 \
           WBArbiter_65 WBArbiter_66

# 核在 WBArbiter.sv（xs_WBArbiter_core），其余 12 个是薄 wrapper
# （由 scripts/gen_fubusy_wbarb.py 生成）。优先级那一级是与 RealWBArbiter 族
# 共用的 rtl/common/xs_PriorityArbSelect.sv，必须一起编。
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(VARIANTS)))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(VARIANTS)))
FM_VARIANTS = $(VARIANTS)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# ---------------------------------------------------------------------------
# matched-unread 加强（vmucp）——★只给 N=1 的那四个变体，不是整个目录★
# ---------------------------------------------------------------------------
# 13 个 target 共用一份 Makefile，但只有 N=1 的 4 个有未读点需要加强：它们的
# 2N+1=3 位反饥饿寄存器在 N=1 时**永远不可达**（scripts/wbarbiter_reachability.py
# 穷举：N=1 可达状态只有全 0 一个），golden 与重写核同为死位；FM 常量折叠吃掉其中
# 3 位，剩 cancelCounter_0[0] 与 hasFull 两个 unmatched unread 点卡住 strict。
# 配对在本目录 fm_pins.tcl（四层 fail-closed），白名单与逐条依据在 scripts/fm_eq.tcl。
#
# 其余 9 个（N>=2）本来就 native+strict 双 SUCCEEDED、unread 0，**不能**顺手也开：
# fm_eq.tcl 的 vmucp 白名单是精确名单，给没在名单里的 top 开 vmucp 会直接
# FM_MODE_ERROR exit 3 —— 目录级变量一开就把那 9 个全打死。所以用 make 的
# 「按目标变量」只作用到这 4 个 fm-* 目标上。
fm-WBArbiter_3 fm-WBArbiter_38 fm-WBArbiter_58 fm-WBArbiter_66: \
    FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。本族 2N+1 个寄存器
# 全是**异步高有效**复位，tb 起手拉 8 拍复位，两轮都应当绿；真正把关复位域的是
# 与 golden 的 always 块结构比对 + mutants.py 的复位域变异。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: mutants
mutants:
	python3 mutants.py
