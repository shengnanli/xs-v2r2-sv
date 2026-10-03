MODULE = IssueQueueAluCsrFenceDiv

# IssueQueueAluCsrFenceDiv（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesAluCsrFenceDiv EnqEntry_6 UIntCompressor_27_000011100000000000001010101 OthersEntry_66 OthersEntry_72 EnqPolicy FuBusyTableRead_23 MultiWakeupQueue_2 PipeWithFlush NewAgeDetector AgeDetector AgeDetector_1
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueAluCsrFenceDiv.sv \
           $(RTL_DIR)/backend/EntriesAluCsrFenceDiv.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_23.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue_2.sv \
           $(RTL_DIR)/backend/NewAgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector_1.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv \
           $(RTL_DIR)/common/PipeWithFlush.sv \
           $(RTL_DIR)/backend/xs_MultiWakeupQueue_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/common/xs_PipeWithFlush_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueAluCsrFenceDiv.sv $(GOLDEN_RTL)/EntriesAluCsrFenceDiv.sv $(GOLDEN_RTL)/EnqEntry_6.sv $(GOLDEN_RTL)/UIntCompressor_27_000011100000000000001010101.sv $(GOLDEN_RTL)/OthersEntry_66.sv $(GOLDEN_RTL)/OthersEntry_72.sv $(GOLDEN_RTL)/EnqPolicy.sv $(GOLDEN_RTL)/FuBusyTableRead_23.sv $(GOLDEN_RTL)/MultiWakeupQueue_2.sv $(GOLDEN_RTL)/PipeWithFlush.sv $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/AgeDetector.sv $(GOLDEN_RTL)/AgeDetector_1.sv

FM_VARIANTS = IssueQueueAluCsrFenceDiv
FM_REF_DEPS_IssueQueueAluCsrFenceDiv = EntriesAluCsrFenceDiv.sv EnqEntry_6.sv UIntCompressor_27_000011100000000000001010101.sv OthersEntry_66.sv OthersEntry_72.sv EnqPolicy.sv FuBusyTableRead_23.sv MultiWakeupQueue_2.sv PipeWithFlush.sv NewAgeDetector.sv AgeDetector.sv AgeDetector_1.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/IssueQueueAluCsrFenceDiv.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
