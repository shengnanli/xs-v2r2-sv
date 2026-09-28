MODULE = FastArbiterL2

RTL_DIR  = ../../../rtl
# 核 xs_FastArbiter_core（rtl/common/，手写）+ 5 个薄 wrapper（rtl/uncore/，由
# scripts/gen_fastarbiter_l2.py 生成；tb.sv 也由它生成）。
RTL_SRCS = $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter_3.sv $(RTL_DIR)/uncore/FastArbiter_4.sv \
           $(RTL_DIR)/uncore/FastArbiter_5.sv $(RTL_DIR)/uncore/FastArbiter_6.sv \
           $(RTL_DIR)/uncore/FastArbiter_7.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/FastArbiter_3.sv $(GOLDEN_RTL)/FastArbiter_4.sv \
              $(GOLDEN_RTL)/FastArbiter_5.sv $(GOLDEN_RTL)/FastArbiter_6.sv \
              $(GOLDEN_RTL)/FastArbiter_7.sv
FM_VARIANTS = FastArbiter_3 FastArbiter_4 FastArbiter_5 FastArbiter_6 FastArbiter_7

# pendingMask[0] 是两侧对称的结构死位（rrGrantMask[0] 恒 0 把它与掉），
# 按 vmucp standing rule 实开比较；精确绑定见 verif/fm_target_config/FastArbiter_<N>.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
# 关 merge_dup：fm_predict 的 passing 模型（寄存器位 + 输出位）只在它关闭时成立
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。
# 本族两张掩码都是异步复位的，tb 在 rst=1 窗口之后才开始比对。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
