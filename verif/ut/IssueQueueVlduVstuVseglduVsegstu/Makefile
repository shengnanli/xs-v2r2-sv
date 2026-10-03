MODULE = IssueQueueVlduVstuVseglduVsegstu

# IssueQueueVlduVstuVseglduVsegstu（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesVlduVstuVseglduVsegstu EnqEntryVecMem OthersEntryVecMem OthersEntryVecMem_2 EnqPolicy_14 NewAgeDetector_6 AgeDetector_12 AgeDetector_21
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueVlduVstuVseglduVsegstu.sv \
           $(RTL_DIR)/backend/EntriesVlduVstuVseglduVsegstu.sv \
           $(RTL_DIR)/backend/NewAgeDetector_6.sv \
           $(RTL_DIR)/backend/AgeDetector_12.sv \
           $(RTL_DIR)/backend/AgeDetector_21.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueVlduVstuVseglduVsegstu.sv $(GOLDEN_RTL)/EntriesVlduVstuVseglduVsegstu.sv $(GOLDEN_RTL)/EnqEntryVecMem.sv $(GOLDEN_RTL)/OthersEntryVecMem.sv $(GOLDEN_RTL)/OthersEntryVecMem_2.sv $(GOLDEN_RTL)/EnqPolicy_14.sv $(GOLDEN_RTL)/NewAgeDetector_6.sv $(GOLDEN_RTL)/AgeDetector_12.sv $(GOLDEN_RTL)/AgeDetector_21.sv

FM_VARIANTS = IssueQueueVlduVstuVseglduVsegstu
FM_REF_DEPS_IssueQueueVlduVstuVseglduVsegstu = EntriesVlduVstuVseglduVsegstu.sv EnqEntryVecMem.sv OthersEntryVecMem.sv OthersEntryVecMem_2.sv EnqPolicy_14.sv NewAgeDetector_6.sv AgeDetector_12.sv AgeDetector_21.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/IssueQueueVlduVstuVseglduVsegstu.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
