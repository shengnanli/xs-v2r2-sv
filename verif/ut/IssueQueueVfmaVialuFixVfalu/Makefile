MODULE = IssueQueueVfmaVialuFixVfalu

# IssueQueueVfmaVialuFixVfalu（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesVfmaVialuFixVfalu EnqEntry_16 OthersEntry_150 OthersEntry_152 EnqPolicy_14 FuBusyTableWrite_80 FuBusyTableWrite_73 FuBusyTableRead_80 FuBusyTableRead_73 NewAgeDetector AgeDetector_8 AgeDetector_15
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueVfmaVialuFixVfalu.sv \
           $(RTL_DIR)/backend/EntriesVfmaVialuFixVfalu.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_80.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_73.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_80.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_73.sv \
           $(RTL_DIR)/backend/NewAgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector_8.sv \
           $(RTL_DIR)/backend/AgeDetector_15.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueVfmaVialuFixVfalu.sv $(GOLDEN_RTL)/EntriesVfmaVialuFixVfalu.sv $(GOLDEN_RTL)/EnqEntry_16.sv $(GOLDEN_RTL)/OthersEntry_150.sv $(GOLDEN_RTL)/OthersEntry_152.sv $(GOLDEN_RTL)/EnqPolicy_14.sv $(GOLDEN_RTL)/FuBusyTableWrite_80.sv $(GOLDEN_RTL)/FuBusyTableWrite_73.sv $(GOLDEN_RTL)/FuBusyTableRead_80.sv $(GOLDEN_RTL)/FuBusyTableRead_73.sv $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/AgeDetector_8.sv $(GOLDEN_RTL)/AgeDetector_15.sv

FM_VARIANTS = IssueQueueVfmaVialuFixVfalu
FM_REF_DEPS_IssueQueueVfmaVialuFixVfalu = EntriesVfmaVialuFixVfalu.sv EnqEntry_16.sv OthersEntry_150.sv OthersEntry_152.sv EnqPolicy_14.sv FuBusyTableWrite_80.sv FuBusyTableWrite_73.sv FuBusyTableRead_80.sv FuBusyTableRead_73.sv NewAgeDetector.sv AgeDetector_8.sv AgeDetector_15.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/IssueQueueVfmaVialuFixVfalu.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
