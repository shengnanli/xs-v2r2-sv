# MissEntry —— DCache MissQueue 的一个 MSHR 表项（MissQueue 里 16 份例化同一模块）
# 重写件 rtl/memblock/MissEntry.sv（missentry_pkg + xs_MissEntry_core + golden 同名 wrapper；
# wrapper 的端口表与结构体拆装由 scripts/gen_missq.py 生成）。golden 是无子模块的叶子。
MODULE = MissEntry

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/MissEntry.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/MissEntry.sv

FM_VARIANTS = MissEntry

# 逐个比较，不合并重复寄存器：golden 有多份值恒等的打拍（每个请求口一份 RegNext(primary_fire) 等），
# 两侧照抄同样份数；也让 fm_predict 模型严格适用。
FM_MERGE_DUP = false

# ★vmucp：依据见 verif/fm_target_config/MissEntry.tcl★ —— 209 个两侧对称死寄存器位（断言打拍、
# 性能秒表/延迟计数器）加强为实比；名字不同的由 fm_pins_pre.tcl（scripts/gen_missq.py 生成）逐项配对。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 段调用未定义的 xs_assert_v2，两侧统一定义 SYNTHESIS。
# initreg：编译期打开机制，运行期 INITREG 选 +vcs+initreg+0 / random / <seed>017。
# 不复位且输出可见的寄存器由 tb 的确定性暖机（store 分配 + 两拍 GrantData）写定。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gencheck
gencheck:
	python3 gen.py --check
