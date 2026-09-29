MODULE = Scheduler_3

# Scheduler_3（调度器）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   IssueQueueStaMou EntriesStaMou EnqEntry_20 UIntCompressor_27_000011100000000000001010101 OthersEntry_172 OthersEntry_174 EnqPolicy_14 NewAgeDetector_6 AgeDetector_12 AgeDetector_21 IssueQueueLdu EntriesLdu EnqEntry_24 OthersEntry_200 OthersEntry_202 FuBusyTableWrite_105 FuBusyTableRead_105 IssueQueueVlduVstuVseglduVsegstu EntriesVlduVstuVseglduVsegstu EnqEntryVecMem OthersEntryVecMem OthersEntryVecMem_2 IssueQueueVlduVstu EntriesVlduVstu EnqEntryVecMem_2 OthersEntryVecMem_14 OthersEntryVecMem_16 IssueQueueStdMoud EntriesStdMoud EnqEntry_30 OthersEntry_242 OthersEntry_244
# 自动生成：verif/ut/IssueQueue_common/gen_tb_sched.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Scheduler_3.sv \
           $(RTL_DIR)/backend/xs_Scheduler_core.sv \
           $(RTL_DIR)/backend/IssueQueueStaMou.sv \
           $(RTL_DIR)/backend/IssueQueueLdu.sv \
           $(RTL_DIR)/backend/IssueQueueVlduVstuVseglduVsegstu.sv \
           $(RTL_DIR)/backend/IssueQueueVlduVstu.sv \
           $(RTL_DIR)/backend/IssueQueueStdMoud.sv \
           $(RTL_DIR)/backend/EntriesStaMou.sv \
           $(RTL_DIR)/backend/NewAgeDetector_6.sv \
           $(RTL_DIR)/backend/AgeDetector_12.sv \
           $(RTL_DIR)/backend/AgeDetector_21.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/EntriesLdu.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_105.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_105.sv \
           $(RTL_DIR)/backend/EntriesVlduVstuVseglduVsegstu.sv \
           $(RTL_DIR)/backend/EntriesVlduVstu.sv \
           $(RTL_DIR)/backend/EntriesStdMoud.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite.sv \
           $(RTL_DIR)/backend/FuBusyTableRead.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/Scheduler_3.sv $(GOLDEN_RTL)/IssueQueueStaMou.sv $(GOLDEN_RTL)/EntriesStaMou.sv $(GOLDEN_RTL)/EnqEntry_20.sv $(GOLDEN_RTL)/UIntCompressor_27_000011100000000000001010101.sv $(GOLDEN_RTL)/OthersEntry_172.sv $(GOLDEN_RTL)/OthersEntry_174.sv $(GOLDEN_RTL)/EnqPolicy_14.sv $(GOLDEN_RTL)/NewAgeDetector_6.sv $(GOLDEN_RTL)/AgeDetector_12.sv $(GOLDEN_RTL)/AgeDetector_21.sv $(GOLDEN_RTL)/IssueQueueLdu.sv $(GOLDEN_RTL)/EntriesLdu.sv $(GOLDEN_RTL)/EnqEntry_24.sv $(GOLDEN_RTL)/OthersEntry_200.sv $(GOLDEN_RTL)/OthersEntry_202.sv $(GOLDEN_RTL)/FuBusyTableWrite_105.sv $(GOLDEN_RTL)/FuBusyTableRead_105.sv $(GOLDEN_RTL)/IssueQueueVlduVstuVseglduVsegstu.sv $(GOLDEN_RTL)/EntriesVlduVstuVseglduVsegstu.sv $(GOLDEN_RTL)/EnqEntryVecMem.sv $(GOLDEN_RTL)/OthersEntryVecMem.sv $(GOLDEN_RTL)/OthersEntryVecMem_2.sv $(GOLDEN_RTL)/IssueQueueVlduVstu.sv $(GOLDEN_RTL)/EntriesVlduVstu.sv $(GOLDEN_RTL)/EnqEntryVecMem_2.sv $(GOLDEN_RTL)/OthersEntryVecMem_14.sv $(GOLDEN_RTL)/OthersEntryVecMem_16.sv $(GOLDEN_RTL)/IssueQueueStdMoud.sv $(GOLDEN_RTL)/EntriesStdMoud.sv $(GOLDEN_RTL)/EnqEntry_30.sv $(GOLDEN_RTL)/OthersEntry_242.sv $(GOLDEN_RTL)/OthersEntry_244.sv

FM_VARIANTS = Scheduler_3
FM_REF_DEPS_Scheduler_3 = IssueQueueStaMou.sv EntriesStaMou.sv EnqEntry_20.sv UIntCompressor_27_000011100000000000001010101.sv OthersEntry_172.sv OthersEntry_174.sv EnqPolicy_14.sv NewAgeDetector_6.sv AgeDetector_12.sv AgeDetector_21.sv IssueQueueLdu.sv EntriesLdu.sv EnqEntry_24.sv OthersEntry_200.sv OthersEntry_202.sv FuBusyTableWrite_105.sv FuBusyTableRead_105.sv IssueQueueVlduVstuVseglduVsegstu.sv EntriesVlduVstuVseglduVsegstu.sv EnqEntryVecMem.sv OthersEntryVecMem.sv OthersEntryVecMem_2.sv IssueQueueVlduVstu.sv EntriesVlduVstu.sv EnqEntryVecMem_2.sv OthersEntryVecMem_14.sv OthersEntryVecMem_16.sv IssueQueueStdMoud.sv EntriesStdMoud.sv EnqEntry_30.sv OthersEntry_242.sv OthersEntry_244.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/Scheduler_3.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
