MODULE = MainPipe_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# CustomL1Hint 子树(reviewer 裁定选项 2): CustomL1Hint 是 192 行纯逻辑, 例化
# Queue16/Queue4_HintQueueEntry, 后者内层 ram_16x11/ram_4x11 均是 reg 数组存储
# (非厂商宏, 可完全 elaborate)。signoff-strict 不允许任何黑盒(matched blackbox pair
# 也判 strict_has_objects→PARTIAL), 故两侧同名 elaborate 全套 golden CustomL1Hint 逻辑,
# 不再当黑盒。无任何 vendor 叶子需要黑盒边界。
FM_L1HINT_ELAB = CustomL1Hint.sv \
                 Queue16_HintQueueEntry.sv \
                 Queue4_HintQueueEntry.sv \
                 ram_16x11.sv \
                 ram_4x11.sv

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/MainPipe_1.sv
# 手写 wrapper + impl 侧也展开同一套 golden CustomL1Hint 子树(两侧对称 elaborate,
# 令 CustomL1Hint/Queue/ram 逻辑受验, 消除黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/uncore/MainPipe_1_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(FM_L1HINT_ELAB))
GOLDEN_SRCS = $(GOLDEN_RTL)/MainPipe_1.sv \
              $(addprefix $(GOLDEN_RTL)/,$(FM_L1HINT_ELAB)) \
              $(GOLDEN_RTL)/Arbiter3_TaskWithData.sv \
              $(GOLDEN_RTL)/Arbiter3_CHIREQ.sv \
              $(GOLDEN_RTL)/Arbiter3_TaskBundle.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref = golden MainPipe_1 + CustomL1Hint 子树(两侧 elaborate) + Arbiter3_*(内联进核,
#     进 ref deps 让 FM 展平 golden 端的仲裁器)。无黑盒。
FM_VARIANTS = MainPipe_1
FM_REF_DEPS_MainPipe_1 = $(FM_L1HINT_ELAB) \
                         Arbiter3_TaskWithData.sv Arbiter3_CHIREQ.sv Arbiter3_TaskBundle.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
