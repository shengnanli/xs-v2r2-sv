MODULE = IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf

# IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf EnqEntry_14 OthersEntry_136 OthersEntry_138 EnqPolicy_14 FuBusyTableWrite_68 FuBusyTableWrite_69 FuBusyTableRead_68 FuBusyTableRead_69 FuBusyTableWrite_71 FuBusyTableRead_71 FuBusyTableWrite_73 FuBusyTableRead_73 FuBusyTableWrite_75 FuBusyTableRead_75 FuBusyTableWrite_79 FuBusyTableRead_79 NewAgeDetector AgeDetector_8 AgeDetector_15
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv \
           $(RTL_DIR)/backend/EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_68.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_69.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_68.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_69.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_71.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_71.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_73.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_73.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_75.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_75.sv \
           $(RTL_DIR)/backend/FuBusyTableWrite_79.sv \
           $(RTL_DIR)/backend/FuBusyTableRead_79.sv \
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
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv $(GOLDEN_RTL)/EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv $(GOLDEN_RTL)/EnqEntry_14.sv $(GOLDEN_RTL)/OthersEntry_136.sv $(GOLDEN_RTL)/OthersEntry_138.sv $(GOLDEN_RTL)/EnqPolicy_14.sv $(GOLDEN_RTL)/FuBusyTableWrite_68.sv $(GOLDEN_RTL)/FuBusyTableWrite_69.sv $(GOLDEN_RTL)/FuBusyTableRead_68.sv $(GOLDEN_RTL)/FuBusyTableRead_69.sv $(GOLDEN_RTL)/FuBusyTableWrite_71.sv $(GOLDEN_RTL)/FuBusyTableRead_71.sv $(GOLDEN_RTL)/FuBusyTableWrite_73.sv $(GOLDEN_RTL)/FuBusyTableRead_73.sv $(GOLDEN_RTL)/FuBusyTableWrite_75.sv $(GOLDEN_RTL)/FuBusyTableRead_75.sv $(GOLDEN_RTL)/FuBusyTableWrite_79.sv $(GOLDEN_RTL)/FuBusyTableRead_79.sv $(GOLDEN_RTL)/NewAgeDetector.sv $(GOLDEN_RTL)/AgeDetector_8.sv $(GOLDEN_RTL)/AgeDetector_15.sv

FM_VARIANTS = IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf
FM_REF_DEPS_IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf = EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv EnqEntry_14.sv OthersEntry_136.sv OthersEntry_138.sv EnqPolicy_14.sv FuBusyTableWrite_68.sv FuBusyTableWrite_69.sv FuBusyTableRead_68.sv FuBusyTableRead_69.sv FuBusyTableWrite_71.sv FuBusyTableRead_71.sv FuBusyTableWrite_73.sv FuBusyTableRead_73.sv FuBusyTableWrite_75.sv FuBusyTableRead_75.sv FuBusyTableWrite_79.sv FuBusyTableRead_79.sv NewAgeDetector.sv AgeDetector_8.sv AgeDetector_15.sv

FM_MERGE_DUP = false

# vmucp（加强不是放宽）：依据与六条证据见 verif/fm_target_config/IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
