# EntriesVfdivVidiv UT/FM 入口（Entries* 家族 canary）
# 重写件只有两个：家族共享参数化核 + 本变体薄文件。
# golden 的 EnqEntry/OthersEntry/EnqPolicy 都不是独立签核目标，故本重写把它们
# 一起扁平化，不放 RTL_GOLDEN_DEPS、不做黑盒；FM 侧 ref 需要它们做依赖闭包。
# 自动生成：verif/ut/EntriesVfdivVidiv/gen.py —— 勿手改
MODULE = EntriesVfdivVidiv

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_iq_entries_core.sv \
           $(RTL_DIR)/backend/EntriesVfdivVidiv.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/EntriesVfdivVidiv.sv \
              $(GOLDEN_RTL)/EnqEntry_18.sv \
              $(GOLDEN_RTL)/OthersEntry_164.sv \
              $(GOLDEN_RTL)/OthersEntry_166.sv \
              $(GOLDEN_RTL)/EnqPolicy_18.sv

FM_VARIANTS = EntriesVfdivVidiv
FM_REF_DEPS_EntriesVfdivVidiv = EnqEntry_18.sv OthersEntry_164.sv OthersEntry_166.sv EnqPolicy_18.sv

include ../../../scripts/ut_common.mk

# golden 带 XSError/XSPerf 等非综合断言，随机激励会踩到 $fatal；两侧统一关掉。
VCS += +define+SYNTHESIS
