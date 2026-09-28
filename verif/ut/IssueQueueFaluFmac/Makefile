MODULE = IssueQueueFaluFmac

# IssueQueueFaluFmac（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesFaluFmac EnqEntry_12 UIntCompressor_27_000000000000001010100000000 OthersEntry_120 OthersEntry_122 EnqPolicy_8 FuBusyTableWrite_52 FuBusyTableRead_52 FuBusyTableWrite_53 FuBusyTableRead_53 MultiWakeupQueue_5 PipeWithFlush_10 PipeWithFlush_11 NewAgeDetector_6 AgeDetector_12 AgeDetector_13
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueFaluFmac.sv \
           $(RTL_DIR)/backend/EntriesFaluFmac.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_52.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_52.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_53.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_53.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_5.sv \
           $(RTL_DIR)/backend/NewAgeDetector_6.sv \
           $(RTL_DIR)/backend/AgeDetector_12.sv \
           $(RTL_DIR)/backend/AgeDetector_13.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv \
           $(RTL_DIR)/common/PipeWithFlush_10.sv \
           $(RTL_DIR)/common/PipeWithFlush_11.sv \
           $(RTL_DIR)/backend/xs_MultiWakeupQueue_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/common/xs_PipeWithFlush_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueFaluFmac.sv $(GOLDEN_RTL)/EntriesFaluFmac.sv $(GOLDEN_RTL)/EnqEntry_12.sv $(GOLDEN_RTL)/UIntCompressor_27_000000000000001010100000000.sv $(GOLDEN_RTL)/OthersEntry_120.sv $(GOLDEN_RTL)/OthersEntry_122.sv $(GOLDEN_RTL)/EnqPolicy_8.sv $(GOLDEN_RTL)/FuBusyTableWrite_52.sv $(GOLDEN_RTL)/FuBusyTableRead_52.sv $(GOLDEN_RTL)/FuBusyTableWrite_53.sv $(GOLDEN_RTL)/FuBusyTableRead_53.sv $(GOLDEN_RTL)/MultiWakeupQueue_5.sv $(GOLDEN_RTL)/PipeWithFlush_10.sv $(GOLDEN_RTL)/PipeWithFlush_11.sv $(GOLDEN_RTL)/NewAgeDetector_6.sv $(GOLDEN_RTL)/AgeDetector_12.sv $(GOLDEN_RTL)/AgeDetector_13.sv

FM_VARIANTS = IssueQueueFaluFmac
FM_REF_DEPS_IssueQueueFaluFmac = EntriesFaluFmac.sv EnqEntry_12.sv UIntCompressor_27_000000000000001010100000000.sv OthersEntry_120.sv OthersEntry_122.sv EnqPolicy_8.sv FuBusyTableWrite_52.sv FuBusyTableRead_52.sv FuBusyTableWrite_53.sv FuBusyTableRead_53.sv MultiWakeupQueue_5.sv PipeWithFlush_10.sv PipeWithFlush_11.sv NewAgeDetector_6.sv AgeDetector_12.sv AgeDetector_13.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/IssueQueueFaluFmac.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
