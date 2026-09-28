MODULE = IssueQueueAluMulBkuBrhJmp

# IssueQueueAluMulBkuBrhJmp（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesAluMulBkuBrhJmp EnqEntry UIntCompressor_27_000011100000000000001010101 OthersEntry OthersEntry_6 EnqPolicy FuBusyTableWrite FuBusyTableRead FuBusyTableRead_2 MultiWakeupQueue PipeWithFlush PipeWithFlush_1 NewAgeDetector AgeDetector AgeDetector_1
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueAluMulBkuBrhJmp.sv \
           $(RTL_DIR)/backend/EntriesAluMulBkuBrhJmp.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_2.sv \
           $(RTL_DIR)/backend/MultiWakeupQueue.sv \
           $(RTL_DIR)/backend/NewAgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector_1.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/common/PipeWithFlush.sv \
           $(RTL_DIR)/common/PipeWithFlush_1.sv \
           $(RTL_DIR)/backend/xs_MultiWakeupQueue_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/common/xs_PipeWithFlush_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueAluMulBkuBrhJmp.sv $(GOLDEN_RTL)/EntriesAluMulBkuBrhJmp.sv $(GOLDEN_RTL)/EnqEntry.sv $(GOLDEN_RTL)/UIntCompressor_27_000011100000000000001010101.sv $(GOLDEN_RTL)/OthersEntry.sv $(GOLDEN_RTL)/OthersEntry_6.sv $(GOLDEN_RTL)/EnqPolicy.sv $(GOLDEN_RTL)/FuBusyTableWrite.sv $(GOLDEN_RTL)/FuBusyTableRead.sv $(GOLDEN_RTL)/FuBusyTableRead_2.sv $(GOLDEN_RTL)/MultiWakeupQueue.sv $(GOLDEN_RTL)/PipeWithFlush.sv $(GOLDEN_RTL)/PipeWithFlush_1.sv $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/AgeDetector.sv $(GOLDEN_RTL)/AgeDetector_1.sv

FM_VARIANTS = IssueQueueAluMulBkuBrhJmp
FM_REF_DEPS_IssueQueueAluMulBkuBrhJmp = EntriesAluMulBkuBrhJmp.sv EnqEntry.sv UIntCompressor_27_000011100000000000001010101.sv OthersEntry.sv OthersEntry_6.sv EnqPolicy.sv FuBusyTableWrite.sv FuBusyTableRead.sv FuBusyTableRead_2.sv MultiWakeupQueue.sv PipeWithFlush.sv PipeWithFlush_1.sv NewAgeDetector.sv AgeDetector.sv AgeDetector_1.sv

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
