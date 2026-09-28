MODULE = IssueQueueVfdivVidiv

# IssueQueueVfdivVidiv（发射队列）。golden 子模块闭包（两侧白盒，impl 用本仓已签核重写件）：
#   EntriesVfdivVidiv EnqEntry_18 OthersEntry_164 OthersEntry_166 EnqPolicy_18 NewAgeDetector_6 AgeDetector_12 AgeDetector_19
# 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/IssueQueueVfdivVidiv.sv \
           $(RTL_DIR)/backend/EntriesVfdivVidiv.sv \
           $(RTL_DIR)/backend/NewAgeDetector_6.sv \
           $(RTL_DIR)/backend/AgeDetector_12.sv \
           $(RTL_DIR)/backend/AgeDetector_19.sv \
           $(RTL_DIR)/backend/xs_IssueQueue_core.sv \
           $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/xs_NewAgeDetector_core.sv \
           $(RTL_DIR)/backend/xs_AgeDetector_core.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/IssueQueueVfdivVidiv.sv $(GOLDEN_RTL)/EntriesVfdivVidiv.sv $(GOLDEN_RTL)/EnqEntry_18.sv $(GOLDEN_RTL)/OthersEntry_164.sv $(GOLDEN_RTL)/OthersEntry_166.sv $(GOLDEN_RTL)/EnqPolicy_18.sv $(GOLDEN_RTL)/NewAgeDetector_6.sv $(GOLDEN_RTL)/AgeDetector_12.sv $(GOLDEN_RTL)/AgeDetector_19.sv

FM_VARIANTS = IssueQueueVfdivVidiv
FM_REF_DEPS_IssueQueueVfdivVidiv = EntriesVfdivVidiv.sv EnqEntry_18.sv OthersEntry_164.sv OthersEntry_166.sv EnqPolicy_18.sv NewAgeDetector_6.sv AgeDetector_12.sv AgeDetector_19.sv

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块（断言调未定义的 xs_assert_v2 + 随机初值）；两侧同口径带 SYNTHESIS。
# initreg：编译期开机制、运行期选取值；INITREG=0 档两侧初值确定，tb 加 +cmp_all 每拍比全部输出。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG) $(if $(filter 0,$(INITREG)),+cmp_all,)
