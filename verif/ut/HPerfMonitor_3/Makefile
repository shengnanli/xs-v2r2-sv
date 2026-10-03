MODULE = HPerfMonitor_3

# HPerfCounter_21（单个性能计数器事件选择流水线）与 HPerfMonitor_3（8 份 + 两拍打拍）同一 UT。
# HPerfMonitor_3 的唯一 child 是 HPerfCounter_21（本 UT 自己签），两侧白盒，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/HPerfCounter_21.sv \
           $(RTL_DIR)/common/HPerfMonitor_3.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/HPerfCounter_21.sv \
              $(GOLDEN_RTL)/HPerfMonitor_3.sv
FM_VARIANTS = HPerfCounter_21 HPerfMonitor_3
FM_REF_DEPS_HPerfMonitor_3 = HPerfCounter_21.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false

# 两目标的算子寄存器 [4:3] 两侧同为死位（依据与期望数见 verif/fm_target_config/<T>.tcl）；
# 路径差由同目录 fm_pins.tcl 钉配，开 vmucp 让 FM 实际比较这些点。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器无复位（照抄 golden）：+random 档两侧初值不同，tb 暖机 8 拍（流水线最深 6 拍）后才比。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)
