MODULE = IssueQueueFaluFcvtF2vFmacFdiv

# IssueQueueFaluFcvtF2vFmacFdiv（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesFaluFcvtF2vFmacFdiv EnqEntry_8 UIntCompressor_27_000000000000001010100000000 OthersEntry_88 OthersEntry_90 EnqPolicy_8 FuBusyTableWrite_42 FuBusyTableRead_42 FuBusyTableWrite_43 FuBusyTableRead_43 MultiWakeupQueue_4 PipeWithFlush_6 PipeWithFlush_7 PipeWithFlush_8 PipeWithFlush_9 NewAgeDetector AgeDetector_8 AgeDetector_9
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueFaluFcvtF2vFmacFdiv.sv \
           $(RTL_DIR)/backend/EntriesFaluFcvtF2vFmacFdiv.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_42.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_42.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_43.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_43.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_4.sv \
           $(RTL_DIR)/backend/NewAgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector_8.sv \
           $(RTL_DIR)/backend/AgeDetector_9.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv \
           $(RTL_DIR)/common/PipeWithFlush_6.sv \
           $(RTL_DIR)/common/PipeWithFlush_7.sv \
           $(RTL_DIR)/common/PipeWithFlush_8.sv \
           $(RTL_DIR)/common/PipeWithFlush_9.sv \
           $(RTL_DIR)/backend/xs_MultiWakeupQueue_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/common/xs_PipeWithFlush_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueFaluFcvtF2vFmacFdiv.sv $(GOLDEN_RTL)/EntriesFaluFcvtF2vFmacFdiv.sv $(GOLDEN_RTL)/EnqEntry_8.sv $(GOLDEN_RTL)/UIntCompressor_27_000000000000001010100000000.sv $(GOLDEN_RTL)/OthersEntry_88.sv $(GOLDEN_RTL)/OthersEntry_90.sv $(GOLDEN_RTL)/EnqPolicy_8.sv $(GOLDEN_RTL)/FuBusyTableWrite_42.sv $(GOLDEN_RTL)/FuBusyTableRead_42.sv $(GOLDEN_RTL)/FuBusyTableWrite_43.sv $(GOLDEN_RTL)/FuBusyTableRead_43.sv $(GOLDEN_RTL)/MultiWakeupQueue_4.sv $(GOLDEN_RTL)/PipeWithFlush_6.sv $(GOLDEN_RTL)/PipeWithFlush_7.sv $(GOLDEN_RTL)/PipeWithFlush_8.sv $(GOLDEN_RTL)/PipeWithFlush_9.sv $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/AgeDetector_8.sv $(GOLDEN_RTL)/AgeDetector_9.sv

FM_VARIANTS = IssueQueueFaluFcvtF2vFmacFdiv
FM_REF_DEPS_IssueQueueFaluFcvtF2vFmacFdiv = EntriesFaluFcvtF2vFmacFdiv.sv EnqEntry_8.sv UIntCompressor_27_000000000000001010100000000.sv OthersEntry_88.sv OthersEntry_90.sv EnqPolicy_8.sv FuBusyTableWrite_42.sv FuBusyTableRead_42.sv FuBusyTableWrite_43.sv FuBusyTableRead_43.sv MultiWakeupQueue_4.sv PipeWithFlush_6.sv PipeWithFlush_7.sv PipeWithFlush_8.sv PipeWithFlush_9.sv NewAgeDetector.sv AgeDetector_8.sv AgeDetector_9.sv

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
